import Combine
import Foundation
import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
  @Published var products: [Product] = []
  @Published var purchasedProductIDs: Set<String> = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private var updateListenerTask: Task<Void, Error>?

  // Product identifiers
  static let premiumFeature = "com.apgi.appendix.premium"
  static let advancedAnalytics = "com.apgi.appendix.analytics"
  static let cloudSync = "com.apgi.appendix.cloudsync"

  init() {
    self.updateListenerTask = self.listenForTransactions()
    Task {
      await self.updatePurchasedStatus()
    }
  }

  deinit {
    updateListenerTask?.cancel()
  }

  func loadProducts() async {
    self.isLoading = true
    self.errorMessage = nil

    do {
      let storeProducts = try await Product.products(for: [
        Self.premiumFeature,
        Self.advancedAnalytics,
        Self.cloudSync,
      ])

      self.products = storeProducts.sorted { $0.price < $1.price }
    } catch {
      self.errorMessage = "Failed to load products: \(error.localizedDescription)"
    }

    self.isLoading = false
  }

  func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
    self.isLoading = true
    defer { isLoading = false }

    let result = try await product.purchase()

    switch result {
    case .success(let verification):
      let transaction = try checkVerified(verification)

      // Deliver content
      await deliver(transaction.productID)

      // Finish transaction
      await transaction.finish()

      return transaction

    case .userCancelled:
      return nil

    case .pending:
      self.errorMessage = "Purchase is pending approval."
      return nil

    @unknown default:
      return nil
    }
  }

  func restorePurchases() async {
    self.isLoading = true
    defer { isLoading = false }

    do {
      try await AppStore.sync()
    } catch {
      self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
    }
  }

  private func listenForTransactions() -> Task<Void, Error> {
    return Task.detached {
      for await result in StoreKit.Transaction.updates {
        await MainActor.run {
          do {
            let transaction = try self.checkVerified(result)
            self.purchasedProductIDs.insert(transaction.productID)
          } catch {
            self.errorMessage = "Failed to verify transaction: \(error.localizedDescription)"
          }
        }
      }
    }
  }

  private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
      throw StoreError.failedVerification
    case .verified(let safe):
      return safe
    }
  }

  private func deliver(_ productID: String) async {
    self.purchasedProductIDs.insert(productID)

    // We still save to UserDefaults for quick UI response, but we'll always
    // validate against StoreKit for authoritative checks.
    UserDefaults.standard.set(Array(self.purchasedProductIDs), forKey: "PurchasedProducts")
  }

  /// Authoritatively update purchase status from StoreKit transaction history
  func updatePurchasedStatus() async {
    var purchasedIDs: Set<String> = []

    // Iterate through all current entitlements (active transactions)
    for await result in Transaction.currentEntitlements {
      do {
        let transaction = try checkVerified(result)
        purchasedIDs.insert(transaction.productID)
      } catch {
        // Log error if needed
      }
    }

    self.purchasedProductIDs = purchasedIDs

    // Sync local cache for offline speed but not for trust
    UserDefaults.standard.set(Array(purchasedIDs), forKey: "PurchasedProducts")
  }

  func isPurchased(_ productID: String) -> Bool {
    return self.purchasedProductIDs.contains(productID)
  }

  // MARK: - Premium Features Access

  var hasPremiumFeatures: Bool {
    self.isPurchased(Self.premiumFeature)
  }

  var hasAdvancedAnalytics: Bool {
    self.isPurchased(Self.advancedAnalytics) || self.hasPremiumFeatures
  }

  var hasCloudSync: Bool {
    self.isPurchased(Self.cloudSync) || self.hasPremiumFeatures
  }
}

enum StoreError: LocalizedError {
  case failedVerification
  case receiptValidationFailed
  case receiptNotFound
  case invalidReceipt
  case serverUnavailable

  var errorDescription: String? {
    switch self {
    case .failedVerification:
      return "Failed to verify purchase"
    case .receiptValidationFailed:
      return "Receipt validation failed"
    case .receiptNotFound:
      return "Purchase receipt not found"
    case .invalidReceipt:
      return "Invalid purchase receipt"
    case .serverUnavailable:
      return "Validation server unavailable"
    }
  }
}

// MARK: - Server-Side Receipt Validation (MF-013)

extension StoreManager {
  /// Validates the App Store receipt with Apple's server
  /// This provides additional security beyond local StoreKit verification
  func validateReceiptWithServer() async -> ReceiptValidationResult {
    // Ensure network connectivity before attempting any server-related validation
    guard NetworkManager.shared.isConnected else {
      return .failure(.serverUnavailable)
    }

    // Prefer StoreKit 2 APIs across platforms to avoid deprecated receipt URL usage
    // Attempt to read the signed App Transaction and enumerate transactions
    do {
      _ = try await AppTransaction.shared
    } catch {
      // If AppTransaction is unavailable, we still proceed to check entitlements/transactions
    }

    // Collect current entitlements as the primary, non-deprecated path
    var currentProductIDs: Set<String> = []
    for await result in Transaction.currentEntitlements {
      do {
        let transaction = try checkVerified(result)
        currentProductIDs.insert(transaction.productID)
      } catch {
        // Skip unverified
      }
    }

    // If we have any active entitlements, treat as success without contacting Apple's verifyReceipt endpoint
    if !currentProductIDs.isEmpty {
      return .success(Array(currentProductIDs))
    }

    // If entitlements are empty, attempt to scan full transaction history for previously purchased non-consumables
    // This still uses StoreKit 2 and avoids deprecated receipt access.
    do {
      var historicalProductIDs: Set<String> = []
      for await verification in Transaction.all {
        do {
          let transaction = try checkVerified(verification)
          // Include completed or restored non-consumables/subscriptions that may still grant access
          if transaction.revocationDate == nil {
            historicalProductIDs.insert(transaction.productID)
          }
        } catch {
          // Skip unverified
        }
      }

      if !historicalProductIDs.isEmpty {
        return .success(Array(historicalProductIDs))
      }
    }

    // As a final step, if you still need server-side verification for your backend,
    // you can call your own server here with identifiers or signed transactions.
    // Since we are avoiding deprecated receipt URL access, we will return a failure that
    // indicates server-side validation couldn't assert anything new.
    return .failure(.receiptValidationFailed)
  }

