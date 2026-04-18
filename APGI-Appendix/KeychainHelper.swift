import CryptoKit
import Foundation
import Security

class KeychainHelper {
  static let shared = KeychainHelper()

  private let encryptionKeyTag = "com.apgi.appendix.encryptionKey"
  private var cachedEncryptionKey: SymmetricKey?

  private init() {
  }

  // MARK: - Encryption Key Management

  private func getEncryptionKey() throws -> SymmetricKey {
    if let cachedKey = cachedEncryptionKey {
      return cachedKey
    }

    if let keyData = retrieveRaw(for: encryptionKeyTag) {
      let key = SymmetricKey(data: keyData)
      self.cachedEncryptionKey = key
      return key
    }

    // Generate new key
    let key = SymmetricKey(size: .bits256)
    let keyData = key.withUnsafeBytes { Data($0) }

    // Store key in Keychain
    guard
      self.saveRaw(
        data: keyData, for: self.encryptionKeyTag,
        accessibility: kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
    else {
      throw NSError(
        domain: "KeychainHelper", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to store encryption key"])
    }

    self.cachedEncryptionKey = key
    return key
  }

  /// Encrypt data using CryptoKit
  private func encrypt(data: Data) throws -> Data {
    let key = try getEncryptionKey()
    let sealedBox = try AES.GCM.seal(data, using: key)
    guard let combined = sealedBox.combined else {
      throw NSError(
        domain: "KeychainHelper", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to get combined data from sealed box"])
    }
    return combined
  }

  /// Decrypt data using CryptoKit
  private func decrypt(data: Data) throws -> Data {
    let key = try getEncryptionKey()
    let sealedBox = try AES.GCM.SealedBox(combined: data)
    return try AES.GCM.open(sealedBox, using: key)
  }

  // MARK: - Raw Keychain Operations (without encryption)

  private func saveRaw(
    data: Data, for key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlocked
  ) -> Bool {
    self.deleteRaw(for: key)

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
      kSecAttrAccessible as String: accessibility,
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
  }

  private func retrieveRaw(for key: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else { return nil }
    return result as? Data
  }

  @discardableResult
  private func deleteRaw(for key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
    ]

    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess || status == errSecItemNotFound
  }

  /// Store data securely in Keychain with encryption
  /// - Parameters:
  ///   - data: The data to store
  ///   - key: Unique identifier for the data
  ///   - accessibility: When the data should be accessible
  /// - Returns: Success status
  @discardableResult
  func save(data: Data, for key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlocked)
    -> Bool
  {
    do {
      let encryptedData = try encrypt(data: data)
      return self.saveRaw(data: encryptedData, for: key, accessibility: accessibility)
    } catch {
      logError(
        error, context: "KeychainHelper.save(data:for:)", function: #function, file: #file,
        line: #line)
      return false
    }
  }

  /// Retrieve data from Keychain and decrypt
  /// - Parameter key: Unique identifier for the data
  /// - Returns: The stored data, or nil if not found or decryption failed
  func retrieve(for key: String) -> Data? {
    guard let encryptedData = retrieveRaw(for: key) else { return nil }

    do {
      return try self.decrypt(data: encryptedData)
    } catch {
      logError(
        error, context: "KeychainHelper.retrieve(for:)", function: #function, file: #file,
        line: #line)
      return nil
    }
  }

  /// Delete data from Keychain
  /// - Parameter key: Unique identifier for the data
  /// - Returns: Success status
  @discardableResult
  func delete(for key: String) -> Bool {
    return self.deleteRaw(for: key)
  }

  /// Store string securely in Keychain with encryption
  /// - Parameters:
  ///   - string: The string to store
  ///   - key: Unique identifier for the data
  ///   - accessibility: When the data should be accessible
  /// - Returns: Success status
  @discardableResult
  func save(
    string: String, for key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlocked
  ) -> Bool {
    guard let data = string.data(using: .utf8) else { return false }
    return self.save(data: data, for: key, accessibility: accessibility)
  }

  /// Retrieve string from Keychain and decrypt
  /// - Parameter key: Unique identifier for the data
  /// - Returns: The stored string, or nil if not found or decryption failed
  func retrieveString(for key: String) -> String? {
    guard let data = retrieve(for: key) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  /// Store Codable object securely in Keychain with encryption
  /// - Parameters:
  ///   - object: The object to store
  ///   - key: Unique identifier for the data
  ///   - accessibility: When the data should be accessible
  /// - Returns: Success status
  @discardableResult
  func save<T: Codable>(
    object: T, for key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlocked
  ) -> Bool {
    do {
      let data = try JSONEncoder().encode(object)
      return self.save(data: data, for: key, accessibility: accessibility)
    } catch {
      logError(
        error, context: "KeychainHelper.save(object:for:)", function: #function, file: #file,
        line: #line)
      return false
    }
  }

  /// Retrieve Codable object from Keychain and decrypt
  /// - Parameter key: Unique identifier for the data
  /// - Returns: The stored object, or nil if not found or decoding/decryption failed
  func retrieveObject<T: Codable>(for key: String) -> T? {
    guard let data = retrieve(for: key) else { return nil }

    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      logError(
        error, context: "KeychainHelper.retrieveObject(for:)", function: #function, file: #file,
        line: #line)
      return nil
    }
  }

  /// Check if data exists in Keychain
  /// - Parameter key: Unique identifier for the data
  /// - Returns: True if data exists
  func exists(for key: String) -> Bool {
    return self.retrieve(for: key) != nil
  }
}
