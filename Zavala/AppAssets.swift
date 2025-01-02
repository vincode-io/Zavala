//
//  AppAssets.swift
//  Zavala
//
//  Created by Maurice Parker on 10/6/22.
//

import UIKit
import SwiftUI

extension Color {
	
	static let aboutBackgroundColor = Color("AboutBackgroundColor")
	
}

extension UIColor {
	
	static let accessoryColor = UIColor.tertiaryLabel
	static let barBackgroundColor = UIColor(named: "BarBackgroundColor")!
	static let fullScreenBackgroundColor = UIColor(named: "FullScreenBackgroundColor")!
	static let verticalBarColor = UIColor.quaternaryLabel
	static let brightenedDefaultAccentColor = UIColor.accentColor.brighten(by: 50)
	
}

extension UIImage {
	
	static let add = UIImage(systemName: "plus")!
	
	static let bold = UIImage(systemName: "bold")!
	static let bullet = UIImage(systemName: "circle.fill")!.applyingSymbolConfiguration(.init(pointSize: 4, weight: .heavy))!

	static let collaborating = UIImage(systemName: "person.crop.circle.badge.checkmark")!
	static let collapseAll = UIImage(systemName: "arrow.down.right.and.arrow.up.left")!
	static let completeRow = UIImage(systemName: "checkmark.square")!
	static let copy = UIImage(systemName: "doc.on.doc")!
	static let copyRowLink = UIImage(systemName: "link.circle")!
	static let createEntity = UIImage(systemName: "square.and.pencil")!
	static let cut = UIImage(systemName: "scissors")!

