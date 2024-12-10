//
//  AppDefaults.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit

enum UserInterfaceColorPalette: Int, CustomStringConvertible, CaseIterable {
	case automatic = 0
	case light = 1
	case dark = 2

	var description: String {
		switch self {
		case .automatic:
			return .automaticControlLabel
		case .light:
			return .lightControlLabel
		case .dark:
			return .darkControlLabel
		}
	}
	
}

enum EditorMaxWidth: Int, CustomStringConvertible, CaseIterable {
	case normal = 0
	case wide = 1
	case fullWidth = 2
	
	var pixels: CGFloat? {
		switch self {
		case .normal:
			return UIFontMetrics(forTextStyle: .body).scaledValue(for: 700)
		case .wide:
			return UIFontMetrics(forTextStyle: .body).scaledValue(for: 900)
		case .fullWidth:
			return nil
		}
	}
	
	var description: String {
		switch self {
		case .normal:
			return .normalControlLabel
		case .wide:
			return .wideControlLabel
		case .fullWidth:
			return .fullWidthControlLabel
		}
	}
}

enum ScrollMode: Int, CustomStringConvertible, CaseIterable {
	case normal = 0
	case typewriterCenter = 1
	
	var description: String {
		switch self {
		case .normal:
			return .normalControlLabel
		case .typewriterCenter:
			return .typewriterCenterControlLabel
		}
	}
}

enum DefaultsSize: Int, CustomStringConvertible, CaseIterable {
	case small = 0
	case medium = 1
	case large = 2
	
	var description: String {
		switch self {
		case .small:
			return .smallControlLabel
		case .medium:
			return .mediumControlLabel
		case .large:
			return .largeControlLabel
		}
	}
}

final class AppDefaults {

	nonisolated(unsafe) static let shared = AppDefaults()
	private init() {}
	
	nonisolated(unsafe) static let store: UserDefaults = {
		let appIdentifierPrefix = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as! String
		let suiteName = "\(appIdentifierPrefix)group.\(Bundle.main.bundleIdentifier!)"
		return UserDefaults.init(suiteName: suiteName)!
	}()
	
	struct Key {
		static let lastSelectedAccountID = "lastSelectedAccountID"
		static let enableMainWindowAsDefault = "enableMainWindowAsDefault"
		static let disableEditorAnimations = "disableEditorAnimations"
		static let enableLocalAccount = "enableLocalAccount"
		static let enableCloudKit = "enableCloudKit"
		static let ownerName = "ownerName"
		static let ownerEmail = "ownerEmail"
		static let ownerURL = "ownerURL"
		static let automaticallyCreateLinks = "automaticallyCreateLinks"
		static let autoLinkingEnabled = "autoLinking"
		static let checkSpellingWhileTyping = "checkSpellingWhileTyping"
		static let correctSpellingAutomatically = "correctSpellingAutomatically"
		static let lastMainWindowWasClosed = "lastMainWindowWasClosed"
		static let lastMainWindowState = "lastMainWindowState"
		static let openQuicklyDocumentContainerID = "openQuicklyDocumentContainerID"
		static let userInterfaceColorPalette = "userInterfaceColorPalette";
		static let editorMaxWidth = "editorWidth";
		static let scrollMode = "scrollMode";
		static let rowIndentSize = "rowIndentSize"
		static let rowSpacingSize = "rowSpacingSize"
		static let textZoom = "textZoom"
		static let outlineFonts = "outlineFonts"
		static let documentHistory = "documentHistory"
		static let confirmDeleteCompletedRows = "confirmDeleteCompletedRows"
		static let upgradedDefaultsToV2 = "upgradedDefaultsToV2"
		static let upgradedDefaultsToV2dot3 = "upgradedDefaultsToV2dot3"
		static let upgradedDefaultsToV3dot1 = "upgradedDefaultsToV3dot1"
		static let lastReviewPromptDate = "lastReviewPromptDate"
		static let lastReviewPromptAppVersion = "lastReviewPromptAppVersion"
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
	
