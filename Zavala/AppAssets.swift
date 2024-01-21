//
//  AppAssets.swift
//  Zavala
//
//  Created by Maurice Parker on 10/6/22.
//

import UIKit
import SwiftUI

extension Color {
	
	static var aboutBackgroundColor = Color("AboutBackgroundColor")
	
}

extension UIColor {
	
	static var accessoryColor = UIColor.tertiaryLabel
	static var barBackgroundColor = UIColor(named: "BarBackgroundColor")!
	static var fullScreenBackgroundColor: UIColor = UIColor(named: "FullScreenBackgroundColor")!
	static var textSelectColor: UIColor = UIColor(named: "TextSelectColor")!
	static var verticalBarColor: UIColor = .quaternaryLabel
	
}

extension UIImage {
	
	static var add = UIImage(systemName: "plus")!
	
	static var bold = UIImage(systemName: "bold")!
	static var bullet = UIImage(systemName: "circle.fill")!.applyingSymbolConfiguration(.init(pointSize: 4, weight: .heavy))!

	static var collaborate = UIImage(systemName: "person.crop.circle.badge.plus")!
	static var collaborating = UIImage(systemName: "person.crop.circle.badge.checkmark")!
	static var collapseAll = UIImage(systemName: "arrow.down.right.and.arrow.up.left")!
	static var completeRow = UIImage(systemName: "checkmark.square")!
	static var copy = UIImage(systemName: "doc.on.doc")!
	static var createEntity = UIImage(systemName: "square.and.pencil")!
	static var cut = UIImage(systemName: "scissors")!

	static var delete = UIImage(systemName: "trash")!
	static var disclosure = UIImage(systemName: "chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 12, weight: .medium))!
	static var documentLink = UIImage(named: "DocumentLink")!.applyingSymbolConfiguration(.init(pointSize: 24, weight: .medium))!
	static var duplicate = UIImage(systemName: "plus.square.on.square")!

	static var ellipsis = UIImage(systemName: "ellipsis.circle")!
	static var expandAll = UIImage(systemName: "arrow.up.left.and.arrow.down.right")!
	static var export = UIImage(systemName: "arrow.up.doc")!

	static var favoriteSelected = UIImage(systemName: "star.fill")!
	static var favoriteUnselected = UIImage(systemName: "star")!
	static var filterActive = UIImage(systemName: "line.horizontal.3.decrease.circle.fill")!
	static var filterInactive = UIImage(systemName: "line.horizontal.3.decrease.circle")!
	static var find = UIImage(systemName: "magnifyingglass")!
	static var focusInactive = UIImage(systemName: "eye.circle")!
	static var focusActive = UIImage(systemName: "eye.circle.fill")!
	static var format = UIImage(systemName: "textformat")!

	static var getInfo = UIImage(systemName: "info.circle")!
	static var goBackward = UIImage(systemName: "chevron.left")!
	static var goForward = UIImage(systemName: "chevron.right")!

	static var importDocument = UIImage(systemName: "square.and.arrow.down")!
	static var italic = UIImage(systemName: "italic")!

	static var hideKeyboard = UIImage(systemName: "keyboard.chevron.compact.down")!
	static var hideNotesActive = UIImage(systemName: "doc.text.fill")!
	static var hideNotesInactive = UIImage(systemName: "doc.text")!

	static var insertImage = UIImage(systemName: "photo")!

	static var link = UIImage(systemName: "link")!

	static var moveDown = UIImage(systemName: "arrow.down.to.line")!
	static var moveLeft = UIImage(systemName: "arrow.left.to.line")!
	static var moveRight = UIImage(systemName: "arrow.right.to.line")!
	static var moveUp = UIImage(systemName: "arrow.up.to.line")!

	static var newline = UIImage(systemName: "return")!
	static var noteAdd = UIImage(systemName: "doc.text")!
	static var noteDelete = UIImage(systemName: "doc.text.fill")!
	static var noteFont = UIImage(systemName: "textformat.size.smaller")!

	static var outline = UIImage(named: "Outline")!

	static var paste = UIImage(systemName: "doc.on.clipboard")!
	static var printDoc = UIImage(systemName: "printer")!
	static var printList = UIImage(systemName: "printer.dotmatrix")!
	
	static var redo = UIImage(systemName: "arrow.uturn.forward")!
	static var rename = UIImage(systemName: "pencil")!
	static var restore = UIImage(systemName: "gobackward")!

	static var share = UIImage(systemName: "square.and.arrow.up")!
	static var statelessCollaborate = UIImage(systemName: "person.crop.circle")!
	static var sync = UIImage(systemName: "arrow.clockwise")!

	static var topicFont = UIImage(systemName: "textformat.size.larger")!
	
	static var uncompleteRow = UIImage(systemName: "square")!
	static var undo = UIImage(systemName: "arrow.uturn.backward")!
	static var undoMenu = UIImage(systemName: "arrow.uturn.backward.circle.badge.ellipsis")!

}

extension String {
	
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
	static var communityURL = "https://github.com/vincode-io/Zavala/discussions"
	static var feedbackURL = "mailto:mo@vincode.io"
	static var helpURL = "https://zavala.vincode.io/help/Zavala_Help.md/"
	static var privacyPolicyURL = "https://vincode.io/privacy-policy/"
	static var websiteURL = "https://zavala.vincode.io"
	
