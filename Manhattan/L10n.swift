// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Add Note
  internal static let addNote = L10n.tr("Localizable", "Add_Note")
  /// Add Row
  internal static let addRow = L10n.tr("Localizable", "Add_Row")
  /// Archive %@
  internal static func archiveAccount(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Archive_Account", String(describing: p1))
  }
  /// Bold
  internal static let bold = L10n.tr("Localizable", "Bold")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "Cancel")
  /// Collapse
  internal static let collapse = L10n.tr("Localizable", "Collapse")
  /// Complete
  internal static let complete = L10n.tr("Localizable", "Complete")
  /// Delete
  internal static let delete = L10n.tr("Localizable", "Delete")
  /// Any Outlines in this folder will also be deleted and unrecoverable.
  internal static let deleteFolderMessage = L10n.tr("Localizable", "Delete_Folder_Message")
  /// Are you sure you want to delete the “%@” folder?
  internal static func deleteFolderPrompt(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Delete_Folder_Prompt", String(describing: p1))
  }
  /// Delete Note
  internal static let deleteNote = L10n.tr("Localizable", "Delete_Note")
  /// The outline be deleted and unrecoverable.
  internal static let deleteOutlineMessage = L10n.tr("Localizable", "Delete_Outline_Message")
  /// Are you sure you want to delete the “%@” outline?
  internal static func deleteOutlinePrompt(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Delete_Outline_Prompt", String(describing: p1))
  }
  /// Delete Row
  internal static let deleteRow = L10n.tr("Localizable", "Delete_Row")
  /// Edit outline “%@”
  internal static func editOutline(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Edit_Outline", String(describing: p1))
  }
  /// Error
  internal static let error = L10n.tr("Localizable", "Error")
  /// Expand
  internal static let expand = L10n.tr("Localizable", "Expand")
  /// Export Markdown
  internal static let exportMarkdown = L10n.tr("Localizable", "Export_Markdown")
  /// Export OPML
  internal static let exportOPML = L10n.tr("Localizable", "Export_OPML")
  /// Format
  internal static let format = L10n.tr("Localizable", "Format")
  /// Get Info
  internal static let getInfo = L10n.tr("Localizable", "Get_Info")
  /// Hide Completed
  internal static let hideCompleted = L10n.tr("Localizable", "Hide_Completed")
  /// Import Failed
  internal static let importFailed = L10n.tr("Localizable", "Import Failed")
  /// Import OPML
  internal static let importOPML = L10n.tr("Localizable", "Import_OPML")
  /// Indent
  internal static let indent = L10n.tr("Localizable", "Indent")
  /// Italic
  internal static let italic = L10n.tr("Localizable", "Italic")
  /// Link
  internal static let link = L10n.tr("Localizable", "Link")
  /// Mark as Favorite
  internal static let markAsFavorite = L10n.tr("Localizable", "Mark_As_Favorite")
  /// Move
  internal static let move = L10n.tr("Localizable", "Move")
  /// New Folder
  internal static let newFolder = L10n.tr("Localizable", "New_Folder")
  /// New Outline
  internal static let newOutline = L10n.tr("Localizable", "New_Outline")
  /// New Window
  internal static let newWindow = L10n.tr("Localizable", "New_Window")
  /// Not Available
  internal static let notAvailable = L10n.tr("Localizable", "Not_Available")
  /// Outdent
  internal static let outdent = L10n.tr("Localizable", "Outdent")
  /// Outline
  internal static let outline = L10n.tr("Localizable", "Outline")
  /// Restore
  internal static let restore = L10n.tr("Localizable", "Restore")
  /// Your current account data will be lost and unrecoverable.
  internal static let restoreAccountMessage = L10n.tr("Localizable", "Restore_Account_Message")
  /// Are you sure you want to restore the “%@” account?
  internal static func restoreAccountPrompt(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Restore_Account_Prompt", String(describing: p1))
  }
  /// Restore Archive
  internal static let restoreArchive = L10n.tr("Localizable", "Restore_Archive")
  /// See outlines in “%@”
  internal static func seeOutlinesIn(_ p1: Any) -> String {
    return L10n.tr("Localizable", "See_Outlines_In", String(describing: p1))
  }
  /// Show Completed
  internal static let showCompleted = L10n.tr("Localizable", "Show_Completed")
  /// Split Row
  internal static let splitRow = L10n.tr("Localizable", "Split_Row")
  /// Toggle Sidebar
  internal static let toggleSidebar = L10n.tr("Localizable", "Toggle_Sidebar")
  /// Typing
  internal static let typing = L10n.tr("Localizable", "Typing")
  /// Uncomplete
  internal static let uncomplete = L10n.tr("Localizable", "Uncomplete")
  /// Unmark as Favorite
  internal static let unmarkAsFavorite = L10n.tr("Localizable", "Unmark_As_Favorite")
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
