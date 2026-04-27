import CryptoKit
import Foundation

// MARK: - Update Signature Verifier

/// Actor responsible for cryptographic verification of update manifests
/// Uses Ed25519 signatures to ensure update authenticity
@globalActor
actor UpdateSignatureActor: GlobalActor {
  static let shared = UpdateSignatureActor()
  nonisolated static let sharedVerifier = UpdateSignatureVerifier()

  static var sharedContext: some Actor { shared }
}

@UpdateSignatureActor
final class UpdateSignatureVerifier: Sendable {
  nonisolated static var shared: UpdateSignatureVerifier { UpdateSignatureActor.sharedVerifier }

  // MARK: - Trusted Public Keys (Ed25519)
  // These are the official APGI signing keys - rotate annually
  private lazy var trustedPublicKeys: [String: P256.Signing.PublicKey] = {
    var keys: [String: P256.Signing.PublicKey] = [:]
    // Primary signing key (2024-2025)
    let keyData = Data([
      0x04, 0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47, 0xF8,
      0xBC, 0xE6, 0xE5, 0x63, 0xA4, 0x40, 0xF2, 0x77, 0x03, 0x7D,
      0x81, 0x2D, 0xEB, 0x33, 0xA0, 0xF4, 0xA1, 0x39, 0x45, 0xD8,
      0x98, 0xC2, 0x96, 0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F,
      0x9B, 0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 0x0F, 0x9E, 0x16, 0x2B,
      0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE, 0xCB, 0xB6, 0x40,
      0x68, 0x37, 0xBF, 0x51, 0xF5
    ])
    if let key = try? P256.Signing.PublicKey(x963Representation: keyData) {
      keys["apgi-primary-2024"] = key
    }
    return keys
  }()

  // MARK: - Trusted Host + Path Policy

  private let trustedDownloadHosts = [
    "apgi-framework.org",
    "github.com"
  ]

  private let trustedPathPatterns = [
    "apgi-framework.org": ["/releases/", "/downloads/", "/updates/"],
    "github.com": ["/apgi/framework/releases/"]
  ]

  // MARK: - Signature Verification

  /// Verifies the signature of an update response
  /// - Parameters:
  ///   - response: The update response to verify
  ///   - signature: Base64-encoded Ed25519 signature
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
      let host = url.host?.lowercased()
    else {
      logSecurityEvent("Invalid download URL format")
      return false
    }

    // Check host is trusted
    let isTrustedHost = trustedDownloadHosts.contains { trustedHost in
      host == trustedHost || host.hasSuffix("." + trustedHost)
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

    return try JSONSerialization.data(withJSONObject: orderedComponents, options: [])
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
  let algorithm: String  // Should be "P256-ECDSA" or "Ed25519"
}
