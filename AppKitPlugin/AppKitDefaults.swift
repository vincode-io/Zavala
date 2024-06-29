//
//  AppKitDefaults.swift
//  AppKitPlugin
//
//  Created by Maurice Parker on 1/6/24.
//

import Foundation

enum UserInterfaceColorPalette: Int, CustomStringConvertible, CaseIterable {
	case automatic = 0
	case light = 1
	case dark = 2
	
	var description: String {
		switch self {
		case .automatic:
			return String(localized: "Automatic", comment: "Control Label: Automatic")
		case .light:
			return String(localized: "Light", comment: "Control Label: Light")
		case .dark:
			return String(localized: "Dark", comment: "Control Label: Dark")
		}
	}
}

final class AppDefaults {

	nonisolated(unsafe) static let shared = AppDefaults()
	private init() {}
	
	nonisolated(unsafe) static var store: UserDefaults = {
		let appIdentifierPrefix = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as! String
		let suiteName = "\(appIdentifierPrefix)group.\(Bundle.main.bundleIdentifier!)"
		return UserDefaults.init(suiteName: suiteName)!
	}()
	
	struct Key {
		static let userInterfaceColorPalette = "userInterfaceColorPalette";
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
	
}