	// MARK: Localizable Variables
	
	static var aboutZavala = String(localized: "About Zavala", comment: "Control Label: About Zavala")
	static var accountsControlLabel = String(localized: "Accounts", comment: "Control Label: Accounts")
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
	static var advancedControlLabel = String(localized: "Advanced", comment: "Control Label: Advanced")
	static var appearanceControlLabel = String(localized: "Appearance", comment: "Control Label: Appearance")
	static var appHelpControlLabel = String(localized: "Zavala Help", comment: "Control Label: Zavala Help")
	static var autoLinkingControlLabel = String(localized: "Automatically Change Link Titles", comment: "Control Label: Auto Linking")
	static var automaticControlLabel = String(localized: "Automatic", comment: "Control Label: Automatic")

	static var backControlLabel = String(localized: "Back", comment: "Control Label: Back")
	static var backlinksLabel = String(localized: "Backlinks", comment: "Font Label: Backlinks")
	static var boldControlLabel = String(localized: "Bold", comment: "Control Label: Bold")
	static var bugTrackerControlLabel = String(localized: "Bug Tracker", comment: "Control Label: Bug Tracker")
	
	static var cancelControlLabel = String(localized: "Cancel", comment: "Control Label: Cancel the proposed action")
	static var checkSpellingWhileTypingControlLabel = String(localized: "Check Spelling While Typing", comment: "Control Label: Check Spelling While Typing")
	static var collaborateControlLabel = String(localized: "Collaborate", comment: "Control Label: Collaborate")
	static var collaborateEllipsisControlLabel = String(localized: "Collaborate…", comment: "Control Label: Collaborate…")
	static var collapseAllControlLabel = String(localized: "Collapse All", comment: "Control Label: Collapse All")
	static var collapseAllInOutlineControlLabel = String(localized: "Collapse All in Outline", comment: "Control Label: Collapse All in Outline")
	static var collapseAllInRowControlLabel = String(localized: "Collapse All in Row", comment: "Control Label: Collapse All in Row")
	static var collapseControlLabel = String(localized: "Collapse", comment: "Control Label: Collapse")
	static var collapseParentRowControlLabel = String(localized: "Collapse Parent Row", comment: "Control Label: Collapse Parent Row")
	static var colorPalettControlLabel = String(localized: "Color Palette", comment: "Control Label: Color Palette")
	static var communityControlLabel = String(localized: "Community Discussion", comment: "Control Label: Community Discussion")
	static var completeAccessibilityLabel = String(localized: "Complete", comment: "Accessibility Label: Complete")
	static var completeControlLabel = String(localized: "Complete", comment: "Control Label: Complete")
	static var copyControlLabel = String(localized: "Copy", comment: "Control Label: Copy")
	static var copyDocumentLinkControlLabel = String(localized: "Copy Document Link", comment: "Control Label: Copy Document Link")
	static var copyDocumentLinksControlLabel = String(localized: "Copy Document Links", comment: "Control Label: Copy Document Links")
	static var correctSpellingAutomaticallyControlLabel = String(localized: "Correct Spelling Automatically", comment: "Control Label: Correct Spelling Automatically")
	static var corruptedOutlineTitle = String(localized: "Corrupted Outline", comment: "Alert Title: Corrupted Outline")
	static var corruptedOutlineMessage = String(localized: "This outline appears to be corrupted. Would you like to attempt to recover any lost rows?", comment: "Alert Message: Corrupted Outline")
	static var createdControlLabel = String(localized: "Created", comment: "Control Label: Created")
	static var cutControlLabel = String(localized: "Cut", comment: "Control Label: Cut")
	