	var disableEditorAnimations: Bool {
		get {
			return Self.bool(for: Key.disableEditorAnimations)
		}
		set {
			Self.setBool(for: Key.disableEditorAnimations, newValue)
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
	
	var autoLinkingEnabled: Bool {
		get {
			return NSUbiquitousKeyValueStore.default.bool(forKey: Key.autoLinkingEnabled)
		}
		set {
			NSUbiquitousKeyValueStore.default.set(newValue, forKey: Key.autoLinkingEnabled)
		}
	}
	
	var automaticallyCreateLinks: Bool {
		get {
			return NSUbiquitousKeyValueStore.default.bool(forKey: Key.automaticallyCreateLinks)
		}
		set {
			NSUbiquitousKeyValueStore.default.set(newValue, forKey: Key.automaticallyCreateLinks)
		}
	}
	
	var checkSpellingWhileTyping: Bool {
		get {
			return NSUbiquitousKeyValueStore.default.bool(forKey: Key.checkSpellingWhileTyping)
		}
		set {
			NSUbiquitousKeyValueStore.default.set(newValue, forKey: Key.checkSpellingWhileTyping)
		}
	}
	
	var correctSpellingAutomatically: Bool {
		get {
			return NSUbiquitousKeyValueStore.default.bool(forKey: Key.correctSpellingAutomatically)
		}
		set {
			NSUbiquitousKeyValueStore.default.set(newValue, forKey: Key.correctSpellingAutomatically)
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
	
	var editorMaxWidth: EditorMaxWidth {
		get {
			if let result = EditorMaxWidth(rawValue: Self.int(for: Key.editorMaxWidth)) {
				return result
			}
			return .normal
		}
		set {
			Self.setInt(for: Key.editorMaxWidth, newValue.rawValue)
		}
	}
	
	var scrollMode: ScrollMode {
		get {
			if let result = ScrollMode(rawValue: Self.int(for: Key.scrollMode)) {
				return result
			}
			return .normal
		}
		set {
			Self.setInt(for: Key.scrollMode, newValue.rawValue)
		}
	}
	
	var rowIndentSize: DefaultsSize {
		get {
			return Self.defaultsSize(for: Key.rowIndentSize)
		}
		set {
			Self.setDefaultsSize(for: Key.rowIndentSize, newValue)
		}
	}
	
	var rowSpacingSize: DefaultsSize {
		get {
			return Self.defaultsSize(for: Key.rowSpacingSize)
		}
		set {
			Self.setDefaultsSize(for: Key.rowSpacingSize, newValue)
		}
	}
	
	var textZoom: Int {
		get {
			return Self.int(for: Key.textZoom)
		}
		set {
			Self.setInt(for: Key.textZoom, newValue)
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
	
	var confirmDeleteCompletedRows: Bool {
		get {
			return Self.bool(for: Key.confirmDeleteCompletedRows)
		}
		set {
			Self.setBool(for: Key.confirmDeleteCompletedRows, newValue)
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

	var upgradedDefaultsToV2dot3: Bool {
		get {
			return Self.bool(for: Key.upgradedDefaultsToV2dot3)
		}
		set {
			Self.setBool(for: Key.upgradedDefaultsToV2dot3, newValue)
		}
	}

	var upgradedDefaultsToV3dot1: Bool {
		get {
			return Self.bool(for: Key.upgradedDefaultsToV3dot1)
		}
		set {
			Self.setBool(for: Key.upgradedDefaultsToV3dot1, newValue)
		}
	}

	var lastReviewPromptDate: Date? {
		get {
			Self.date(for: Key.lastReviewPromptDate)
		}
		set {
			Self.setDate(for: Key.lastReviewPromptDate, newValue)
		}
	}

	var lastReviewPromptAppVersion: String? {
		get {
			Self.string(for: Key.lastReviewPromptAppVersion)
		}
		set {
			Self.setString(for: Key.lastReviewPromptAppVersion, newValue)
		}
	}

	static func registerDefaults() {
		var defaults: [String: Any] = [Key.enableLocalAccount: true]
		
		defaults[Key.userInterfaceColorPalette] = UserInterfaceColorPalette.automatic.rawValue
		defaults[Key.outlineFonts] = OutlineFontDefaults.defaults.userInfo
		defaults[Key.confirmDeleteCompletedRows] = true
		defaults[Key.rowIndentSize] = DefaultsSize.medium.rawValue
		defaults[Key.rowSpacingSize] = DefaultsSize.medium.rawValue
		
		AppDefaults.store.register(defaults: defaults)
		
		upgradeDefaultsToV2()
		upgradeDefaultsToV2dot3()
		upgradeDefaultsToV3dot1()
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
	
	static func defaultsSize(for key: String) -> DefaultsSize {
		let intValue = int(for: key)
		return DefaultsSize(rawValue: intValue)!
	}
	
	static func setDefaultsSize(for key: String, _ size: DefaultsSize) {
		setInt(for: key, size.rawValue)
	}
	
	static func upgradeDefaultsToV2() {
		guard !Self.shared.upgradedDefaultsToV2, var outlineFonts = Self.shared.outlineFonts else { return }
		
		if outlineFonts.rowFontConfigs[.tags] == OutlineFontDefaults.tagConfigV1 {
			outlineFonts.rowFontConfigs[.tags] = OutlineFontDefaults.tagConfigV2
		}
		
		Self.shared.outlineFonts = outlineFonts
		Self.shared.upgradedDefaultsToV2 = true
	}

	static func upgradeDefaultsToV2dot3() {
		guard !Self.shared.upgradedDefaultsToV2dot3 else { return }
		
		AppDefaults.shared.checkSpellingWhileTyping = true
		AppDefaults.shared.correctSpellingAutomatically = true

		if let userInfo = AppDefaults.store.object(forKey: Key.outlineFonts) as? [String: [AnyHashable: AnyHashable]] {
			let updatedUserInfo = OutlineFontDefaults.addSecondaryColorFields(userInfo: userInfo)
			AppDefaults.store.set(updatedUserInfo, forKey: Key.outlineFonts)
		}

		Self.shared.upgradedDefaultsToV2dot3 = true
	}
	
	static func upgradeDefaultsToV3dot1() {
		guard !Self.shared.upgradedDefaultsToV3dot1 else { return }
		
		AppDefaults.shared.automaticallyCreateLinks = true
		
		Self.shared.upgradedDefaultsToV3dot1 = true
	}
}
