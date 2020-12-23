// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// iCloud
  internal static let accountICloud = L10n.tr("Localizable", "Account_iCloud")
  /// On My iPad
  internal static let accountOnMyIPad = L10n.tr("Localizable", "Account_On_My_iPad")
  /// On My iPhone
  internal static let accountOnMyIPhone = L10n.tr("Localizable", "Account_On_My_iPhone")
  /// On My Mac
  internal static let accountOnMyMac = L10n.tr("Localizable", "Account_On_My_Mac")
  /// This doesn't appear to be a Zavala archive.  We're unable to restore from this file.
  internal static let checkArchiveError = L10n.tr("Localizable", "Check_Archive_Error")
  /// Unable to read the import file.
  internal static let folderErrorImportRead = L10n.tr("Localizable", "Folder_Error_Import_Read")
  /// Unable to access security scoped resource.
  internal static let folderErrorScopedResource = L10n.tr("Localizable", "Folder_Error_Scoped_Resource")
  /// All
  internal static let providerAll = L10n.tr("Localizable", "Provider_All")
  /// Favorites
  internal static let providerFavorites = L10n.tr("Localizable", "Provider_Favorites")
  /// Recents
  internal static let providerRecents = L10n.tr("Localizable", "Provider_Recents")
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
