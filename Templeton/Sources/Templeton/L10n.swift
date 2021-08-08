// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Unable to read the import file.
  internal static let accountErrorImportRead = L10n.tr("Localizable", "Account_Error_Import_Read")
  /// Unable to access security scoped resource.
  internal static let accountErrorScopedResource = L10n.tr("Localizable", "Account_Error_Scoped_Resource")
  /// iCloud
  internal static let accountICloud = L10n.tr("Localizable", "Account_iCloud")
  /// On My iPad
  internal static let accountOnMyIPad = L10n.tr("Localizable", "Account_On_My_iPad")
  /// On My iPhone
  internal static let accountOnMyIPhone = L10n.tr("Localizable", "Account_On_My_iPhone")
  /// On My Mac
  internal static let accountOnMyMac = L10n.tr("Localizable", "Account_On_My_Mac")
  /// Add Note
  internal static let addNote = L10n.tr("Localizable", "Add_Note")
  /// Add Row
  internal static let addRow = L10n.tr("Localizable", "Add_Row")
  /// Add Row Inside
  internal static let addRowInside = L10n.tr("Localizable", "Add_Row_Inside")
  /// Add Row Outside
  internal static let addRowOutside = L10n.tr("Localizable", "Add_Row_Outside")
  /// Add Tag
  internal static let addTag = L10n.tr("Localizable", "Add_Tag")
  /// All
  internal static let all = L10n.tr("Localizable", "All")
  /// This doesn't appear to be a Zavala archive.  We're unable to restore from this file.
  internal static let checkArchiveError = L10n.tr("Localizable", "Check_Archive_Error")
  /// Collapse
  internal static let collapse = L10n.tr("Localizable", "Collapse")
  /// Collapse All
  internal static let collapseAll = L10n.tr("Localizable", "Collapse_All")
  /// Collapse All in Outline
  internal static let collapseAllInOutline = L10n.tr("Localizable", "Collapse_All_In_Outline")
  /// Complete
  internal static let complete = L10n.tr("Localizable", "Complete")
  /// Copy
  internal static let copy = L10n.tr("Localizable", "Copy")
  /// Cut
  internal static let cut = L10n.tr("Localizable", "Cut")
  /// Delete Note
  internal static let deleteNote = L10n.tr("Localizable", "Delete_Note")
  /// Delete Row
  internal static let deleteRow = L10n.tr("Localizable", "Delete_Row")
  /// Delete Tag
  internal static let deleteTag = L10n.tr("Localizable", "Delete_Tag")
  /// Duplicate
  internal static let duplicate = L10n.tr("Localizable", "Duplicate")
  /// Expand
  internal static let expand = L10n.tr("Localizable", "Expand")
  /// Expand All
  internal static let expandAll = L10n.tr("Localizable", "Expand_All")
  /// Expand All in Outline
  internal static let expandAllInOutline = L10n.tr("Localizable", "Expand_All_In_Outline")
  /// Indent
  internal static let indent = L10n.tr("Localizable", "Indent")
  /// Move
  internal static let move = L10n.tr("Localizable", "Move")
  /// Move Down
  internal static let moveDown = L10n.tr("Localizable", "Move_Down")
  /// Move Left
  internal static let moveLeft = L10n.tr("Localizable", "Move_Left")
  /// Move Right
  internal static let moveRight = L10n.tr("Localizable", "Move_Right")
  /// Move Up
  internal static let moveUp = L10n.tr("Localizable", "Move_Up")
  /// Outdent
  internal static let outdent = L10n.tr("Localizable", "Outdent")
  /// Paste
  internal static let paste = L10n.tr("Localizable", "Paste")
  /// Recent
  internal static let recent = L10n.tr("Localizable", "Recent")
  /// Search
  internal static let search = L10n.tr("Localizable", "Search")
  /// Split Row
  internal static let splitRow = L10n.tr("Localizable", "Split_Row")
  /// Typing
  internal static let typing = L10n.tr("Localizable", "Typing")
  /// Uncomplete
  internal static let uncomplete = L10n.tr("Localizable", "Uncomplete")
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