	static var darkControlLabel = String(localized: "Dark", comment: "Control Label: Dark")
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
	static var disableEditorAnimationsControlLabel = String(localized: "Disable Editor Animations", comment: "Control Label: Disable Editor Animations")
	static var documentFindEllipsisControlLabel = String(localized: "Document Find…", comment: "Control Label: Document Find…")
	static var doneControlLabel = String(localized: "Done", comment: "Control Label: Done")
	static var duplicateControlLabel = String(localized: "Duplicate", comment: "Control Label: Duplicate")
	
	static var editorMaxWidthControlLabel = String(localized: "Editor Max Width", comment: "Control Label: Editor Max Width")
	static var emailControlLabel = String(localized: "Email", comment: "Control Label: Email")
	static var enableCloudKitControlLabel = String(localized: "Enable iCloud", comment: "Control Label: Enable iCloud")
	static var enableOnMyIPhoneControlLabel = String(localized: "Enable On My iPhone", comment: "Control Label: Enable On My iPhone")
	static var enableOnMyIPadControlLabel = String(localized: "Enable On My iPad", comment: "Control Label: Enable On My iPad")
	static var enableOnMyMacControlLabel = String(localized: "Enable On My Mac", comment: "Control Label: Enable On My Mac")
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
	
	static var feedbackControlLabel = String(localized: "Provide Feedback", comment: "Control Label: Provide Feedback")
	static var filterControlLabel = String(localized: "Filter", comment: "Control Label: Filter")
	static var filterCompletedControlLabel = String(localized: "Filter Completed", comment: "Control Label: Filter Completed")
	static var filterNotesControlLabel = String(localized: "Filter Notes", comment: "Control Label: Filter Notes")
	static var findControlLabel = String(localized: "Find", comment: "Control Label: Find")
	static var findEllipsisControlLabel = String(localized: "Find…", comment: "Control Label: Find…")
	static var findNextControlLabel = String(localized: "Find Next", comment: "Control Label: Find Next")
	static var findPreviousControlLabel = String(localized: "Find Previous", comment: "Control Label: Find Previous")
	static var focusInControlLabel = String(localized: "Focus In", comment: "Control Label: Focus In")
	static var focusOutControlLabel = String(localized: "Focus Out", comment: "Control Label: Focus Out")
	static var fontsControlLabel = String(localized: "Fonts", comment: "Control Label: Fonts")
	static var formatControlLabel = String(localized: "Format", comment: "Control Label: Format")
	static var forwardControlLabel = String(localized: "Forward", comment: "Control Label: Forward")
	static var fullWidthControlLabel = String(localized: "Full Width", comment: "Control Label: Full Width")

	static var getInfoControlLabel = String(localized: "Get Info", comment: "Control Label: Get Info")
	static var generalControlLabel = String(localized: "General", comment: "Control Label: General")
	static var gitHubRepositoryControlLabel = String(localized: "GitHub Repository", comment: "Control Label: GitHub Repository")
	static var goBackwardControlLabel = String(localized: "Go Backward", comment: "Control Label: Go Backward")
	static var goForwardControlLabel = String(localized: "Go Forward", comment: "Control Label: Go Forward")
	
	static var helpControlLabel = String(localized: "Help", comment: "Control Label: Help")
	static var hideKeyboardControlLabel = String(localized: "Hide Keyboard", comment: "Control Label: Hide Keyboard")
	static var historyControlLabel = String(localized: "History", comment: "Control Label: History")
	
	static var imageControlLabel = String(localized: "Image", comment: "Control Label: Image")
	static var importFailedTitle = String(localized: "Import Failed", comment: "Error Message Title: Import Failed")
	static var importOPMLControlLabel = String(localized: "Import OPML", comment: "Control Label: Import OPML")
	static var importOPMLEllipsisControlLabel = String(localized: "Import OPML…", comment: "Control Label: Import OPML…")
	static var insertImageControlLabel = String(localized: "Insert Image", comment: "Control Label: Insert Image")
	static var insertImageEllipsisControlLabel = String(localized: "Insert Image…", comment: "Control Label: Insert Image…")
	static var italicControlLabel = String(localized: "Italic", comment: "Control Label: Italic")
	
	static var largeControlLabel = String(localized: "Large", comment: "Control Label: Large")
	static var linkControlLabel = String(localized: "Link", comment: "Control Label: Link")
	static var linkEllipsisControlLabel = String(localized: "Link…", comment: "Control Label: Link…")
	static var lightControlLabel = String(localized: "Light", comment: "Control Label: Light")

