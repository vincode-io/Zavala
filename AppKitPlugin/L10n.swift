// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Add Note Level
  internal static let addNoteLevel = L10n.tr("Localizable", "Add_Note_Level")
  /// Add Topic Level
  internal static let addTopicLevel = L10n.tr("Localizable", "Add_Topic_Level")
  /// Zavala won't launch while another instance is running. You may have to force quit the other instance.
  internal static let alreadyRunningInfo = L10n.tr("Localizable", "Already_Running_Info")
  /// Zavala was already running.
  internal static let alreadyRunningMessage = L10n.tr("Localizable", "Already_Running_Message")
  /// Automatic
  internal static let automatic = L10n.tr("Localizable", "Automatic")
  /// Backlinks
  internal static let backlinks = L10n.tr("Localizable", "Backlinks")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "Cancel")
  /// Dark
  internal static let dark = L10n.tr("Localizable", "Dark")
  /// Fonts & Colors
  internal static let fontsAndColors = L10n.tr("Localizable", "Fonts_And_Colors")
  /// General
  internal static let general = L10n.tr("Localizable", "General")
  /// Light
  internal static let light = L10n.tr("Localizable", "Light")
  /// Note Level %d
  internal static func noteLevel(_ p1: Int) -> String {
    return L10n.tr("Localizable", "Note_Level", p1)
  }
  /// Open Quickly
  internal static let openQuickly = L10n.tr("Localizable", "Open Quickly")
  /// Remove
  internal static let remove = L10n.tr("Localizable", "Remove")
  /// Are you sure you want to remove the iCloud Account? All documents in the iCloud Account will be removed from this computer.
  internal static let removeCloudKitMessage = L10n.tr("Localizable", "Remove_CloudKit_Message")
  /// Remove iCloud Account
  internal static let removeCloudKitTitle = L10n.tr("Localizable", "Remove_CloudKit_Title")
  /// Restore
  internal static let restore = L10n.tr("Localizable", "Restore")
  /// Are you sure you want to restore the defaults? All your font customizations will be lost.
  internal static let restoreDefaultsInformative = L10n.tr("Localizable", "Restore_Defaults_Informative")
  /// Restore Defaults
  internal static let restoreDefaultsMessage = L10n.tr("Localizable", "Restore_Defaults_Message")
  /// Tags
  internal static let tags = L10n.tr("Localizable", "Tags")
  /// Title
  internal static let title = L10n.tr("Localizable", "Title")
  /// Topic Level %d
  internal static func topicLevel(_ p1: Int) -> String {
    return L10n.tr("Localizable", "Topic_Level", p1)
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
