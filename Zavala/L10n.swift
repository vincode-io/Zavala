// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Acknowledgements
  internal static let acknowledgements = L10n.tr("Localizable", "Acknowledgements")
  /// Add
  internal static let add = L10n.tr("Localizable", "Add")
  /// Add Note
  internal static let addNote = L10n.tr("Localizable", "Add_Note")
  /// Add Row
  internal static let addRow = L10n.tr("Localizable", "Add_Row")
  /// Add Row Above
  internal static let addRowAbove = L10n.tr("Localizable", "Add_Row_Above")
  /// Add Row Below
  internal static let addRowBelow = L10n.tr("Localizable", "Add_Row_Below")
  /// Archive %@
  internal static func archiveAccount(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Archive_Account", String(describing: p1))
  }
  /// Bold
  internal static let bold = L10n.tr("Localizable", "Bold")
  /// Bug Tracker
  internal static let bugTracker = L10n.tr("Localizable", "Bug_Tracker")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "Cancel")
  /// Check for Updates...
  internal static let checkForUpdates = L10n.tr("Localizable", "Check_For_Updates")
  /// Collapse
  internal static let collapse = L10n.tr("Localizable", "Collapse")
  /// Collapse All
  internal static let collapseAll = L10n.tr("Localizable", "Collapse_All")
  /// Collapse All in Outline
  internal static let collapseAllInOutline = L10n.tr("Localizable", "Collapse_All_In_Outline")
  /// Collapse All in Row
  internal static let collapseAllInRow = L10n.tr("Localizable", "Collapse_All_In_Row")
  /// Complete
  internal static let complete = L10n.tr("Localizable", "Complete")
  /// Copy
  internal static let copy = L10n.tr("Localizable", "Copy")
  /// Copy Link
  internal static let copyLink = L10n.tr("Localizable", "Copy_Link")
  /// To help us fix crashing bugs, click “Email It” below. You will have a chance to review the email message before it is sent.
  internal static let crashReporterMessage = L10n.tr("Localizable", "Crash_Reporter_Message")
  /// Crash Log Found
  internal static let crashReporterTitle = L10n.tr("Localizable", "Crash_Reporter_Title")
  /// Created on %@ at %@
  internal static func createdOn(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Created_On", String(describing: p1), String(describing: p2))
  }
  /// Cut
  internal static let cut = L10n.tr("Localizable", "Cut")
  /// Delete
  internal static let delete = L10n.tr("Localizable", "Delete")
  /// Delete Completed Rows
  internal static let deleteCompletedRows = L10n.tr("Localizable", "Delete_Completed_Rows")
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
  /// Delete Rows
  internal static let deleteRows = L10n.tr("Localizable", "Delete_Rows")
  /// Delete Tag
  internal static let deleteTag = L10n.tr("Localizable", "Delete_Tag")
  /// Document Find...
  internal static let documentFind = L10n.tr("Localizable", "Document_Find")
  /// Edit document “%@”
  internal static func editDocument(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Edit_Document", String(describing: p1))
  }
  /// Email It
  internal static let emailIt = L10n.tr("Localizable", "Email_It")
  /// Enable On My iPad
  internal static let enableOnMyIPad = L10n.tr("Localizable", "Enable_On_My_iPad")
  /// Enable On My iPhone
  internal static let enableOnMyIPhone = L10n.tr("Localizable", "Enable_On_My_iPhone")
  /// Error
  internal static let error = L10n.tr("Localizable", "Error")
  /// Expand
  internal static let expand = L10n.tr("Localizable", "Expand")
  /// Expand All
  internal static let expandAll = L10n.tr("Localizable", "Expand_All")
  /// Expand All in Outline
  internal static let expandAllInOutline = L10n.tr("Localizable", "Expand_All_In_Outline")
  /// Expand All in Row
  internal static let expandAllInRow = L10n.tr("Localizable", "Expand_All_In_Row")
  /// Export Markdown
  internal static let exportMarkdown = L10n.tr("Localizable", "Export_Markdown")
  /// Export OPML
  internal static let exportOPML = L10n.tr("Localizable", "Export_OPML")
  /// Find
  internal static let find = L10n.tr("Localizable", "Find")
  /// Find...
  internal static let findEllipsis = L10n.tr("Localizable", "Find_Ellipsis")
  /// Find Next
  internal static let findNext = L10n.tr("Localizable", "Find_Next")
  /// Find Previous
  internal static let findPrevious = L10n.tr("Localizable", "Find_Previous")
  /// Format
  internal static let format = L10n.tr("Localizable", "Format")
  /// Get Info
  internal static let getInfo = L10n.tr("Localizable", "Get_Info")
  /// GitHub Repository
  internal static let gitHubRepository = L10n.tr("Localizable", "GitHub_Repository")
  /// Hide Completed
  internal static let hideCompleted = L10n.tr("Localizable", "Hide_Completed")
  /// Hide Notes
  internal static let hideNotes = L10n.tr("Localizable", "Hide_Notes")
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
  /// More...
  internal static let more = L10n.tr("Localizable", "More")
  /// Move
  internal static let move = L10n.tr("Localizable", "Move")
  /// New Folder
  internal static let newFolder = L10n.tr("Localizable", "New_Folder")
  /// New Main Window
  internal static let newMainWindow = L10n.tr("Localizable", "New_Main_Window")
  /// New Outline
  internal static let newOutline = L10n.tr("Localizable", "New_Outline")
  /// Next Result
  internal static let nextResult = L10n.tr("Localizable", "Next_Result")
  /// Not Available
  internal static let notAvailable = L10n.tr("Localizable", "Not_Available")
  /// Open Quickly...
  internal static let openQuickly = L10n.tr("Localizable", "Open_Quickly")
  /// Open Quickly
  internal static let openQuicklyPlaceholder = L10n.tr("Localizable", "Open_Quickly_Placeholder")
  /// Outdent
  internal static let outdent = L10n.tr("Localizable", "Outdent")
  /// Outline
  internal static let outline = L10n.tr("Localizable", "Outline")
  /// Paste
  internal static let paste = L10n.tr("Localizable", "Paste")
  /// Preferences...
  internal static let preferences = L10n.tr("Localizable", "Preferences")
  /// Previous Result
  internal static let previousResult = L10n.tr("Localizable", "Previous_Result")
  /// Print
  internal static let print = L10n.tr("Localizable", "Print")
  /// Reference: 
  internal static let reference = L10n.tr("Localizable", "Reference")
  /// References: 
  internal static let references = L10n.tr("Localizable", "References")
  /// Release Notes
  internal static let releaseNotes = L10n.tr("Localizable", "Release_Notes")
  /// Remove
  internal static let remove = L10n.tr("Localizable", "Remove")
  /// Are you sure you want to remove the iCloud Account? All documents in the iCloud Account will be removed from this device.
  internal static let removeCloudKitMessage = L10n.tr("Localizable", "Remove_CloudKit_Message")
  /// Remove iCloud Account
  internal static let removeCloudKitTitle = L10n.tr("Localizable", "Remove_CloudKit_Title")
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
  /// Search
  internal static let search = L10n.tr("Localizable", "Search")
  /// See documents in “%@”
  internal static func seeDocumentsIn(_ p1: Any) -> String {
    return L10n.tr("Localizable", "See_Documents_In", String(describing: p1))
  }
  /// Send a Copy
  internal static let sendCopy = L10n.tr("Localizable", "Send_Copy")
  /// Share
  internal static let share = L10n.tr("Localizable", "Share")
  /// Show Completed
  internal static let showCompleted = L10n.tr("Localizable", "Show_Completed")
  /// Show Notes
  internal static let showNotes = L10n.tr("Localizable", "Show_Notes")
  /// Split Row
  internal static let splitRow = L10n.tr("Localizable", "Split_Row")
  /// Sync with iCloud
  internal static let sync = L10n.tr("Localizable", "Sync")
  /// Tag
  internal static let tag = L10n.tr("Localizable", "Tag")
  /// Toggle Sidebar
  internal static let toggleSidebar = L10n.tr("Localizable", "Toggle_Sidebar")
  /// Typing
  internal static let typing = L10n.tr("Localizable", "Typing")
  /// Uncomplete
  internal static let uncomplete = L10n.tr("Localizable", "Uncomplete")
  /// Unmark as Favorite
  internal static let unmarkAsFavorite = L10n.tr("Localizable", "Unmark_As_Favorite")
  /// Updated on %@ at %@
  internal static func updatedOn(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Updated_On", String(describing: p1), String(describing: p2))
  }
  /// Use Selection For Find
  internal static let useSelectionForFind = L10n.tr("Localizable", "Use_Selection_For_Find")
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
