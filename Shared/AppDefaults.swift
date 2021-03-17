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
	
	static func registerDefaults() {
		let defaults: [String : Any] = [Key.enableLocalAccount: true]
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

	static func sortDirection(for key:String) -> ComparisonResult {
		let rawInt = int(for: key)
		if rawInt == ComparisonResult.orderedAscending.rawValue {
			return .orderedAscending
		}
		return .orderedDescending
	}

	static func setSortDirection(for key: String, _ value: ComparisonResult) {
		if value == .orderedAscending {
			setInt(for: key, ComparisonResult.orderedAscending.rawValue)
		}
		else {
			setInt(for: key, ComparisonResult.orderedDescending.rawValue)
		}
	}
	
}
