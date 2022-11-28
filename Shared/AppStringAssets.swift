//
//  AppStringAssets.swift
//  Zavala
//
//  Created by Maurice Parker on 10/6/22.
//

import Foundation

struct AppStringAssets {
	
	private static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
		return dateFormatter
	}()
	
	private static let timeFormatter: DateFormatter = {
		let timeFormatter = DateFormatter()
		timeFormatter.dateStyle = .none
		timeFormatter.timeStyle = .short
		return timeFormatter
	}()
	
	// MARK: URL's
	
	static var acknowledgementsURL = "https://github.com/vincode-io/Zavala/wiki/Acknowledgements"
	static var bugTrackerURL = "https://github.com/vincode-io/Zavala/issues"
	static var feedbackURL = "mailto:mo@vincode.io"
	static var githubRepositoryURL = "https://github.com/vincode-io/Zavala"
	static var helpURL = "https://zavala.vincode.io/help/Zavala_Help.md/"
	static var privacyPolicyURL = "https://vincode.io/privacy-policy/"
	static var releaseNotesURL = "https://github.com/vincode-io/Zavala/releases/tag/\(Bundle.main.versionNumber)"
	static var websiteURL = "https://zavala.vincode.io"
	
	// MARK: Localizable Variables
	
	static var acknowledgementsControlLabel = String(localized: "Acknowledgements", comment: "Control Label: Acknowledgements")
	static var addControlLabel = String(localized: "Add", comment: "Control Label: Add")
	static var addNoteControlLabel = String(localized: "Add Note", comment: "Control Label: Add Note.")
	static var addNoteLevelControlLabel = String(localized: "Add Note Level", comment: "Control Label: The menu option to add a new Note Level.")
	static var addRowAboveControlLabel = String(localized: "Add Row Above", comment: "Control Label: Add Row Above")
	static var addRowAfterControlLabel = String(localized: "Add Row After", comment: "Control Label: Add Row After")
	static var addRowBelowControlLabel = String(localized: "Add Row Below", comment: "Control Label: Add Row Below")
	static var addRowControlLabel = String(localized: "Add Row", comment: "Control Label: Add Row")
	static var addRowInsideControlLabel = String(localized: "Add Row Inside", comment: "Control Label: Add Row Inside")
	static var addRowOutsideControlLabel = String(localized: "Add Row Outside", comment: "Control Label: Add Row Outside")
	static var addTagControlLabel = String(localized: "Add Tag", comment: "Control Label: Add Tag.")
	static var addTopicLevelControlLabel = String(localized: "Add Topic Level", comment: "Control Label: The menu option to add a new Topic Level.")
	static var appearanceControlLabel = String(localized: "Appearance", comment: "Control Label: Appearance")
	
	static var backControlLabel = String(localized: "Back", comment: "Control Label: Back")
	static var backlinksLabel = String(localized: "Backlinks", comment: "Font Label: Backlinks")
	static var boldControlLabel = String(localized: "Bold", comment: "Control Label: Bold")
	static var bugTrackerControlLabel = String(localized: "Bug Tracker", comment: "Control Label: Bug Tracker")
	
	static var cancelControlLabel = String(localized: "Cancel", comment: "Control Label: Cancel the proposed action")
	static var collaborateControlLabel = String(localized: "Collaborate", comment: "Control Label: Collaborate")
	static var collaborateEllipsisControlLabel = String(localized: "Collaborate…", comment: "Control Label: Collaborate…")
	static var collapseAllControlLabel = String(localized: "Collapse All", comment: "Control Label: Collapse All")
	static var collapseAllInOutlineControlLabel = String(localized: "Collapse All in Outline", comment: "Control Label: Collapse All in Outline")
	static var collapseAllInRowControlLabel = String(localized: "Collapse All in Row", comment: "Control Label: Collapse All in Row")
	static var collapseControlLabel = String(localized: "Collapse", comment: "Control Label: Collapse")
	static var collapseParentRowControlLabel = String(localized: "Collapse Parent Row", comment: "Control Label: Collapse Parent Row")
	static var completeAccessibilityLabel = String(localized: "Complete", comment: "Accessibility Label: Complete")
	static var completeControlLabel = String(localized: "Complete", comment: "Control Label: Complete")
	static var copyControlLabel = String(localized: "Copy", comment: "Control Label: Copy")
	static var copyDocumentLinkControlLabel = String(localized: "Copy Document Link", comment: "Control Label: Copy Document Link")
	static var copyDocumentLinksControlLabel = String(localized: "Copy Document Links", comment: "Control Label: Copy Document Links")
	static var cutControlLabel = String(localized: "Cut", comment: "Control Label: Cut")
	
	static var deleteAlwaysControlLabel = String(localized: "Always Delete Without Asking", comment: "Control Label: Always Delete Without Asking")
	static var deleteCompletedRowsControlLabel = String(localized: "Delete Completed", comment: "Control Label: Delete Completed Rows")
	static var deleteCompletedRowsTitle = String(localized: "Delete Completed Rows", comment: "Alert Title: Delete Completed Rows")
	static var deleteCompletedRowsMessage = String(localized: "Are you sure you want to delete the completed rows?", comment: "Alert Message: Delete Completed Rows")
	static var deleteControlLabel = String(localized: "Delete", comment: "Control Label: Delete an entity")
	static var deleteOnceControlLabel = String(localized: "Delete Once", comment: "Control Label: Delete Once")
	static var deleteOutlineControlLabel = String(localized: "Delete Outline", comment: "Control Label: Delete Outline")
	static var deleteOutlineMessage = String(localized: "The outline be deleted and unrecoverable.", comment: "Alert Message: delete outline")
	static var deleteOutlinesMessage = String(localized: "The outlines be deleted and unrecoverable.", comment: "Alert Message: delete outline")
	static var deleteNoteControlLabel = String(localized: "Delete Note", comment: "Control Label: Delete Note")
	static var deleteRowControlLabel = String(localized: "Delete Row", comment: "Control Label: Delete Row")
	static var deleteRowsControlLabel = String(localized: "Delete Rows", comment: "Control Label: Delete Rows")
	static var deleteTagMessage = String(localized: "No Outlines associated with this tag will be deleted.", comment: "Alert Message: delete tag")
	static var deleteTagsMessage = String(localized: "No Outlines associated with these tags will be deleted.", comment: "Alert Message: delete tags")
	static var documentFindEllipsisControlLabel = String(localized: "Document Find…", comment: "Control Label: Document Find…")
	static var doneControlLabel = String(localized: "Done", comment: "Control Label: Done")
	static var duplicateControlLabel = String(localized: "Duplicate", comment: "Control Label: Duplicate")
	
	static var enableOnMyIPhoneLabel = String(localized: "Enable On My iPhone", comment: "Label: Enable On My iPhone")
	static var enableOnMyIPadLabel = String(localized: "Enable On My iPad", comment: "Label: Enable On My iPad")
	static var errorAlertTitle = String(localized: "Error", comment: "Alert Title: Error")
	static var exportControlLabel = String(localized: "Export", comment: "Control Label: Export")
	static var exportMarkdownDocEllipsisControlLabel = String(localized: "Export Markdown Doc…", comment: "Control Label: Export Markdown Doc…")
	static var exportMarkdownListEllipsisControlLabel = String(localized: "Export Markdown List…", comment: "Control Label: Export Markdown List…")
	static var exportPDFDocEllipsisControlLabel = String(localized: "Export PDF Doc…", comment: "Control Label: Export PDF Doc…")
	static var exportPDFListEllipsisControlLabel = String(localized: "Export Export PDF List…", comment: "Control Label: Export PDF List…")
	static var exportOPMLEllipsisControlLabel = String(localized: "Export OPML…", comment: "Control Label: Export OPML…")
	static var expandAllControlLabel = String(localized: "Expand All", comment: "Control Label: Expand All")
	static var expandAllInOutlineControlLabel = String(localized: "Expand All in Outline", comment: "Control Label: Expand All in Outline")
	static var expandAllInRowControlLabel = String(localized: "Expand All in Row", comment: "Control Label: Expand All in Row")
	static var expandControlLabel = String(localized: "Expand", comment: "Control Label: Expand")
	
	static var feedbackControlLabel = String(localized: "Feedback", comment: "Control Label: Feedback")
	static var filterControlLabel = String(localized: "Filter", comment: "Control Label: Filter")
	static var filterCompletedControlLabel = String(localized: "Filter Completed", comment: "Control Label: Filter Completed")
	static var filterNotesControlLabel = String(localized: "Filter Notes", comment: "Control Label: Filter Notes")
	static var findControlLabel = String(localized: "Find", comment: "Control Label: Find")
	static var findEllipsisControlLabel = String(localized: "Find…", comment: "Control Label: Find…")
	static var findNextControlLabel = String(localized: "Find Next", comment: "Control Label: Find Next")
	static var findPreviousControlLabel = String(localized: "Find Previous", comment: "Control Label: Find Previous")
	static var formatControlLabel = String(localized: "Format", comment: "Control Label: Format")
	static var forwardControlLabel = String(localized: "Forward", comment: "Control Label: Forward")
	
	static var getInfoControlLabel = String(localized: "Get Info", comment: "Control Label: Get Info")
	static var generalControlLabel = String(localized: "General", comment: "Control Label: General")
	static var gitHubRepositoryControlLabel = String(localized: "GitHub Repository", comment: "Control Label: GitHub Repository")
	static var goBackwardControlLabel = String(localized: "Go Backward", comment: "Control Label: Go Backward")
	static var goForwardControlLabel = String(localized: "Go Forward", comment: "Control Label: Go Forward")
	
	static var hideKeyboardControlLabel = String(localized: "Hide Keyboard", comment: "Control Label: Hide Keyboard")
	static var historyControlLabel = String(localized: "History", comment: "Control Label: History")
	
	static var imageControlLabel = String(localized: "Image", comment: "Control Label: Image")
	static var importFailedTitle = String(localized: "Import Failed", comment: "Error Message Title: Import Failed")
	static var importOPMLControlLabel = String(localized: "Import OPML", comment: "Control Label: Import OPML")
	static var importOPMLEllipsisControlLabel = String(localized: "Import OPML…", comment: "Control Label: Import OPML…")
	static var insertImageControlLabel = String(localized: "Insert Image", comment: "Control Label: Insert Image")
	static var insertImageEllipsisControlLabel = String(localized: "Insert Image…", comment: "Control Label: Insert Image…")
	static var italicControlLabel = String(localized: "Italic", comment: "Control Label: Italic")
	
	static var linkControlLabel = String(localized: "Link", comment: "Control Label: Link")
	static var linkEllipsisControlLabel = String(localized: "Link…", comment: "Control Label: Link…")
	
	static var moreControlLabel = String(localized: "More", comment: "Control Label: More")
	static var moveControlLabel = String(localized: "Move", comment: "Control Label: Move")
	static var moveRightControlLabel = String(localized: "Move Right", comment: "Control Label: Move Right")
	static var moveLeftControlLabel = String(localized: "Move Left", comment: "Control Label: Move Left")
	static var moveUpControlLabel = String(localized: "Move Up", comment: "Control Label: Move Up")
	static var moveDownControlLabel = String(localized: "Move Down", comment: "Control Label: Move Down")
	static var multipleSelectionsLabel = String(localized: "Multiple Selections", comment: "Large Label: Multiple Selections")
	
	static var navigationControlLabel = String(localized: "Navigation", comment: "Control Label: Navigation")
	static var newMainWindowControlLabel = String(localized: "New Main Window", comment: "Control Label: New Main Window")
	static var newOutlineControlLabel = String(localized: "New New Outline", comment: "Control Label: New New Outline")
	static var nextResultControlLabel = String(localized: "Next Result", comment: "Control Label: Next Result")
	static var noSelectionLabel = String(localized: "No Selection", comment: "Large Label: No Selection")
	static var noTitleLabel = String(localized: "(No Title)", comment: "Control Label: (No Title)")
	
	static var openQuicklyEllipsisControlLabel = String(localized: "Open Quickly…", comment: "Control Label: Open Quickly…")
	static var openQuicklySearchPlaceholder = String(localized: "Open Quickly", comment: "Search Field Placeholder: Open Quickly")
	static var openQuicklyWindowTitle = String(localized: "Open Quickly", comment: "Window Title: Open Quickly")
	static var outlineControlLabel = String(localized: "Outline", comment: "Control Label: Outline")
	
	static var pasteControlLabel = String(localized: "Paste", comment: "Control Label: Paste")
	static var preferencesEllipsisControlLabel = String(localized: "Preferences…", comment: "Control Label: Preferences…")
	static var previousResultControlLabel = String(localized: "Previous Result", comment: "Control Label: Previous Result")
	static var printControlLabel = String(localized: "Print", comment: "Control Label: Print")
	static var printDocControlLabel = String(localized: "Print Doc", comment: "Control Label: Print Doc")
	static var printDocEllipsisControlLabel = String(localized: "Print Doc…", comment: "Control Label: Print Doc…")
	static var printListControlLabel = String(localized: "Print List", comment: "Control Label: Print List")
	static var printListControlEllipsisLabel = String(localized: "Print List…", comment: "Control Label: Print List…")
	static var privacyPolicyControlLabel = String(localized: "Privacy Policy", comment: "Control Label: Privacy Policy")
	
	static var releaseNotesControlLabel = String(localized: "Release Notes", comment: "Control Label: Release Notes")
	static var removeControlLabel = String(localized: "Remove", comment: "Control Label: Remove")
	static var removeICloudAccountTitle = String(localized: "Remove iCloud Account", comment: "Alert Title: title for removing an iCloud Account")
	static var removeICloudAccountMessage = String(localized: "Are you sure you want to remove the iCloud Account? " +
												   "All documents in the iCloud Account will be removed from this computer.",
												   comment: "Alert Message: message for removing an iCloud Account")
	static var removeTagControlLabel = String(localized: "Remove Tag", comment: "Control Label: Remove Tag")
	static var renameControlLabel = String(localized: "Rename", comment: "Control Label: Rename")
	static var referenceLabel = String(localized: "Reference: ", comment: "Label: reference label for backlinks")
	static var referencesLabel = String(localized: "References: ", comment: "Label: references label for backlinks")
	static var restoreControlLabel = String(localized: "Restore", comment: "Control Label: Restore")
	static var restoreDefaultsMessage = String(localized: "Restore Defaults", comment: "Alert: message for restoring font defaults")
	static var restoreDefaultsInformative = String(localized: "Are you sure you want to restore the defaults? All your font customizations will be lost.",
												   comment: "Alert: information for restoring font defaults")
	
	static var searchPlaceholder = String(localized: "Search", comment: "Field Placeholder: Search")
	static var selectControlLabel = String(localized: "Select", comment: "Control Label: Select")
	static var settingsEllipsisControlLabel = String(localized: "Settings…", comment: "Control Label: Settings…")
	static var shareControlLabel = String(localized: "Share", comment: "Control Label: Share")
	static var shareEllipsisControlLabel = String(localized: "Share…", comment: "Control Label: Share…")
	static var splitRowControlLabel = String(localized: "Split Row", comment: "Control Label: Split Row")
	static var syncControlLabel = String(localized: "Sync", comment: "Control Label: Sync")
	
	static var tagsLabel = String(localized: "Tags", comment: "Font Label: Tags")
	static var tagDataEntryPlaceholder = String(localized: "Tag", comment: "Data Entry Placeholder: Tag")
	static var titleLabel = String(localized: "Title", comment: "Font Label: Title")
	static var togglerSidebarControlLabel = String(localized: "Toggle Sidebar", comment: "Control Label: Toggle Sidebar")
	static var turnFilterOffControlLabel = String(localized: "Turn Filter Off", comment: "Control Label: Turn Filter Off")
	static var turnFilterOnControlLabel = String(localized: "Turn Filter On", comment: "Control Label: Turn Filter On")
	static var typingControlLabel = String(localized: "Typing", comment: "Control Label: Typing")
	
	static var useSelectionForFindControlLabel = String(localized: "Use Selection For Find", comment: "Control Label: Use Selection For Find")
	static var uncompleteControlLabel = String(localized: "Uncomplete", comment: "Control Label: Uncomplete")
	
	static var websiteControlLabel = String(localized: "Website", comment: "Control Label: Website")
	
	static var zavalaHelpControlLabel = String(localized: "Zavala Help", comment: "Control Label: Zavala Help")
	
	// MARK: Localizable Functions
	
	static func createdOnLabel(date: Date) -> String {
		let dateString = dateFormatter.string(from: date)
		let timeString = timeFormatter.string(from: date)
		return String(localized: "Created on \(dateString) at \(timeString)", comment: "Timestame Label: Created")
	}
	
	static func updatedOnLabel(date: Date) -> String {
		let dateString = dateFormatter.string(from: date)
		let timeString = timeFormatter.string(from: date)
		return String(localized: "Updated on \(dateString) at \(timeString)", comment: "Timestame Label: Updated")
	}
	
	static func deleteOutlinePrompt(outlineTitle: String) -> String {
		return String(localized: "Are you sure you want to delete the “\(outlineTitle)” outline?", comment: "Confirmation: delete outline?")
	}
	
	static func deleteTagPrompt(tagName: String) -> String {
		return String(localized: "Are you sure you want to delete the “\(tagName)” tag?", comment: "Confirmation: delete tag?")
	}
	
	static func deleteTagsPrompt(tagCount: Int) -> String {
		return String(localized: "Are you sure you want to delete \(tagCount) tags?", comment: "Confirmation: delete tags?")
	}
	
	static func deleteOutlinePrompt(outlineName: String) -> String {
		return String(localized: "Are you sure you want to delete the “\(outlineName)” outline?", comment: "Confirmation: delete outline?")
	}
	
	static func deleteOutlinesPrompt(outlineCount: Int) -> String {
		return String(localized: "Are you sure you want to delete \(outlineCount) outlines?", comment: "Confirmation: delete outlines?")
	}
	
	static func documents(count: Int) -> String {
		return String(localized: "\(count) documents", comment: "Title: number of documents")
	}
	
	static func seeDocumentsInPrompt(documentContainerTitle: String) -> String {
		return String(localized: "See documents in “\(documentContainerTitle)”", comment: "Prompt: see documents in document container")
	}
	
	static func editDocumentPrompt(documentTitle: String) -> String {
		return String(localized: "Edit document “\(documentTitle)”", comment: "Prompt: edit document")
	}
	
	static func topicLevelLabel(level: Int) -> String {
		String(localized: "Topic Level \(level)", comment: "Font Label: The font for the given Topic Level")
	}
	
	static func noteLevelLabel(level: Int) -> String {
		String(localized: "Note Level \(level)", comment: "Font Label: The font for the given Note Level")
	}
	
}
