//
//  AppDefaults.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import Foundation

final class AppDefaults {

	static let shared = AppDefaults()
	private init() {}
	
	static var store: UserDefaults = {
		let appIdentifierPrefix = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as! String
		let suiteName = "\(appIdentifierPrefix)group.\(Bundle.main.bundleIdentifier!)"
		return UserDefaults.init(suiteName: suiteName)!
	}()
	
	struct Key {
		static let lastSelectedAccountID = "lastSelectedAccountID"
		static let enableCloudKit = "enableCloudKit"
		static let enableLocalAccount = "enableLocalAccount"
		static let ownerName = "ownerName"
		static let ownerEmail = "ownerEmail"
		static let ownerURL = "ownerURL"
		static let lastMainWindowWasClosed = "lastMainWindowWasClosed"
		static let openQuicklyDocumentContainerID = "openQuicklyDocumentContainerID"
		static let outlineFonts = "outlineFonts"
		static let jekyllRootFolder = "jekyllRootFolder"
		static let jekyllPostsFolder = "jekyllPostsFolder"
		static let jekyllImagesFolder = "jekyllImagesFolder"
	}
	
	let isDeveloperBuild: Bool = {
		if let dev = Bundle.main.object(forInfoDictionaryKey: "DeveloperEntitlements") as? String, dev == "-dev" {
			return true
		}
		return false
	}()

	var lastSelectedAccountID: Int {
		get {
			return Self.int(for: Key.lastSelectedAccountID)
		}
		set {
			Self.setInt(for: Key.lastSelectedAccountID, newValue)
		}
	}
	
	var enableCloudKit: Bool {
		get {
			return Self.bool(for: Key.enableCloudKit)
		}
		set {
			Self.setBool(for: Key.enableCloudKit, newValue)
		}
	}

	var enableLocalAccount: Bool {
		get {
			return Self.bool(for: Key.enableLocalAccount)
		}
		set {
			Self.setBool(for: Key.enableLocalAccount, newValue)
		}
	}
	
	var ownerName: String? {
		get {
			NSUbiquitousKeyValueStore.default.string(forKey: Key.ownerName)
		}
		set {
			NSUbiquitousKeyValueStore.default.set(newValue, forKey: Key.ownerName)
		}
	}

	var ownerEmail: String? {
		get {
			NSUbiquitousKeyValueStore.default.string(forKey: Key.ownerEmail)
		}
		set {
			NSUbiquitousKeyValueStore.default.set(newValue, forKey: Key.ownerEmail)
		}
	}
	
	var ownerURL: String? {
		get {
			NSUbiquitousKeyValueStore.default.string(forKey: Key.ownerURL)
		}
		set {
			NSUbiquitousKeyValueStore.default.set(newValue, forKey: Key.ownerURL)
		}
	}
	
	var lastMainWindowWasClosed: Bool {
		get {
			return Self.bool(for: Key.lastMainWindowWasClosed)
		}
		set {
			Self.setBool(for: Key.lastMainWindowWasClosed, newValue)
		}
	}

	var openQuicklyDocumentContainerID: [AnyHashable : AnyHashable]? {
		get {
			return AppDefaults.store.object(forKey: Key.openQuicklyDocumentContainerID) as? [AnyHashable : AnyHashable]
		}
		set {
			AppDefaults.store.set(newValue, forKey: Key.openQuicklyDocumentContainerID)
		}
	}

	var outlineFonts: OutlineFontDefaults? {
		get {
			if let userInfo = AppDefaults.store.object(forKey: Key.outlineFonts) as? [String: [AnyHashable: AnyHashable]] {
				return OutlineFontDefaults(userInfo: userInfo)
			}
			return nil
		}
		set {
			AppDefaults.store.set(newValue?.userInfo, forKey: Key.outlineFonts)
		}
	}

	var jekyllRootFolder: String? {
		get {
			return Self.string(for: Key.jekyllRootFolder)
		}
		set {
			Self.setString(for: Key.jekyllRootFolder, newValue)
		}
	}

	var jekyllPostsFolder: String? {
		get {
			return Self.string(for: Key.jekyllPostsFolder)
		}
		set {
			Self.setString(for: Key.jekyllPostsFolder, newValue)
		}
	}

	var jekyllImagesFolder: String? {
		get {
			return Self.string(for: Key.jekyllImagesFolder)
		}
		set {
			Self.setString(for: Key.jekyllImagesFolder, newValue)
		}
	}

	static func registerDefaults() {
		var defaults: [String : Any] = [Key.enableLocalAccount: true]
		defaults[Key.outlineFonts] = OutlineFontDefaults.defaults.userInfo
		AppDefaults.store.register(defaults: defaults)
	}

}

private extension AppDefaults {

	static func string(for key: String) -> String? {
		return AppDefaults.store.string(forKey: key)
	}
	
	static func setString(for key: String, _ value: String?) {
		AppDefaults.store.set(value, forKey: key)
	}

	static func bool(for key: String) -> Bool {
		return AppDefaults.store.bool(forKey: key)
	}

	static func setBool(for key: String, _ flag: Bool) {
		AppDefaults.store.set(flag, forKey: key)
	}

	static func int(for key: String) -> Int {
		return AppDefaults.store.integer(forKey: key)
	}
	
	static func setInt(for key: String, _ x: Int) {
		AppDefaults.store.set(x, forKey: key)
	}
	
	static func date(for key: String) -> Date? {
		return AppDefaults.store.object(forKey: key) as? Date
	}

	static func setDate(for key: String, _ date: Date?) {
		AppDefaults.store.set(date, forKey: key)
	}
	
}
