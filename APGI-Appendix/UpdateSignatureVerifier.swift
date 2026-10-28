import CryptoKit
import Foundation

// MARK: - Update Signature Verifier

/// Actor responsible for cryptographic verification of update manifests
/// Uses P256-ECDSA signatures to ensure update authenticity
@globalActor
actor UpdateSignatureActor: GlobalActor {
  static let shared = UpdateSignatureActor()
  nonisolated static let sharedVerifier = UpdateSignatureVerifier()

  static var sharedContext: some Actor { shared }
}

@UpdateSignatureActor
final class UpdateSignatureVerifier: Sendable {
  nonisolated static var shared: UpdateSignatureVerifier { UpdateSignatureActor.sharedVerifier }

  // No production signing key has been supplied. Updates fail closed until a
  // reviewed release key and corresponding server manifest contract are installed.
  private let trustedPublicKeys: [String: P256.Signing.PublicKey] = [:]
  private let trustedDownloadHosts = ["apgiframework.com", "api.apgiframework.com"]
  private let trustedPathPatterns = [
    "apgiframework.com": ["/releases/", "/downloads/", "/updates/"],
    "api.apgiframework.com": ["/releases/", "/downloads/", "/updates/"]
  ]

  // MARK: - Signature Verification

  /// Verifies the signature of an update response
  /// - Parameters:
  ///   - response: The update response to verify
  ///   - signature: Base64-encoded P256-ECDSA signature
  ///   - keyId: The key identifier used for signing
  /// - Returns: True if signature is valid
  func verifyUpdate(_ response: UpdateResponse, signature: String, keyId: String) -> Bool {
    guard let publicKey = trustedPublicKeys[keyId] else {
      logSecurityEvent("Unknown signing key: \(keyId)")
      return false
    }

    guard let signatureData = Data(base64Encoded: signature) else {
      logSecurityEvent("Invalid signature encoding")
      return false
    }

    do {
      let ecdsaSignature = try P256.Signing.ECDSASignature(rawRepresentation: signatureData)

      // Create canonical JSON for verification (sorted keys, no whitespace)
      let canonicalData = try createCanonicalData(from: response)

      let isValid = publicKey.isValidSignature(ecdsaSignature, for: canonicalData)

      if isValid {
        logSecurityEvent("Update signature verified with key: \(keyId)")
      } else {
        logSecurityEvent("Invalid signature for update \(response.latestVersion)")
      }

      return isValid
    } catch {
      logSecurityEvent("Signature verification failed: \(error.localizedDescription)")
      return false
    }
  }

  /// Validates download URL against trusted host + path policy
  /// - Parameter urlString: The download URL to validate
  /// - Returns: True if URL matches trusted policy
  func validateDownloadURL(_ urlString: String) -> Bool {
    guard let url = URL(string: urlString),
      url.scheme == "https", url.user == nil, url.password == nil,
      url.port == nil || url.port == 443,
      let host = url.host?.lowercased()
    else {
      logSecurityEvent("Invalid download URL format")
      return false
    }

    // Check host is trusted
    let isTrustedHost = trustedDownloadHosts.contains { trustedHost in
      host == trustedHost
    }

    guard isTrustedHost else {
      logSecurityEvent("Untrusted download host: \(host)")
      return false
    }

    // Check path matches allowed patterns
    guard let allowedPatterns = trustedPathPatterns[host] else {
      logSecurityEvent("No path policy for host: \(host)")
      return false
    }

    let urlPath = url.path.lowercased()
    let matchesPattern = allowedPatterns.contains { pattern in
      urlPath.hasPrefix(pattern.lowercased())
    }

    if !matchesPattern {
      logSecurityEvent("Download path violates policy: \(urlPath)")
    }

    return matchesPattern
  }

  /// Comprehensive security check for update
  /// - Parameters:
  ///   - response: The update response
  ///   - signature: The signature string
  ///   - keyId: The key identifier
  /// - Returns: Validation result with details
  func validateUpdate(
    _ response: UpdateResponse,
    signature: String?,
    keyId: String?
  ) -> UpdateValidationResult {
    guard response.algorithm == "P256-ECDSA" else {
      return .invalid(reason: "Unsupported signature algorithm")
    }
    // Require signature and keyId for all updates
    guard let signature = signature, !signature.isEmpty else {
      return .invalid(reason: "Missing required signature")
    }

    guard let keyId = keyId, !keyId.isEmpty else {
      return .invalid(reason: "Missing required key identifier")
    }

    // Verify manifest signature
    guard verifyUpdate(response, signature: signature, keyId: keyId) else {
      return .invalid(reason: "Signature verification failed")
    }

    // Validate download URL if present
    if let downloadURL = response.downloadURL {
      guard validateDownloadURL(downloadURL) else {
        return .invalid(reason: "Download URL violates security policy")
      }
    }

    // Check for critical update requirements
    if response.isCritical == true {
      // Critical updates have additional validation
      guard response.minimumVersion != nil else {
        return .invalid(reason: "Critical update missing minimum version")
      }
    }

    return .valid(keyId: keyId)
  }

  // MARK: - Private Helpers

  private func createCanonicalData(from response: UpdateResponse) throws -> Data {
    // Create deterministic representation for signing
    var components: [String: Any] = [
      "latestVersion": response.latestVersion,
      "releaseNotes": response.releaseNotes
    ]

    if let minimumVersion = response.minimumVersion {
      components["minimumVersion"] = minimumVersion
    }

    if let downloadURL = response.downloadURL {
      components["downloadURL"] = downloadURL
    }

    if let releaseDate = response.releaseDate {
      components["releaseDate"] = releaseDate
    }

    if let isCritical = response.isCritical {
      components["isCritical"] = isCritical
    }

    // Sort keys for deterministic output
    let sortedKeys = components.keys.sorted()
    var orderedComponents: [String: Any] = [:]
    for key in sortedKeys {
      orderedComponents[key] = components[key]
    }

    return try JSONSerialization.data(withJSONObject: orderedComponents, options: [.sortedKeys, .withoutEscapingSlashes])
  }

  private func logSecurityEvent(_ message: String) {
    Task { @MainActor in
      logInfo("[SECURITY] \(message)", context: "UpdateSignatureVerifier")
    }
  }
}

// MARK: - Validation Result

enum UpdateValidationResult {
  case valid(keyId: String)
  case invalid(reason: String)

  var isValid: Bool {
    if case .valid = self { return true }
    return false
  }

  var errorReason: String? {
    if case .invalid(let reason) = self { return reason }
    return nil
  }
}

// MARK: - Extended Update Response

/// Update response model including signature metadata
struct SignedUpdateResponse: Codable {
  let update: UpdateResponse
  let signature: String
  let keyId: String
  let algorithm: String  // Should be "P256-ECDSA" or "P256-ECDSA"
}
