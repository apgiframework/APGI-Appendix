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
        }
        catch {
            self.errorMessage = "Failed to load products: \(error.localizedDescription)"
        }

        self.isLoading = false
    }

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        self.isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case let .success(verification):
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
        }
        catch {
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
                    }
                    catch {
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
        case let .verified(safe):
            return safe
        }
    }

    private func deliver(_ productID: String) async {
        self.purchasedProductIDs.insert(productID)

        // Save to UserDefaults for persistence
        UserDefaults.standard.set(Array(self.purchasedProductIDs), forKey: "PurchasedProducts")
    }

    func checkPurchasedStatus() {
        if let savedProductIDs = UserDefaults.standard.array(forKey: "PurchasedProducts") as? [String] {
            self.purchasedProductIDs = Set(savedProductIDs)
        }
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

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Failed to verify purchase"
        }
    }
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
            .navigationTitle("APGI Store")
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
                self.storeManager.checkPurchasedStatus()
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
            }
            else {
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