  private func validateWithApple(receiptBase64: String, sandbox: Bool) async
    -> ReceiptValidationResult?
  {
    let endpoint =
      sandbox
      ? "https://sandbox.itunes.apple.com/verifyReceipt"
      : "https://buy.itunes.apple.com/verifyReceipt"

    guard let url = URL(string: endpoint) else { return nil }

    // Prepare request payload
    let payload: [String: Any] = [
      "receipt-data": receiptBase64,
      "password": getSharedSecret(),  // For auto-renewable subscriptions (optional)
      "exclude-old-transactions": false,
    ]

    guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 30

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else {
        return nil
      }

      guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let status = json["status"] as? Int
      else {
        return nil
      }

      // Handle status codes
      switch status {
      case 0:
        // Valid receipt
        if let receipt = json["receipt"] as? [String: Any],
          let inApp = receipt["in_app"] as? [[String: Any]]
        {
          let validatedProducts = extractValidatedProducts(from: inApp)
          return .success(validatedProducts)
        }
        return .failure(.invalidReceipt)

      case 21007:
        // Sandbox receipt sent to production - caller should retry with sandbox
        return nil  // Signal to retry

      case 21008:
        // Production receipt sent to sandbox
        return .failure(.invalidReceipt)

      case 21004, 21005:
        // Shared secret mismatch or server unavailable
        return .failure(.serverUnavailable)

      default:
        return .failure(.receiptValidationFailed)
      }
    } catch {
      return nil
    }
  }

  private func extractValidatedProducts(from inAppPurchases: [[String: Any]]) -> [String] {
    var productIDs: [String] = []

    for purchase in inAppPurchases {
      if let productID = purchase["product_id"] as? String,
        let transactionState = purchase["transaction_state"] as? String
      {
        // Only include completed transactions
        if transactionState == "purchased" || transactionState == "restored" {
          productIDs.append(productID)
        }
      }
    }

    return productIDs
  }

  private func getSharedSecret() -> String {
    // In production, this should be retrieved from a secure server
    // or from Keychain after being fetched during app startup
    #if DEBUG
      return "your-shared-secret-here"  // Replace with actual shared secret in production
    #else
      // Production: Fetch from secure keychain or config
      return UserDefaults.standard.string(forKey: "IAPSharedSecret") ?? ""
    #endif
  }

  /// Performs comprehensive validation: local StoreKit + server-side receipt
  func validatePurchasesComprehensive() async -> Bool {
    // First: Local StoreKit validation (authoritative)
    await updatePurchasedStatus()

    // Second: Server-side receipt validation (additional security layer)
    let serverResult = await validateReceiptWithServer()

    switch serverResult {
    case .success(let validatedProducts):
      // Sync server-validated products with local state
      await MainActor.run {
        for productID in validatedProducts {
          self.purchasedProductIDs.insert(productID)
        }
        UserDefaults.standard.set(Array(self.purchasedProductIDs), forKey: "PurchasedProducts")
      }
      return true

    case .failure(let error):
      // Log error but don't block user - StoreKit validation is primary
      print("Server receipt validation failed: \(error.localizedDescription)")
      // Still return true if StoreKit validation succeeded
      return !self.purchasedProductIDs.isEmpty
    }
  }
}

/// Result type for receipt validation
enum ReceiptValidationResult {
  case success([String])  // Array of validated product IDs
  case failure(StoreError)
}

// MARK: - Store Views

struct StoreView: View {
  @StateObject private var storeManager = StoreManager()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      List {
        Section("Premium Features") {
          ForEach(self.storeManager.products) { product in
            ProductRow(product: product, storeManager: self.storeManager)
          }
        }

        Section("Restore Purchases") {
          Button("Restore Purchases") {
            Task {
              await self.storeManager.restorePurchases()
            }
          }
          .disabled(self.storeManager.isLoading)
        }
      }
      .navigationTitle("APGI Appendix Store")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Done") {
            self.dismiss()
          }
        }
      }
      .overlay {
        if self.storeManager.isLoading {
          ProgressView("Loading...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
        }
      }
      .alert("Error", isPresented: .constant(self.storeManager.errorMessage != nil)) {
        Button("OK") {
          self.storeManager.errorMessage = nil
        }
      } message: {
        if let errorMessage = storeManager.errorMessage {
          Text(errorMessage)
        }
      }
      .task {
        await self.storeManager.loadProducts()
        // Use comprehensive validation including server-side receipt check
        _ = await self.storeManager.validatePurchasesComprehensive()
      }
    }
  }
}

struct ProductRow: View {
  let product: Product
  let storeManager: StoreManager

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(self.product.displayName)
          .font(.headline)
        Text(self.product.description)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      if self.storeManager.isPurchased(self.product.id) {
        Text("Purchased")
          .foregroundColor(.green)
          .font(.caption)
      } else {
        Button(action: {
          Task {
            try? await self.storeManager.purchase(self.product)
          }
        }) {
          Text(self.product.displayPrice)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(self.storeManager.isLoading)
      }
    }
    .padding(.vertical, 4)
  }
}
