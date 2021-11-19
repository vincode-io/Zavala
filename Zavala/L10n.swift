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
  /// Add Note Level
  internal static let addNoteLevel = L10n.tr("Localizable", "Add_Note_Level")
  /// Add Row
  internal static let addRow = L10n.tr("Localizable", "Add_Row")
  /// Add Row Above
  internal static let addRowAbove = L10n.tr("Localizable", "Add_Row_Above")
  /// Add Row Below
  internal static let addRowBelow = L10n.tr("Localizable", "Add_Row_Below")
  /// Add Row Inside
  internal static let addRowInside = L10n.tr("Localizable", "Add_Row_Inside")
  /// Add Row Outside
  internal static let addRowOutside = L10n.tr("Localizable", "Add_Row_Outside")
  /// Add Topic Level
  internal static let addTopicLevel = L10n.tr("Localizable", "Add_Topic_Level")
  /// Archive %@
  internal static func archiveAccount(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Archive_Account", String(describing: p1))
  }
  /// Automatic
  internal static let automatic = L10n.tr("Localizable", "Automatic")
  /// Back
  internal static let back = L10n.tr("Localizable", "Back")
  /// Backlinks
  internal static let backlinks = L10n.tr("Localizable", "Backlinks")
  /// Bold
  internal static let bold = L10n.tr("Localizable", "Bold")
  /// Bug Tracker
  internal static let bugTracker = L10n.tr("Localizable", "Bug_Tracker")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "Cancel")
  /// Collaborate
  internal static let collaborate = L10n.tr("Localizable", "Collaborate")
  /// Collaborate…
  internal static let collaborateEllipsis = L10n.tr("Localizable", "Collaborate_Ellipsis")
  /// Collapse
  internal static let collapse = L10n.tr("Localizable", "Collapse")
  /// Collapse All
  internal static let collapseAll = L10n.tr("Localizable", "Collapse_All")
  /// Collapse All in Outline
  internal static let collapseAllInOutline = L10n.tr("Localizable", "Collapse_All_In_Outline")
  /// Collapse All in Row
  internal static let collapseAllInRow = L10n.tr("Localizable", "Collapse_All_In_Row")
  /// Collapse Parent Row
  internal static let collapseParentRow = L10n.tr("Localizable", "Collapse_Parent_Row")
  /// Complete
  internal static let complete = L10n.tr("Localizable", "Complete")
  /// Copy
  internal static let copy = L10n.tr("Localizable", "Copy")
  /// Copy Document Link
  internal static let copyDocumentLink = L10n.tr("Localizable", "Copy_Document_Link")
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
  /// Dark
  internal static let dark = L10n.tr("Localizable", "Dark")
  /// Delete
  internal static let delete = L10n.tr("Localizable", "Delete")
  /// Always Delete Without Asking
  internal static let deleteAlways = L10n.tr("Localizable", "Delete_Always")
  /// Are you sure you want to delete the completed rows?
  internal static let deleteCompletedMessage = L10n.tr("Localizable", "Delete_Completed_Message")
  /// Delete Completed Rows
  internal static let deleteCompletedRows = L10n.tr("Localizable", "Delete_Completed_Rows")
  /// Delete Completed Rows
  internal static let deleteCompletedTitle = L10n.tr("Localizable", "Delete_Completed_Title")
  /// Delete Note
  internal static let deleteNote = L10n.tr("Localizable", "Delete_Note")
  /// Delete Once
  internal static let deleteOnce = L10n.tr("Localizable", "Delete_Once")
  /// Delete Outline
  internal static let deleteOutline = L10n.tr("Localizable", "Delete_Outline")
  /// The outline be deleted and unrecoverable.
  internal static let deleteOutlineMessage = L10n.tr("Localizable", "Delete_Outline_Message")
  /// Are you sure you want to delete the “%@” outline?
  internal static func deleteOutlinePrompt(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Delete_Outline_Prompt", String(describing: p1))
  }
  /// The outlines be deleted and unrecoverable.
  internal static let deleteOutlinesMessage = L10n.tr("Localizable", "Delete_Outlines_Message")
  /// Are you sure you want to delete %d outlines?
  internal static func deleteOutlinesPrompt(_ p1: Int) -> String {
    return L10n.tr("Localizable", "Delete_Outlines_Prompt", p1)
  }
  /// Delete Row
  internal static let deleteRow = L10n.tr("Localizable", "Delete_Row")
  /// Delete Rows
  internal static let deleteRows = L10n.tr("Localizable", "Delete_Rows")
  /// Delete Tag
  internal static let deleteTag = L10n.tr("Localizable", "Delete_Tag")
  /// No Outlines associated with this tag will be deleted.
  internal static let deleteTagMessage = L10n.tr("Localizable", "Delete_Tag_Message")
  /// Are you sure you want to delete the “%@” tag?
  internal static func deleteTagPrompt(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Delete_Tag_Prompt", String(describing: p1))
  }
  /// No Outlines associated with these tags will be deleted.
  internal static let deleteTagsMessage = L10n.tr("Localizable", "Delete_Tags_Message")
  /// Are you sure you want to delete %d tags?
  internal static func deleteTagsPrompt(_ p1: Int) -> String {
    return L10n.tr("Localizable", "Delete_Tags_Prompt", p1)
  }
  /// Document Find…
  internal static let documentFindEllipsis = L10n.tr("Localizable", "Document_Find_Ellipsis")
  /// Done
  internal static let done = L10n.tr("Localizable", "Done")
  /// Duplicate
  internal static let duplicate = L10n.tr("Localizable", "Duplicate")
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
  /// Export
  internal static let export = L10n.tr("Localizable", "Export")
  /// Export Markdown Doc…
  internal static let exportMarkdownDocEllipsis = L10n.tr("Localizable", "Export_Markdown_Doc_Ellipsis")
  /// Export Markdown List…
  internal static let exportMarkdownListEllipsis = L10n.tr("Localizable", "Export_Markdown_List_Ellipsis")
  /// Export OPML…
  internal static let exportOPMLEllipsis = L10n.tr("Localizable", "Export_OPML_Ellipsis")
  /// Export PDF Doc…
  internal static let exportPDFDocEllipsis = L10n.tr("Localizable", "Export_PDF_Doc_Ellipsis")
  /// Export PDF List…
  internal static let exportPDFListEllipsis = L10n.tr("Localizable", "Export_PDF_List_Ellipsis")
  /// Find
  internal static let find = L10n.tr("Localizable", "Find")
  /// Find…
  internal static let findEllipsis = L10n.tr("Localizable", "Find_Ellipsis")
  /// Find Next
  internal static let findNext = L10n.tr("Localizable", "Find_Next")
  /// Find Previous
  internal static let findPrevious = L10n.tr("Localizable", "Find_Previous")
  /// Format
  internal static let format = L10n.tr("Localizable", "Format")
  /// Forward
  internal static let forward = L10n.tr("Localizable", "Forward")
  /// Get Info
  internal static let getInfo = L10n.tr("Localizable", "Get_Info")
  /// GitHub Repository
  internal static let gitHubRepository = L10n.tr("Localizable", "GitHub_Repository")
  /// Go Backward
  internal static let goBackward = L10n.tr("Localizable", "Go_Backward")
  /// Go Forward
  internal static let goForward = L10n.tr("Localizable", "Go_Forward")
  /// Hide Completed
  internal static let hideCompleted = L10n.tr("Localizable", "Hide_Completed")
  /// Hide Notes
  internal static let hideNotes = L10n.tr("Localizable", "Hide_Notes")
  /// History
  internal static let history = L10n.tr("Localizable", "History")
  /// Image
  internal static let image = L10n.tr("Localizable", "Image")
  /// Import Failed
  internal static let importFailed = L10n.tr("Localizable", "Import Failed")
  /// Import OPML
  internal static let importOPML = L10n.tr("Localizable", "Import_OPML")
  /// Import OPML…
  internal static let importOPMLEllipsis = L10n.tr("Localizable", "Import_OPML_Ellipsis")
  /// Insert Image
  internal static let insertImage = L10n.tr("Localizable", "Insert_Image")
  /// Insert Image…
  internal static let insertImageEllipsis = L10n.tr("Localizable", "Insert_Image_Ellipsis")
  /// Italic
  internal static let italic = L10n.tr("Localizable", "Italic")
  /// Light
  internal static let light = L10n.tr("Localizable", "Light")
  /// Link
  internal static let link = L10n.tr("Localizable", "Link")
  /// Link…
  internal static let linkEllipsis = L10n.tr("Localizable", "Link_Ellipsis")
  /// Mark as Favorite
  internal static let markAsFavorite = L10n.tr("Localizable", "Mark_As_Favorite")
  /// More…
  internal static let more = L10n.tr("Localizable", "More")
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
  /// Multiple Selections
  internal static let multipleSelections = L10n.tr("Localizable", "Multiple_Selections")
  /// Navigation
  internal static let navigation = L10n.tr("Localizable", "Navigation")
  /// New Folder
  internal static let newFolder = L10n.tr("Localizable", "New_Folder")
  /// New Main Window
  internal static let newMainWindow = L10n.tr("Localizable", "New_Main_Window")
  /// New Outline
  internal static let newOutline = L10n.tr("Localizable", "New_Outline")
  /// Next Result
  internal static let nextResult = L10n.tr("Localizable", "Next_Result")
  /// (No Title)
  internal static let noTitle = L10n.tr("Localizable", "No_Title")
  /// Not Available
  internal static let notAvailable = L10n.tr("Localizable", "Not_Available")
  /// Note Level %d
  internal static func noteLevel(_ p1: Int) -> String {
    return L10n.tr("Localizable", "Note_Level", p1)
  }
  /// Open Quickly…
  internal static let openQuicklyEllipsis = L10n.tr("Localizable", "Open_Quickly_Ellipsis")
  /// Open Quickly
  internal static let openQuicklyPlaceholder = L10n.tr("Localizable", "Open_Quickly_Placeholder")
  /// Outline
  internal static let outline = L10n.tr("Localizable", "Outline")
  /// Paste
  internal static let paste = L10n.tr("Localizable", "Paste")
  /// Preferences…
  internal static let preferencesEllipsis = L10n.tr("Localizable", "Preferences_Ellipsis")
  /// Previous Result
  internal static let previousResult = L10n.tr("Localizable", "Previous_Result")
  /// Print Doc
  internal static let printDoc = L10n.tr("Localizable", "Print_Doc")
  /// Print Doc…
  internal static let printDocEllipsis = L10n.tr("Localizable", "Print_Doc_Ellipsis")
  /// Print List
  internal static let printList = L10n.tr("Localizable", "Print_List")
  /// Print List…
  internal static let printListEllipsis = L10n.tr("Localizable", "Print_List_Ellipsis")
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
  /// Remove Tag
  internal static let removeTag = L10n.tr("Localizable", "Remove_Tag")
  /// Rename
  internal static let rename = L10n.tr("Localizable", "Rename")
  /// Restore
  internal static let restore = L10n.tr("Localizable", "Restore")
  /// Restore Archive
  internal static let restoreArchive = L10n.tr("Localizable", "Restore_Archive")
  /// Are you sure you want to restore the defaults? All your font customizations will be lost.
  internal static let restoreDefaultsInformative = L10n.tr("Localizable", "Restore_Defaults_Informative")
  /// Restore Defaults
  internal static let restoreDefaultsMessage = L10n.tr("Localizable", "Restore_Defaults_Message")
  /// Search
  internal static let search = L10n.tr("Localizable", "Search")
  /// See documents in “%@”
  internal static func seeDocumentsIn(_ p1: Any) -> String {
    return L10n.tr("Localizable", "See_Documents_In", String(describing: p1))
  }
  /// Select
  internal static let select = L10n.tr("Localizable", "Select")
  /// Share
  internal static let share = L10n.tr("Localizable", "Share")
  /// Share…
  internal static let shareEllipsis = L10n.tr("Localizable", "Share_Ellipsis")
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
  /// Tags
  internal static let tags = L10n.tr("Localizable", "Tags")
  /// Title
  internal static let title = L10n.tr("Localizable", "Title")
  /// Toggle Sidebar
  internal static let toggleSidebar = L10n.tr("Localizable", "Toggle_Sidebar")
  /// Topic Level %d
  internal static func topicLevel(_ p1: Int) -> String {
    return L10n.tr("Localizable", "Topic_Level", p1)
  }
  /// Twitter
  internal static let twitter = L10n.tr("Localizable", "Twitter")
  /// Typing
  internal static let typing = L10n.tr("Localizable", "Typing")
  /// Uncomplete
  internal static let uncomplete = L10n.tr("Localizable", "Uncomplete")
  /// The requested outline could not be found.
  internal static let unknownOutline = L10n.tr("Localizable", "Unknown_Outline")
  /// Unmark as Favorite
  internal static let unmarkAsFavorite = L10n.tr("Localizable", "Unmark_As_Favorite")
  /// Updated on %@ at %@
  internal static func updatedOn(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Updated_On", String(describing: p1), String(describing: p2))
  }
  /// Use Selection For Find
  internal static let useSelectionForFind = L10n.tr("Localizable", "Use_Selection_For_Find")
  /// Website
  internal static let website = L10n.tr("Localizable", "Website")
  /// Zavala Help
  internal static let zavalaHelp = L10n.tr("Localizable", "Zavala_Help")
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