	static var mediumControlLabel = String(localized: "Medium", comment: "Control Label: Medium")
	static var moreControlLabel = String(localized: "More", comment: "Control Label: More")
	static var moveControlLabel = String(localized: "Move", comment: "Control Label: Move")
	static var moveRightControlLabel = String(localized: "Move Right", comment: "Control Label: Move Right")
	static var moveLeftControlLabel = String(localized: "Move Left", comment: "Control Label: Move Left")
	static var moveUpControlLabel = String(localized: "Move Up", comment: "Control Label: Move Up")
	static var moveDownControlLabel = String(localized: "Move Down", comment: "Control Label: Move Down")
	static var multipleSelectionsLabel = String(localized: "Multiple Selections", comment: "Large Label: Multiple Selections")
	
	static var nameControlLabel = String(localized: "Name", comment: "Control Label: Name")
	static var navigationControlLabel = String(localized: "Navigation", comment: "Control Label: Navigation")
	static var newMainWindowControlLabel = String(localized: "New Main Window", comment: "Control Label: New Main Window")
	static var newOutlineControlLabel = String(localized: "New New Outline", comment: "Control Label: New New Outline")
	static var nextResultControlLabel = String(localized: "Next Result", comment: "Control Label: Next Result")
	static var noneControlLabel = String(localized: "None", comment: "Control Label: None")
	static var normalControlLabel = String(localized: "Normal", comment: "Control Label: Normal")
	static var noSelectionLabel = String(localized: "No Selection", comment: "Large Label: No Selection")
	static var noTitleLabel = String(localized: "(No Title)", comment: "Control Label: (No Title)")
	
	static var openQuicklyEllipsisControlLabel = String(localized: "Open Quickly…", comment: "Control Label: Open Quickly…")
	static var openQuicklySearchPlaceholder = String(localized: "Open Quickly", comment: "Search Field Placeholder: Open Quickly")
	static var outlineControlLabel = String(localized: "Outline", comment: "Control Label: Outline")
	static var outlineOwnerControlLabel = String(localized: "Outline Owner", comment: "Control Label: Outline Owner")
	static var outlineDefaultsControlLabel = String(localized: "Outline Defaults", comment: "Control Label: Outline Defaults")
	static var opmlOwnerFieldNote = String(localized: "This information is included in OPML documents to attribute ownership.", comment: "Note: OPML Ownership.")
	static var ownerControlLabel = String(localized: "Owner", comment: "Control Label: Owner")

	static var pasteControlLabel = String(localized: "Paste", comment: "Control Label: Paste")
	static var preferencesEllipsisControlLabel = String(localized: "Preferences…", comment: "Control Label: Preferences…")
	static var previousResultControlLabel = String(localized: "Previous Result", comment: "Control Label: Previous Result")
	static var printControlLabel = String(localized: "Print", comment: "Control Label: Print")
	static var printDocControlLabel = String(localized: "Print Doc", comment: "Control Label: Print Doc")
	static var printDocEllipsisControlLabel = String(localized: "Print Doc…", comment: "Control Label: Print Doc…")
	static var printListControlLabel = String(localized: "Print List", comment: "Control Label: Print List")
	static var printListControlEllipsisLabel = String(localized: "Print List…", comment: "Control Label: Print List…")
	static var privacyPolicyControlLabel = String(localized: "Privacy Policy", comment: "Control Label: Privacy Policy")
	
	static var readableControlLabel = String(localized: "Readable", comment: "Control Label: Readable")
	static var recoverControlLabel = String(localized: "Recover", comment: "Control Label: Recover")
	static var redoControlLabel = String(localized: "Redo", comment: "Control Label: Redo")
	static var releaseNotesControlLabel = String(localized: "Release Notes", comment: "Control Label: Release Notes")
	static var removeControlLabel = String(localized: "Remove", comment: "Control Label: Remove")
	static var removeICloudAccountTitle = String(localized: "Remove iCloud Account", comment: "Alert Title: title for removing an iCloud Account")
	static var removeICloudAccountMessage = String(localized: "Are you sure you want to remove the iCloud Account? All documents in the iCloud Account will be removed from this computer.",
												   comment: "Alert Message: message for removing an iCloud Account")
	static var removeTagControlLabel = String(localized: "Remove Tag", comment: "Control Label: Remove Tag")
	static var renameControlLabel = String(localized: "Rename", comment: "Control Label: Rename")
	static var referenceLabel = String(localized: "Reference: ", comment: "Label: reference label for backlinks")
	static var referencesLabel = String(localized: "References: ", comment: "Label: references label for backlinks")
	static var restoreControlLabel = String(localized: "Restore", comment: "Control Label: Restore")
	static var restoreDefaultsMessage = String(localized: "Restore Defaults", comment: "Alert: message for restoring font defaults")
	static var restoreDefaultsInformative = String(localized: "Are you sure you want to restore the defaults? All your font customizations will be lost.",
												   comment: "Alert: information for restoring font defaults")
	static var rowIndentControlLabel = String(localized: "Row Indent", comment: "Control Label: Row Indent")
	static var rowSpacingControlLabel = String(localized: "Row Spacing", comment: "Control Label: Row Spacing")

