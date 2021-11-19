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
		static let enableMainWindowAsDefault = "enableMainWindowAsDefault"
		static let enableLocalAccount = "enableLocalAccount"
		static let enableCloudKit = "enableCloudKit"
		static let ownerName = "ownerName"
		static let ownerEmail = "ownerEmail"
		static let ownerURL = "ownerURL"
		static let lastMainWindowWasClosed = "lastMainWindowWasClosed"
		static let lastMainWindowState = "lastMainWindowState"
		static let openQuicklyDocumentContainerID = "openQuicklyDocumentContainerID"
		static let userInterfaceColorPalette = "userInterfaceColorPalette";
		static let outlineFonts = "outlineFonts"
		static let documentHistory = "documentHistory"
		static let upgradedDefaultsToV2 = "upgradedDefaultsToV2"
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
	
	var enableMainWindowAsDefault: Bool {
		get {
			return Self.bool(for: Key.enableMainWindowAsDefault)
		}
		set {
			Self.setBool(for: Key.enableMainWindowAsDefault, newValue)
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
	
	var enableCloudKit: Bool {
		get {
			return Self.bool(for: Key.enableCloudKit)
		}
		set {
			Self.setBool(for: Key.enableCloudKit, newValue)
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
	
	var lastMainWindowState: [AnyHashable: Any]? {
		get {
			return AppDefaults.store.object(forKey: Key.lastMainWindowState) as? [AnyHashable : Any]
		}
		set {
			AppDefaults.store.set(newValue, forKey: Key.lastMainWindowState)
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

	var userInterfaceColorPalette: UserInterfaceColorPalette {
		get {
			if let result = UserInterfaceColorPalette(rawValue: Self.int(for: Key.userInterfaceColorPalette)) {
				return result
			}
			return .automatic
		}
		set {
			Self.setInt(for: Key.userInterfaceColorPalette, newValue.rawValue)
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

	var documentHistory: [[AnyHashable: AnyHashable]]? {
		get {
			return AppDefaults.store.object(forKey: Key.documentHistory) as? [[AnyHashable: AnyHashable]]
		}
		set {
			AppDefaults.store.set(newValue, forKey: Key.documentHistory)
		}
	}
	
	var upgradedDefaultsToV2: Bool {
		get {
			return Self.bool(for: Key.upgradedDefaultsToV2)
		}
		set {
			Self.setBool(for: Key.upgradedDefaultsToV2, newValue)
		}
	}

	static func registerDefaults() {
		var defaults: [String : Any] = [Key.enableLocalAccount: true]
		defaults[Key.userInterfaceColorPalette] = UserInterfaceColorPalette.automatic.rawValue
		defaults[Key.outlineFonts] = OutlineFontDefaults.defaults.userInfo
		AppDefaults.store.register(defaults: defaults)
		
		upgradeDefaultsToV2()
	}

}

// MARK: Helpers

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
	
	static func data(for key: String) -> Data? {
		return AppDefaults.store.object(forKey: key) as? Data
	}

	static func setData(for key: String, _ data: Data?) {
		AppDefaults.store.set(data, forKey: key)
	}
	
	static func upgradeDefaultsToV2() {
		guard !Self.shared.upgradedDefaultsToV2, var outlineFonts = Self.shared.outlineFonts else { return }
		
		if outlineFonts.rowFontConfigs[.tags] == OutlineFontDefaults.tagConfigV1 {
			outlineFonts.rowFontConfigs[.tags] = OutlineFontDefaults.tagConfigV2
		}
		
		Self.shared.outlineFonts = outlineFonts
		Self.shared.upgradedDefaultsToV2 = true
	}
}