	static let delete = UIImage(systemName: "trash")!
	static let disclosure = UIImage(systemName: "chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 12, weight: .medium))!
	static let documentLink = UIImage(named: "DocumentLink")!.applyingSymbolConfiguration(.init(pointSize: 24, weight: .medium))!
	static let duplicate = UIImage(systemName: "plus.square.on.square")!

	static let ellipsis = UIImage(systemName: "ellipsis.circle")!
	static let expandAll = UIImage(systemName: "arrow.up.left.and.arrow.down.right")!
	static let export = UIImage(systemName: "arrow.up.doc")!

	static let favoriteSelected = UIImage(systemName: "star.fill")!
	static let favoriteUnselected = UIImage(systemName: "star")!
	static let filterActive = UIImage(systemName: "line.horizontal.3.decrease.circle.fill")!
	static let filterInactive = UIImage(systemName: "line.horizontal.3.decrease.circle")!
	static let find = UIImage(systemName: "magnifyingglass")!
	static let focusInactive = UIImage(systemName: "eye.circle")!
	static let focusActive = UIImage(systemName: "eye.circle.fill")!
	static let format = UIImage(systemName: "textformat")!

	static let getInfo = UIImage(systemName: "info.circle")!
	static let goBackward = UIImage(systemName: "chevron.left")!
	static let goForward = UIImage(systemName: "chevron.right")!
	static let groupRows = UIImage(systemName: "increase.indent")!

	static let importDocument = UIImage(systemName: "square.and.arrow.down")!
	static let italic = UIImage(systemName: "italic")!

	static let hideKeyboard = UIImage(systemName: "keyboard.chevron.compact.down")!
	static let hideNotesActive = UIImage(systemName: "doc.text.fill")!
	static let hideNotesInactive = UIImage(systemName: "doc.text")!

	static let insertImage = UIImage(systemName: "photo")!

	static let link = UIImage(systemName: "link")!

	static let moveDown = UIImage(systemName: "arrow.down.to.line.compact")!
	static let moveLeft = UIImage(systemName: "arrow.left.to.line.compact")!
	static let moveRight = UIImage(systemName: "arrow.right.to.line.compact")!
	static let moveUp = UIImage(systemName: "arrow.up.to.line.compact")!

	static let newline = UIImage(systemName: "return")!
	static let noteAdd = UIImage(systemName: "doc.text")!
	static let noteDelete = UIImage(systemName: "doc.text.fill")!
	static let noteFont = UIImage(systemName: "textformat.size.smaller")!

	static let outline = UIImage(named: "Outline")!

	static let paste = UIImage(systemName: "doc.on.clipboard")!
	#if targetEnvironment(macCatalyst)
	static let popupChevrons = UIImage(systemName: "chevron.up.chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 10, weight: .bold))!
	#else
	static let popupChevrons = UIImage(systemName: "chevron.up.chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 13, weight: .medium))!
	#endif
	static let printDoc = UIImage(systemName: "printer")!
	static let printList = UIImage(systemName: "printer.dotmatrix")!
	
	static let redo = UIImage(systemName: "arrow.uturn.forward")!
	static let rename = UIImage(systemName: "pencil")!
	static let restore = UIImage(systemName: "gobackward")!

	static let settings = UIImage(systemName: "gear")!
	static let share = UIImage(systemName: "square.and.arrow.up")!
	static let sort = UIImage(systemName: "arrow.up.arrow.down")!
	static let sync = UIImage(systemName: "arrow.clockwise")!

	static let topicFont = UIImage(systemName: "textformat.size.larger")!
	
	static let uncompleteRow = UIImage(systemName: "square")!
	static let undo = UIImage(systemName: "arrow.uturn.backward")!
	static let undoMenu = UIImage(systemName: "arrow.uturn.backward.circle.badge.ellipsis")!

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
	
	static let acknowledgementsURL = "https://github.com/vincode-io/Zavala/wiki/Acknowledgements"
	static let communityURL = "https://github.com/vincode-io/Zavala/discussions"
	static let feedbackURL = "mailto:mo@vincode.io"
	static let helpURL = "https://zavala.vincode.io/help/Zavala_Help.md/"
	static let privacyPolicyURL = "https://vincode.io/privacy-policy/"
	static let websiteURL = "https://zavala.vincode.io"
	
	// MARK: Localizable Variables
	
	static let aboutZavala = String(localized: "About Zavala", comment: "Control Label: About Zavala")
	static let accountsControlLabel = String(localized: "Accounts", comment: "Control Label: Accounts")
	static let acknowledgementsControlLabel = String(localized: "Acknowledgements", comment: "Control Label: Acknowledgements")
	static let actualSizeControlLabel = String(localized: "Actual Size", comment: "Control Label: Actual Size")
	static let addControlLabel = String(localized: "Add", comment: "Control Label: Add")
	static let addNoteControlLabel = String(localized: "Add Note", comment: "Control Label: Add Note")
	static let addNoteLevelControlLabel = String(localized: "Add Note Level", comment: "Control Label: Add Note Level")
	static let addNumberingLevelControlLabel = String(localized: "Add Numbering Level", comment: "Control Label: The menu option to add a new Numbering Level.")
	static let addRowAboveControlLabel = String(localized: "Add Row Above", comment: "Control Label: Add Row Above")
	static let addRowAfterControlLabel = String(localized: "Add Row After", comment: "Control Label: Add Row After")
	static let addRowBelowControlLabel = String(localized: "Add Row Below", comment: "Control Label: Add Row Below")
	static let addRowControlLabel = String(localized: "Add Row", comment: "Control Label: Add Row")
	static let addRowInsideControlLabel = String(localized: "Add Row Inside", comment: "Control Label: Add Row Inside")
	static let addRowOutsideControlLabel = String(localized: "Add Row Outside", comment: "Control Label: Add Row Outside")
	static let addTagControlLabel = String(localized: "Add Tag", comment: "Control Label: Add Tag.")
	static let addTopicLevelControlLabel = String(localized: "Add Topic Level", comment: "Control Label: The menu option to add a new Topic Level.")
	static let appHelpControlLabel = String(localized: "Zavala Help", comment: "Control Label: Zavala Help")
	static let ascendingControlLabel = String(localized: "Ascending", comment: "Control Label: Ascending")
	static let automaticallyChangeLinkTitlesControlLabel = String(localized: "Change Link Titles Automatically", comment: "Control Label: Auto Linking")
	static let automaticallyCreateLinksControlLabel = String(localized: "Create Links Automatically", comment: "Control Label: Automatically Create Links")
	static let automaticControlLabel = String(localized: "Automatic", comment: "Control Label: Automatic")

	static let backControlLabel = String(localized: "Back", comment: "Control Label: Back")
	static let backlinksLabel = String(localized: "Backlinks", comment: "Font Label: Backlinks")
	static let blueControlLabel = String(localized: "Blue", comment: "Control Label: Blue")
	static let boldControlLabel = String(localized: "Bold", comment: "Control Label: Bold")
	static let brownControlLabel = String(localized: "Brown", comment: "Control Label: Brown")
	static let bugTrackerControlLabel = String(localized: "Bug Tracker", comment: "Control Label: Bug Tracker")
	
	static let cancelControlLabel = String(localized: "Cancel", comment: "Control Label: Cancel the proposed action")
	static let checkSpellingWhileTypingControlLabel = String(localized: "Check Spelling While Typing", comment: "Control Label: Check Spelling While Typing")
	static let collaborateControlLabel = String(localized: "Collaborate", comment: "Control Label: Collaborate")
	static let collaborateEllipsisControlLabel = String(localized: "Collaborate…", comment: "Control Label: Collaborate…")
	static let collapseAllControlLabel = String(localized: "Collapse All", comment: "Control Label: Collapse All")
	static let collapseAllInOutlineControlLabel = String(localized: "Collapse All in Outline", comment: "Control Label: Collapse All in Outline")
	static let collapseAllInRowControlLabel = String(localized: "Collapse All in Row", comment: "Control Label: Collapse All in Row")
	static let collapseControlLabel = String(localized: "Collapse", comment: "Control Label: Collapse")
	static let collapseParentRowControlLabel = String(localized: "Collapse Parent Row", comment: "Control Label: Collapse Parent Row")
	static let colorPalettControlLabel = String(localized: "Color Palette", comment: "Control Label: Color Palette")
	static let communityControlLabel = String(localized: "Community Discussion", comment: "Control Label: Community Discussion")
	static let completeAccessibilityLabel = String(localized: "Complete", comment: "Accessibility Label: Complete")
	static let completeControlLabel = String(localized: "Complete", comment: "Control Label: Complete")
	static let copyControlLabel = String(localized: "Copy", comment: "Control Label: Copy")
	static let copyDocumentLinkControlLabel = String(localized: "Copy Document Link", comment: "Control Label: Copy Document Link")
	static let copyDocumentLinksControlLabel = String(localized: "Copy Document Links", comment: "Control Label: Copy Document Links")
	static let copyRowLinkControlLabel = String(localized: "Copy Row Link", comment: "Control Label: Copy Row Link")
	static let correctSpellingAutomaticallyControlLabel = String(localized: "Correct Spelling Automatically", comment: "Control Label: Correct Spelling Automatically")
	static let corruptedOutlineTitle = String(localized: "Corrupted Outline", comment: "Alert Title: Corrupted Outline")
	static let corruptedOutlineMessage = String(localized: "This outline appears to be corrupted. Would you like to fix it?", comment: "Alert Message: Corrupted Outline")
	static let createdControlLabel = String(localized: "Created", comment: "Control Label: Created")
	static let cutControlLabel = String(localized: "Cut", comment: "Control Label: Cut")
	static let cyanControlLabel = String(localized: "Cyan", comment: "Control Label: Cyan")

	static let darkControlLabel = String(localized: "Dark", comment: "Control Label: Dark")
	static let deleteAlwaysControlLabel = String(localized: "Always Delete Without Asking", comment: "Control Label: Always Delete Without Asking")
	static let deleteCompletedRowsControlLabel = String(localized: "Delete Completed", comment: "Control Label: Delete Completed Rows")
	static let deleteCompletedRowsTitle = String(localized: "Delete Completed Rows", comment: "Alert Title: Delete Completed Rows")
	static let deleteCompletedRowsMessage = String(localized: "Are you sure you want to delete the completed rows?", comment: "Alert Message: Delete Completed Rows")
	static let deleteControlLabel = String(localized: "Delete", comment: "Control Label: Delete an entity")
	static let deleteOnceControlLabel = String(localized: "Delete Once", comment: "Control Label: Delete Once")
	static let deleteOutlineControlLabel = String(localized: "Delete Outline", comment: "Control Label: Delete Outline")
	static let deleteOutlineMessage = String(localized: "The outline will be deleted and unrecoverable.", comment: "Alert Message: delete outline")
	static let deleteOutlinesMessage = String(localized: "The outlines will be deleted and unrecoverable.", comment: "Alert Message: delete outline")
	static let deleteNoteControlLabel = String(localized: "Delete Note", comment: "Control Label: Delete Note")
	static let deleteRowControlLabel = String(localized: "Delete Row", comment: "Control Label: Delete Row")
	static let deleteRowsControlLabel = String(localized: "Delete Rows", comment: "Control Label: Delete Rows")
	static let deleteTagMessage = String(localized: "Any child Tag associated with this Tag will also be deleted. No Outlines associated with this Tag will be deleted.", comment: "Alert Message: delete tag")
	static let deleteTagsMessage = String(localized: "Any child Tag associated with these Tags will also be deleted. No Outlines associated with these Tags will be deleted.", comment: "Alert Message: delete tags")
	static let descendingControlLabel = String(localized: "Descending", comment: "Control Label: Descending")
	static let disableAnimationsControlLabel = String(localized: "Disable Animations", comment: "Control Label: Disable Animations")
	static let documentNotFoundTitle = String(localized: "Document Not Found", comment: "Alert Title: Document Not Found")
	static let documentNotFoundMessage = String(localized: "The requested document could not be found. It was most likely deleted and is no longer available.", comment: "Alert Message: Document Not Found")
	static let doneControlLabel = String(localized: "Done", comment: "Control Label: Done")
	static let duplicateControlLabel = String(localized: "Duplicate", comment: "Control Label: Duplicate")
	static let duplicateRowControlLabel = String(localized: "Duplicate Row", comment: "Control Label: Duplicate Row")
	static let duplicateRowsControlLabel = String(localized: "Duplicate Rows", comment: "Control Label: Duplicate Rows")

	static let editorControlLabel = String(localized: "Editor", comment: "Control Label: Editor")
	static let emailControlLabel = String(localized: "Email", comment: "Control Label: Email")
	static let enableCloudKitControlLabel = String(localized: "Enable iCloud", comment: "Control Label: Enable iCloud")
	static let enableOnMyIPhoneControlLabel = String(localized: "Enable On My iPhone", comment: "Control Label: Enable On My iPhone")
	static let enableOnMyIPadControlLabel = String(localized: "Enable On My iPad", comment: "Control Label: Enable On My iPad")
	static let enableOnMyMacControlLabel = String(localized: "Enable On My Mac", comment: "Control Label: Enable On My Mac")
	static let errorAlertTitle = String(localized: "Error", comment: "Alert Title: Error")
	static let exportControlLabel = String(localized: "Export", comment: "Control Label: Export")
	static let exportMarkdownDocEllipsisControlLabel = String(localized: "Export Markdown Doc…", comment: "Control Label: Export Markdown Doc…")
	static let exportMarkdownListEllipsisControlLabel = String(localized: "Export Markdown List…", comment: "Control Label: Export Markdown List…")
	static let exportPDFDocEllipsisControlLabel = String(localized: "Export PDF Doc…", comment: "Control Label: Export PDF Doc…")
	static let exportPDFListEllipsisControlLabel = String(localized: "Export PDF List…", comment: "Control Label: Export PDF List…")
	static let exportOPMLEllipsisControlLabel = String(localized: "Export OPML…", comment: "Control Label: Export OPML…")
	static let expandAllControlLabel = String(localized: "Expand All", comment: "Control Label: Expand All")
	static let expandAllInOutlineControlLabel = String(localized: "Expand All in Outline", comment: "Control Label: Expand All in Outline")
	static let expandAllInRowControlLabel = String(localized: "Expand All in Row", comment: "Control Label: Expand All in Row")
	static let expandControlLabel = String(localized: "Expand", comment: "Control Label: Expand")
	
	static let feedbackControlLabel = String(localized: "Provide Feedback", comment: "Control Label: Provide Feedback")
	static let filterControlLabel = String(localized: "Filter", comment: "Control Label: Filter")
	static let filterCompletedControlLabel = String(localized: "Filter Completed", comment: "Control Label: Filter Completed")
	static let filterNotesControlLabel = String(localized: "Filter Notes", comment: "Control Label: Filter Notes")
	static let findControlLabel = String(localized: "Find", comment: "Control Label: Find")
	static let findEllipsisControlLabel = String(localized: "Find…", comment: "Control Label: Find…")
	static let findNextControlLabel = String(localized: "Find Next", comment: "Control Label: Find Next")
	static let findPreviousControlLabel = String(localized: "Find Previous", comment: "Control Label: Find Previous")
	static let fixItControlLabel = String(localized: "Fix It", comment: "Control Label: Fix It")
	static let focusInControlLabel = String(localized: "Focus In", comment: "Control Label: Focus In")
	static let focusOutControlLabel = String(localized: "Focus Out", comment: "Control Label: Focus Out")
	static let fontsControlLabel = String(localized: "Fonts", comment: "Control Label: Fonts")
	static let formatControlLabel = String(localized: "Format", comment: "Control Label: Format")
	static let forwardControlLabel = String(localized: "Forward", comment: "Control Label: Forward")
	static let fullWidthControlLabel = String(localized: "Full Width", comment: "Control Label: Full Width")

	static let getInfoControlLabel = String(localized: "Get Info", comment: "Control Label: Get Info")
	static let generalControlLabel = String(localized: "General", comment: "Control Label: General")
	static let gitHubRepositoryControlLabel = String(localized: "GitHub Repository", comment: "Control Label: GitHub Repository")
	static let goBackwardControlLabel = String(localized: "Go Backward", comment: "Control Label: Go Backward")
	static let goForwardControlLabel = String(localized: "Go Forward", comment: "Control Label: Go Forward")
	static let greenControlLabel = String(localized: "Green", comment: "Control Label: Green")
	static let groupRowControlLabel = String(localized: "Group Row", comment: "Control Label: Group Row")
	static let groupRowsControlLabel = String(localized: "Group Rows", comment: "Control Label: Group Rows")

	static let helpControlLabel = String(localized: "Help", comment: "Control Label: Help")
	static let hideKeyboardControlLabel = String(localized: "Hide Keyboard", comment: "Control Label: Hide Keyboard")
	static let historyControlLabel = String(localized: "History", comment: "Control Label: History")
	
	static let imageControlLabel = String(localized: "Image", comment: "Control Label: Image")
	static let importFailedTitle = String(localized: "Import Failed", comment: "Error Message Title: Import Failed")
	static let importOPMLControlLabel = String(localized: "Import OPML", comment: "Control Label: Import OPML")
	static let importOPMLEllipsisControlLabel = String(localized: "Import OPML…", comment: "Control Label: Import OPML…")
	static let indigoControlLabel = String(localized: "Indigo", comment: "Control Label: Indigo")
	static let insertImageControlLabel = String(localized: "Insert Image", comment: "Control Label: Insert Image")
	static let insertImageEllipsisControlLabel = String(localized: "Insert Image…", comment: "Control Label: Insert Image…")
	static let italicControlLabel = String(localized: "Italic", comment: "Control Label: Italic")

	static let jumpToNoteControlLabel = String(localized: "Jump to Note", comment: "Control Label: Jump to Note")
	static let jumpToTopicControlLabel = String(localized: "Jump to Topic", comment: "Control Label: Jump to Topic")

	static let largeControlLabel = String(localized: "Large", comment: "Control Label: Large")
	static let linkControlLabel = String(localized: "Link", comment: "Control Label: Link")
	static let linkEllipsisControlLabel = String(localized: "Link…", comment: "Control Label: Link…")
	static let lightControlLabel = String(localized: "Light", comment: "Control Label: Light")

	static let manageSharingEllipsisControlLabel = String(localized: "Manage Sharing…", comment: "Control Label: Manage Sharing…")
	static let maxWidthControlLabel = String(localized: "Max Width", comment: "Control Label: Max Width")
	static let mediumControlLabel = String(localized: "Medium", comment: "Control Label: Medium")
	static let mintControlLabel = String(localized: "Mint", comment: "Control Label: Mint")
	static let moreControlLabel = String(localized: "More", comment: "Control Label: More")
	static let moveControlLabel = String(localized: "Move", comment: "Control Label: Move")
	static let moveRightControlLabel = String(localized: "Move Right", comment: "Control Label: Move Right")
	static let moveLeftControlLabel = String(localized: "Move Left", comment: "Control Label: Move Left")
	static let moveUpControlLabel = String(localized: "Move Up", comment: "Control Label: Move Up")
	static let moveDownControlLabel = String(localized: "Move Down", comment: "Control Label: Move Down")
	static let multipleSelectionsLabel = String(localized: "Multiple Selections", comment: "Large Label: Multiple Selections")
	
	static let nameControlLabel = String(localized: "Name", comment: "Control Label: Name")
	static let navigationControlLabel = String(localized: "Navigation", comment: "Control Label: Navigation")
	static let newMainWindowControlLabel = String(localized: "New Main Window", comment: "Control Label: New Main Window")
	static let newOutlineControlLabel = String(localized: "New Outline", comment: "Control Label: New Outline")
	static let nextResultControlLabel = String(localized: "Next Result", comment: "Control Label: Next Result")
	static let noneControlLabel = String(localized: "None", comment: "Control Label: None")
	static let normalControlLabel = String(localized: "Normal", comment: "Control Label: Normal")
	static let noSelectionLabel = String(localized: "No Selection", comment: "Large Label: No Selection")
	static let noTitleLabel = String(localized: "(No Title)", comment: "Title Label: (No Title)")
	static let numberingStyleControlLabel = String(localized: "Numbering Style", comment: "Control Label: Numbering Style")

	static let openQuicklyEllipsisControlLabel = String(localized: "Open Quickly…", comment: "Control Label: Open Quickly…")
	static let openQuicklySearchPlaceholder = String(localized: "Open Quickly", comment: "Search Field Placeholder: Open Quickly")
	static let outlineControlLabel = String(localized: "Outline", comment: "Control Label: Outline")
	static let outlineOwnerControlLabel = String(localized: "Outline Owner", comment: "Control Label: Outline Owner")
	static let outlineDefaultsControlLabel = String(localized: "Outline Defaults", comment: "Control Label: Outline Defaults")
	static let opmlOwnerFieldNote = String(localized: "This information is included in OPML documents to attribute ownership.", comment: "Note: OPML Ownership.")
	static let orangeControlLabel = String(localized: "Orange", comment: "Control Label: Orange")
	static let ownerControlLabel = String(localized: "Owner", comment: "Control Label: Owner")

	static let pasteControlLabel = String(localized: "Paste", comment: "Control Label: Paste")
	static let preferencesEllipsisControlLabel = String(localized: "Preferences…", comment: "Control Label: Preferences…")
	static let previousResultControlLabel = String(localized: "Previous Result", comment: "Control Label: Previous Result")
	static let pinkControlLabel = String(localized: "Pink", comment: "Control Label: Pink")
	static let primaryTextControlLabel = String(localized: "Primary Text", comment: "Control Label: Primary Text")
	static let printControlLabel = String(localized: "Print", comment: "Control Label: Print")
	static let printDocControlLabel = String(localized: "Print Doc", comment: "Control Label: Print Doc")
	static let printDocEllipsisControlLabel = String(localized: "Print Doc…", comment: "Control Label: Print Doc…")
	static let printListControlLabel = String(localized: "Print List", comment: "Control Label: Print List")
	static let printListControlEllipsisLabel = String(localized: "Print List…", comment: "Control Label: Print List…")
	static let privacyPolicyControlLabel = String(localized: "Privacy Policy", comment: "Control Label: Privacy Policy")
	static let purpleControlLabel = String(localized: "Purple", comment: "Control Label: Purple")

	static let quaternaryTextControlLabel = String(localized: "Quaternary Text", comment: "Control Label: Quaternary Text")

	static let redControlLabel = String(localized: "Red", comment: "Control Label: Red")
	static let readableControlLabel = String(localized: "Readable", comment: "Control Label: Readable")
	static let redoControlLabel = String(localized: "Redo", comment: "Control Label: Redo")
	static let releaseNotesControlLabel = String(localized: "Release Notes", comment: "Control Label: Release Notes")
	static let removeControlLabel = String(localized: "Remove", comment: "Control Label: Remove")
	static let removeICloudAccountTitle = String(localized: "Remove iCloud Account", comment: "Alert Title: title for removing an iCloud Account")
	static let removeICloudAccountMessage = String(localized: "Are you sure you want to remove the iCloud Account? All documents in the iCloud Account will be removed from this computer.",
												   comment: "Alert Message: message for removing an iCloud Account")
	static let referenceLabel = String(localized: "Reference: ", comment: "Label: reference label for backlinks")
	static let referencesLabel = String(localized: "References: ", comment: "Label: references label for backlinks")
	static let removeTagControlLabel = String(localized: "Remove Tag", comment: "Control Label: Remove Tag")
	static let renameControlLabel = String(localized: "Rename", comment: "Control Label: Rename")
	static let replaceControlLabel = String(localized: "Replace", comment: "Control Label: Replace")
	static let restoreControlLabel = String(localized: "Restore", comment: "Control Label: Restore")
	static let restoreDefaultsMessage = String(localized: "Restore Defaults", comment: "Alert: message for restoring font defaults")
	static let restoreDefaultsInformative = String(localized: "Are you sure you want to restore the defaults? All your font customizations will be lost.",
												   comment: "Alert: information for restoring font defaults")
	static let rowIndentControlLabel = String(localized: "Row Indent", comment: "Control Label: Row Indent")
	static let rowSpacingControlLabel = String(localized: "Row Spacing", comment: "Control Label: Row Spacing")

	static let saveControlLabel = String(localized: "Save", comment: "Control Label: Save")
	static let scrollModeControlLabel = String(localized: "Scroll Mode", comment: "Control Label: Scroll Mode")
	static let searchPlaceholder = String(localized: "Search", comment: "Field Placeholder: Search")
	static let secondaryTextControlLabel = String(localized: "Secondary Text", comment: "Control Label: Secondary Text")
	static let selectControlLabel = String(localized: "Select", comment: "Control Label: Select")
	static let settingsControlLabel = String(localized: "Settings", comment: "Control Label: Settings")
	static let settingsEllipsisControlLabel = String(localized: "Settings…", comment: "Control Label: Settings…")
	static let shareControlLabel = String(localized: "Share", comment: "Control Label: Share")
	static let shareEllipsisControlLabel = String(localized: "Share…", comment: "Control Label: Share…")
	static let smallControlLabel = String(localized: "Small", comment: "Control Label: Small")
	static let sortDocumentsControlLabel = String(localized: "Sort Documents", comment: "Control Label: Sort Documents")
	static let sortRowsControlLabel = String(localized: "Sort Rows", comment: "Control Label: Sort Rows")
	static let splitRowControlLabel = String(localized: "Split Row", comment: "Control Label: Split Row")
	static let statisticsControlLabel = String(localized: "Statistics", comment: "Control Label: Statistics")
	static let syncControlLabel = String(localized: "Sync", comment: "Control Label: Sync")
	
	static let tagsLabel = String(localized: "Tags", comment: "Font Label: Tags")
	static let tagDataEntryPlaceholder = String(localized: "Tag", comment: "Data Entry Placeholder: Tag")
	static let tealControlLabel = String(localized: "Teal", comment: "Control Label: Teal")
	static let tertiaryTextControlLabel = String(localized: "Tertiary Text", comment: "Control Label: Tertiary Text")
	static let titleLabel = String(localized: "Title", comment: "Font Label: Title")
	static let titleControlLabel = String(localized: "Title", comment: "Control Label: Title")
	static let togglerSidebarControlLabel = String(localized: "Toggle Sidebar", comment: "Control Label: Toggle Sidebar")
	static let turnFilterOffControlLabel = String(localized: "Turn Filter Off", comment: "Control Label: Turn Filter Off")
	static let turnFilterOnControlLabel = String(localized: "Turn Filter On", comment: "Control Label: Turn Filter On")
	static let typingControlLabel = String(localized: "Typing", comment: "Control Label: Typing")
	static let typewriterCenterControlLabel = String(localized: "Typewriter", comment: "Control Label: Typewriter")

	static let uncompleteControlLabel = String(localized: "Uncomplete", comment: "Control Label: Uncomplete")
	static let undoControlLabel = String(localized: "Undo", comment: "Control Label: Undo")
	static let undoMenuControlLabel = String(localized: "Undo Menu", comment: "Control Label: Undo Menu")
	static let updatedControlLabel = String(localized: "Updated", comment: "Control Label: Updated")
	static let urlControlLabel = String(localized: "URL", comment: "Control Label: URL")
	static let useSelectionForFindControlLabel = String(localized: "Use Selection For Find", comment: "Control Label: Use Selection For Find")
	static let useMainWindowAsDefaultControlLabel = String(localized: "Use Main Window as Default", comment: "Control Label: Use Main Window as Default")
 
	static let websiteControlLabel = String(localized: "Website", comment: "Control Label: Website")
	static let wideControlLabel = String(localized: "Wide", comment: "Control Label: Wide")
	static let wordCountLabel = String(localized: "Word Count", comment: "Control Label: Word Count")

	static let yellowControlLabel = String(localized: "Yellow", comment: "Control Label: Yellow")

	static let zavalaHelpControlLabel = String(localized: "Zavala Help", comment: "Control Label: Zavala Help")
	static let zoomInControlLabel = String(localized: "Zoom In", comment: "Control Label: Zoom In")
	static let zoomOutControlLabel = String(localized: "Zoom Out", comment: "Control Label: Zoom Out")

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
	
	static func numberingLevelLabel(level: Int) -> String {
		return String(localized: "Numbering Level \(level)", comment: "Font Label: The font for the given Numbering Level")
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