	static var saveControlLabel = String(localized: "Save", comment: "Control Label: Save")
	static var searchPlaceholder = String(localized: "Search", comment: "Field Placeholder: Search")
	static var secondaryColorControlLabel = String(localized: "Secondary Color", comment: "Control Label: Secondary Color")
	static var selectControlLabel = String(localized: "Select", comment: "Control Label: Select")
	static var settingsControlLabel = String(localized: "Settings", comment: "Control Label: Settings")
	static var settingsEllipsisControlLabel = String(localized: "Settings…", comment: "Control Label: Settings…")
	static var shareControlLabel = String(localized: "Share", comment: "Control Label: Share")
	static var shareEllipsisControlLabel = String(localized: "Share…", comment: "Control Label: Share…")
	static var smallControlLabel = String(localized: "Small", comment: "Control Label: Small")
	static var splitRowControlLabel = String(localized: "Split Row", comment: "Control Label: Split Row")
	static var statisticsControlLabel = String(localized: "Statistics", comment: "Control Label: Statistics")
	static var syncControlLabel = String(localized: "Sync", comment: "Control Label: Sync")
	
	static var tagsLabel = String(localized: "Tags", comment: "Font Label: Tags")
	static var tagDataEntryPlaceholder = String(localized: "Tag", comment: "Data Entry Placeholder: Tag")
	static var titleLabel = String(localized: "Title", comment: "Font Label: Title")
	static var togglerSidebarControlLabel = String(localized: "Toggle Sidebar", comment: "Control Label: Toggle Sidebar")
	static var turnFilterOffControlLabel = String(localized: "Turn Filter Off", comment: "Control Label: Turn Filter Off")
	static var turnFilterOnControlLabel = String(localized: "Turn Filter On", comment: "Control Label: Turn Filter On")
	static var typingControlLabel = String(localized: "Typing", comment: "Control Label: Typing")
	
	static var uncompleteControlLabel = String(localized: "Uncomplete", comment: "Control Label: Uncomplete")
	static var undoControlLabel = String(localized: "Undo", comment: "Control Label: Undo")
	static var undoMenuControlLabel = String(localized: "Undo Menu", comment: "Control Label: Undo Menu")
	static var updatedControlLabel = String(localized: "Updated", comment: "Control Label: Updated")
	static var urlControlLabel = String(localized: "URL", comment: "Control Label: URL")
	static var useSelectionForFindControlLabel = String(localized: "Use Selection For Find", comment: "Control Label: Use Selection For Find")
	static var useMainWindowAsDefaultControlLabel = String(localized: "Use Main Window as Default", comment: "Control Label: Use Main Window as Default")
 
	static var websiteControlLabel = String(localized: "Website", comment: "Control Label: Website")
	static var wideControlLabel = String(localized: "Wide", comment: "Control Label: Wide")
	static var wordCountLabel = String(localized: "Word Count", comment: "Control Label: Word Count")

	static var zavalaHelpControlLabel = String(localized: "Zavala Help", comment: "Control Label: Zavala Help")
	
	// MARK: Localizable Functions
	
	static func createdOnLabel(date: Date) -> String {
		let dateString = dateFormatter.string(from: date)
		let timeString = timeFormatter.string(from: date)
		return String(localized: "\(dateString) at \(timeString)", comment: "Timestame Label: Created")
	}
	
	static func updatedOnLabel(date: Date) -> String {
		let dateString = dateFormatter.string(from: date)
		let timeString = timeFormatter.string(from: date)
		return String(localized: "\(dateString) at \(timeString)", comment: "Timestame Label: Updated")
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
		return String(localized: "Topic Level \(level)", comment: "Font Label: The font for the given Topic Level")
	}
	
	static func noteLevelLabel(level: Int) -> String {
		return String(localized: "Note Level \(level)", comment: "Font Label: The font for the given Note Level")
	}
	
	static func copyrightLabel() -> String {
		let year = String(Calendar.current.component(.year, from: Date()))
		return String(localized: "Copyright © Vincode, Inc. 2020-\(year)", comment: "About Box copyright information")
	}
	
}
