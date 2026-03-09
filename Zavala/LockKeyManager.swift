//
//  LockKeyManager.swift
//  Zavala
//
//  Created by Maurice Parker on 3/8/26.
//

import Foundation
import Security
import CryptoKit
import VinOutlineKit

enum LockError: LocalizedError {
	case keychainWriteFailed(OSStatus)
	case keychainReadFailed(OSStatus)
	case keychainDeleteFailed(OSStatus)
	case authenticationFailed
	case noKeyFound

	var errorDescription: String? {
		switch self {
		case .keychainWriteFailed(let status):
			return "Keychain write failed: \(status)"
		case .keychainReadFailed(let status):
			return "Keychain read failed: \(status)"
		case .keychainDeleteFailed(let status):
			return "Keychain delete failed: \(status)"
		case .authenticationFailed:
			return String(localized: "Authentication failed.", comment: "Error: Authentication failed")
		case .noKeyFound:
			return String(localized: "No encryption key found for this outline.", comment: "Error: No encryption key found")
		}
	}
}

final class LockKeyManager {

	private static let keychainService = "io.vincode.Zavala.OutlineLock"

	/// Generate a new AES-256 key for an outline and store it in iCloud Keychain.
	static func createKey(for outlineID: EntityID) throws -> SymmetricKey {
		let key = SymmetricKey(size: .bits256)
		let keyData = key.withUnsafeBytes { Data($0) }

		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: keychainService,
			kSecAttrAccount as String: outlineID.description,
			kSecValueData as String: keyData,
			kSecAttrSynchronizable as String: true,
			kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
		]

		let status = SecItemAdd(query as CFDictionary, nil)
		guard status == errSecSuccess else {
			throw LockError.keychainWriteFailed(status)
		}

		return key
	}

	/// Retrieve the AES key for an outline from Keychain.
	static func retrieveKey(for outlineID: EntityID) throws -> SymmetricKey? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: keychainService,
			kSecAttrAccount as String: outlineID.description,
			kSecAttrSynchronizable as String: true,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne
		]

		var result: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &result)

		guard status == errSecSuccess, let keyData = result as? Data else {
			if status == errSecItemNotFound { return nil }
			throw LockError.keychainReadFailed(status)
		}

		return SymmetricKey(data: keyData)
	}

	/// Delete the key when removing lock from an outline.
	static func deleteKey(for outlineID: EntityID) throws {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: keychainService,
			kSecAttrAccount as String: outlineID.description,
			kSecAttrSynchronizable as String: true
		]

		let status = SecItemDelete(query as CFDictionary)
		guard status == errSecSuccess || status == errSecItemNotFound else {
			throw LockError.keychainDeleteFailed(status)
		}
	}

}
