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
	
	static let aboutZavala = String(localized: "label.text.about-zavala", comment: "Label: About Zavala")
	static let accountsControlLabel = String(localized: "label.text.accounts", comment: "Label: Accounts")
	static let acknowledgementsControlLabel = String(localized: "label.text.acknowledgements", comment: "Label: Acknowledgements")
	static let actualSizeControlLabel = String(localized: "button.text.actual-size", comment: "View Action: Actual Size")
	static let addControlLabel = String(localized: "button.text.add", comment: "Outline Action: Add")
	static let addNoteControlLabel = String(localized: "button.text.add-note", comment: "Outline Action: Add Note")
	static let addNoteLevelControlLabel = String(localized: "button.text.add-note-level", comment: "Action: Add Note Level")
	static let addNumberingLevelControlLabel = String(localized: "button.text.add-numbering-level", comment: "Action: Add Numbering Level")
	static let addRowAboveControlLabel = String(localized: "button.text.add-row-above", comment: "Outline Action: Add Row Above")
	static let addRowAfterControlLabel = String(localized: "button.text.add-row-after", comment: "Outline Action: Add Row After")
	static let addRowBelowControlLabel = String(localized: "button.text.add-row-below", comment: "Outline Action: Add Row Below")
	static let addRowControlLabel = String(localized: "button.text.add-row", comment: "Outline Action: Add Row")
	static let addRowInsideControlLabel = String(localized: "button.text.add-row-inside", comment: "Outline Action: Add Row Inside")
	static let addRowOutsideControlLabel = String(localized: "button.text.add-row-outside", comment: "Outline Action: Add Row Outside")
	static let addTagControlLabel = String(localized: "button.text.add-tag", comment: "Outline Action: Add Tag")
	static let addTopicLevelControlLabel = String(localized: "button.text.add-topic-level", comment: "Outline Action: Add Topic Level")
	static let appHelpControlLabel = String(localized: "label.text.zavala-help", comment: "Label: Zavala Help")
	static let appIconCreditLabel = String(localized: "label.text.app-icon-credit", comment: "App icon by [Brad Ellis](https://hachyderm.io/@bradellis)")
	static let appDevelopedByCreditLabel = String(localized: "label.text.app-developed-by", comment: "Developed by [Maurice C. Parker](https://vincode.io)")
	static let ascendingControlLabel = String(localized: "button.text.ascending", comment: "Sort Action: Ascending")
	static let automaticallyChangeLinkTitlesControlLabel = String(localized: "button.text.change-link-titles-automatically", comment: "Set Default Action: Change Link Titles Automatically")
	static let automaticallyCreateLinksControlLabel = String(localized: "button.text.create-links-automatically", comment: "Set Default Action: Create Links Automatically")
	static let automaticControlLabel = String(localized: "button.text.automatic-color-palette", comment: "Set App Color Palette Action: Automatic")

	static let backControlLabel = String(localized: "button.text.back", comment: "Navigation Action: Back")
	static let backlinksLabel = String(localized: "label.text.backlinks", comment: "Label: Backlinks")
	static let blueControlLabel = String(localized: "button.text.set-font-blue", comment: "Set Font Color Action: Blue")
	static let boldControlLabel = String(localized: "button.text.set-font-bold", comment: "Set Font Weight Action: Bold")
	static let brownControlLabel = String(localized: "button.text.set-font-brown", comment: "Set Font Color Action: Brown")
	static let bugTrackerControlLabel = String(localized: "label.text.bug-tracker", comment: "Label: Bug Tracker")
	
	static let cancelControlLabel = String(localized: "button.text.cancel", comment: "Action: Cancel")
	static let checkSpellingWhileTypingControlLabel = String(localized: "button.text.check-spelling-while-typing", comment: "Set Default Action: Check Spelling While Typing")
	
	static let collapseAllControlLabel = String(localized: "button.text.collapse-all", comment: "Outline Action: Collapse All")
	static let collapseAllInOutlineControlLabel = String(localized: "button.text.collapse-all-in-outline", comment: "Outline Action: Collapse All in Outline")
	static let collapseAllInRowControlLabel = String(localized: "button.text.collapse-all-in-row", comment: "Outline Action: Collapse All in Row")
	static let collapseControlLabel = String(localized: "button.text.collapse", comment: "Outline Action: Collapse")
	static let collapseParentRowControlLabel = String(localized: "outline.action.collapse-parent-row", comment: "Outline Action: Collapse Parent Row")
	static let collectionsControlLabel = String(localized: "label.title.collections", comment: "Label: Collections")
	static let colorPalettControlLabel = String(localized: "label.text.color-palette", comment: "Label: Color Palette")
	static let communityControlLabel = String(localized: "label.text.community-discussion", comment: "Label: Community Discussion")
	static let completeAccessibilityLabel = String(localized: "accessibility.text.complete", comment: "Accessibility Label: Complete")
	static let completeControlLabel = String(localized: "label.text.complete", comment: "Label: Complete")
	static let copyControlLabel = String(localized: "button.text.copy", comment: "Action: Copy")
	static let copyDocumentLinkControlLabel = String(localized: "button.text.copy-document-link", comment: "Document Action: Copy Document Link")
	static let copyDocumentLinksControlLabel = String(localized: "button.text.copy-document-links", comment: "Document Action: Copy Document Links")
	static let copyRowLinkControlLabel = String(localized: "button.text.copy-row-link", comment: "Document Action: Copy Row Link")
	static let correctSpellingAutomaticallyControlLabel = String(localized: "button.text.correct-spelling-automatically", comment: "Default Action: Correct Spelling Automatically")
	static let corruptedOutlineTitle = String(localized: "label.text.corrupted-outline", comment: "Label: Corrupted Outline")
	static let corruptedOutlineMessage = String(localized: "label.text.corrupted-outline-message", comment: "Alert Message: This outline appears to be corrupted. Would you like to fix it?")
	static let createdControlLabel = String(localized: "label.text.created", comment: "Label: Created")
	static let cutControlLabel = String(localized: "button.text.cut", comment: "Action: Cut")
	static let cyanControlLabel = String(localized: "button.text.set-font-cyan", comment: "Set Font Color Action: Cyan")

	static let darkControlLabel = String(localized: "button.text.set-appearance-dark", comment: "Set App Color Palette Action: Dark")
	static let deleteAlwaysControlLabel = String(localized: "button.text.always-delete-without-asking", comment: "Delete Action: Always Delete Without Asking")
	static let deleteCompletedRowsControlLabel = String(localized: "label.text.delete-completed", comment: "Label: Delete Completed Rows")
	static let deleteCompletedRowsTitle = String(localized: "label.text.delete-completed-rows", comment: "Label: Delete Completed Rows")
	static let deleteCompletedRowsMessage = String(localized: "label.text.delete-completed-rows-message", comment: "Alert Message: Are you sure you want to delete the completed rows?")
	static let deleteControlLabel = String(localized: "button.text.delete", comment: "Action: Delete")
	static let deleteOnceControlLabel = String(localized: "button.text.delete-once", comment: "Action: Delete Once")
	static let deleteOutlineControlLabel = String(localized: "button.text.delete-outline", comment: "Action: Delete Outline")
	static let deleteOutlineMessage = String(localized: "button.text.delete-outline-message", comment: "Alert Message: The outline will be deleted and unrecoverable.")
	static let deleteOutlinesMessage = String(localized: "button.text.delete-outlines-message", comment: "Alert Message: The outlines will be deleted and unrecoverable.")
	static let deleteNoteControlLabel = String(localized: "button.text.delete-note", comment: "Action: Delete Note")
	static let deleteRowControlLabel = String(localized: "button.text.delete-row", comment: "Action: Delete Row")
	static let deleteRowsControlLabel = String(localized: "button.text.delete-rows", comment: "Action: Delete Rows")
	static let deleteTagMessage = String(localized: "button.text.delete-tag-message.", comment: "Alert Message: Any child Tag associated with this Tag will also be deleted. No Outlines associated with this Tag will be deleted.")
	static let deleteTagsMessage = String(localized: "button.text.delete-tags-message.", comment: "Alert Message: Any child Tag associated with these Tags will also be deleted. No Outlines associated with these Tags will be deleted.")
	static let descendingControlLabel = String(localized: "button.text.descending", comment: "Action: Descending")
	static let disableAnimationsControlLabel = String(localized: "button.text.disable-animations", comment: "Action: Disable Animations")
	static let documentNotFoundTitle = String(localized: "label.text.document-not-found", comment: "Label: Document Not Found")
	static let documentNotFoundMessage = String(localized: "label.text.document-not-found-message", comment: "Alert Message: The requested document could not be found. It was most likely deleted and is no longer available.")
	static let doneControlLabel = String(localized: "label.text.done", comment: "Label: Done")
	static let duplicateControlLabel = String(localized: "button.text.duplicate", comment: "Action: Duplicate")
	static let duplicateRowControlLabel = String(localized: "button.text.duplicate-row", comment: "Action: Duplicate Row")
	static let duplicateRowsControlLabel = String(localized: "button.text.duplicate-rows", comment: "Action: Duplicate Rows")

	static let editorControlLabel = String(localized: "label.text.editor", comment: "Label: Editor")
	static let emailControlLabel = String(localized: "label.text.email", comment: "Label: Email")
	static let enableCloudKitControlLabel = String(localized: "button.text.enable-icloud", comment: "Label: Enable iCloud")
	static let enableOnMyDevice = String(localized: "button.text.enable-on-my-device", comment: "Label: Enable On My <Device>")
	static let errorAlertTitle = String(localized: "label.text.error", comment: "Label: Error")
	static let exportControlLabel = String(localized: "button.text.export", comment: "Action: Export")
	static let exportMarkdownDocEllipsisControlLabel = String(localized: "button.text.export-markdown-doc-with-ellipsis", comment: "Action: Export Markdown Doc…")
	static let exportMarkdownListEllipsisControlLabel = String(localized: "button.text.export-markdown-list-with-ellipsis", comment: "Action: Export Markdown List…")
	static let exportPDFDocEllipsisControlLabel = String(localized: "button.text.export-pdf-doc-with-ellipsis", comment: "Action: Export PDF Doc…")
	static let exportPDFListEllipsisControlLabel = String(localized: "button.text.export-pdf-list-with-ellipsis", comment: "Action: Export PDF List…")
	static let exportOPMLEllipsisControlLabel = String(localized: "button.text.export-opml-ellipsis", comment: "Action: Export OPML…")
	static let expandAllControlLabel = String(localized: "button.text.expand-all", comment: "Action: Expand All")
	static let expandAllInOutlineControlLabel = String(localized: "button.text.expand-all-in-outline", comment: "Action: Expand All in Outline")
	static let expandAllInRowControlLabel = String(localized: "button.text.expand-all-in-row", comment: "Action: Expand All in Row")
	static let expandControlLabel = String(localized: "button.text.expand", comment: "Action: Expand")
	
	static let feedbackControlLabel = String(localized: "button.text.provide-feedback", comment: "Action: Provide Feedback")
	static let filterControlLabel = String(localized: "button.text.filter", comment: "Action: Filter")
	static let filterCompletedControlLabel = String(localized: "label.text.filter-completed", comment: "Label: Filter Completed")
	static let filterNotesControlLabel = String(localized: "button.text.filter-notes", comment: "Action: Filter Notes")
	static let findControlLabel = String(localized: "button.text.find", comment: "Action: Find")
	static let findEllipsisControlLabel = String(localized: "button.text.find-with-ellipsis", comment: "Action: Find…")
	static let findNextControlLabel = String(localized: "button.text.find-next", comment: "Action: Find Next")
	static let findPreviousControlLabel = String(localized: "button.text.find-previous", comment: "Action: Find Previous")
	static let fixItControlLabel = String(localized: "button.text.fix-it", comment: "Action: Fix It")
	static let focusInControlLabel = String(localized: "button.text.focus-in", comment: "Action: Focus In")
	static let focusOutControlLabel = String(localized: "button.text.focus-out", comment: "Action: Focus Out")
	static let fontsControlLabel = String(localized: "label.text.fonts", comment: "Label: Fonts")
	static let formatControlLabel = String(localized: "label.text.format", comment: "Label: Format")
	static let forwardControlLabel = String(localized: "button.text.forward", comment: "Action: Forward")
	static let fullWidthControlLabel = String(localized: "button.text.full-width", comment: "Action: Full Width")

	static let getInfoControlLabel = String(localized: "button.text.get-info", comment: "Action: Get Info")
	static let generalControlLabel = String(localized: "button.text.general", comment: "Action: General")
	static let gitHubRepositoryControlLabel = String(localized: "label.text.github-repository", comment: "Label: GitHub Repository")
	static let goBackwardControlLabel = String(localized: "button.text.go-backward", comment: "Action: Go Backward")
	static let goForwardControlLabel = String(localized: "button.text.go-forward", comment: "Action: Go Forward")
	static let greenControlLabel = String(localized: "button.text.set-font-green", comment: "Set Font Color Action: Green")
	static let groupRowControlLabel = String(localized: "button.text.group-row", comment: "Action: Group Row")
	static let groupRowsControlLabel = String(localized: "button.text.group-rows", comment: "Action: Group Rows")

	static let helpControlLabel = String(localized: "label.text.help", comment: "Label: Help")
	static let hideKeyboardControlLabel = String(localized: "button.text.hide-keyboard", comment: "Action: Hide Keyboard")
	static let historyControlLabel = String(localized: "label.text.history", comment: "Label: History")
	
	static let imageControlLabel = String(localized: "label.text.image", comment: "Label: Image")
	static let importFailedTitle = String(localized: "label.text.import-failed", comment: "Error Message Title: Import Failed")
	static let importOPMLControlLabel = String(localized: "button.text.import-opml", comment: "Action: Import OPML")
	static let importOPMLEllipsisControlLabel = String(localized: "button.text.import-opml-with-ellipsis", comment: "Action: Import OPML…")
	static let indigoControlLabel = String(localized: "button.text.set-font-indigo", comment: "Set Font Color Action: Indigo")
	static let insertImageControlLabel = String(localized: "button.text.insert-image", comment: "Action: Insert Image")
	static let insertImageEllipsisControlLabel = String(localized: "button.text.insert-image-with-ellipsis", comment: "Label: Insert Image…")
	static let italicControlLabel = String(localized: "button.text.italic", comment: "Set Font Action: Italic")

	static let jumpToNoteControlLabel = String(localized: "button.text.jump-to-note", comment: "Action: Jump to Note")
	static let jumpToTopicControlLabel = String(localized: "button.text.jump-to-topic", comment: "Action: Jump to Topic")

	static let largeControlLabel = String(localized: "button.text.large", comment: "Action: Large")
	static let linkControlLabel = String(localized: "label.text.link", comment: "Label: Link")
	static let linkEllipsisControlLabel = String(localized: "label.text.link-with-ellipsis", comment: "Label: Link…")
	static let lightControlLabel = String(localized: "button.text.light", comment: "Set App Appearance Action: Light")

	static let manageSharingEllipsisControlLabel = String(localized: "label.text.manage-sharing-with-ellipsis", comment: "Label: Manage Sharing…")
	static let maxWidthControlLabel = String(localized: "label.text.max-width", comment: "Label: Max Width")
	static let mediumControlLabel = String(localized: "button.text.medium", comment: "Set Appearance Action: Medium")
	static let mintControlLabel = String(localized: "button.text.mint", comment: "Set Font Color Action: Mint")
	static let moreControlLabel = String(localized: "label.text.more", comment: "Label: More")
	static let moveControlLabel = String(localized: "label.text.move", comment: "Label: Move")
	static let moveRightControlLabel = String(localized: "button.text.move-right", comment: "Action: Move Right")
	static let moveLeftControlLabel = String(localized: "button.text.move-left", comment: "Action: Move Left")
	static let moveUpControlLabel = String(localized: "button.text.move-up", comment: "Action: Move Up")
	static let moveDownControlLabel = String(localized: "button.text.move-down", comment: "Action: Move Down")
	static let multipleSelectionsLabel = String(localized: "label.text.multiple-selections", comment: "Label: Multiple Selections")
	
	static let nameControlLabel = String(localized: "label.text.name", comment: "Label: Name")
	static let navigationControlLabel = String(localized: "label.text.navigation", comment: "Label: Navigation")
	static let newMainWindowControlLabel = String(localized: "label.text.new-main-window", comment: "Label: New Main Window")
	static let newOutlineControlLabel = String(localized: "button.text.new-outline", comment: "Action: New Outline")
	static let nextResultControlLabel = String(localized: "button.text.next-result", comment: "Action: Next Result")
	static let noneControlLabel = String(localized: "label.text.none", comment: "Label: None")
	static let normalControlLabel = String(localized: "button.text.normal", comment: "Label: Normal")
	static let noSelectionLabel = String(localized: "label.text.no-selection", comment: "Label: No Selection")
	static let noTitleLabel = String(localized: "label.text.no-title", comment: "Label: (No Title)")
	static let numberingStyleControlLabel = String(localized: "label.text.numbering-style", comment: "Label: Numbering Style")

	static let openQuicklyEllipsisControlLabel = String(localized: "button.text.open-quickly-with-ellipsis", comment: "Action: Open Quickly…")
	static let openQuicklySearchPlaceholder = String(localized: "button.text.open-quickly", comment: "Action: Open Quickly")
	static let outlineControlLabel = String(localized: "label.text.outline", comment: "Label: Outline")
	static let outlineOwnerControlLabel = String(localized: "label.text.outline-owner", comment: "Label: Outline Owner")
	static let outlineDefaultsControlLabel = String(localized: "label.text.outline-defaults", comment: "Label: Outline Defaults")
	static let opmlOwnerFieldNote = String(localized: "label.text.opml-ownership-description", comment: "Label: This information is included in OPML documents to attribute ownership.")
	static let orangeControlLabel = String(localized: "button.text.orange", comment: "Set Font Color Action: Orange")
	static let ownerControlLabel = String(localized: "label.text.owner", comment: "Label: Owner")

	static let pasteControlLabel = String(localized: "button.text.paste", comment: "Action: Paste")
	static let preferencesEllipsisControlLabel = String(localized: "label.text.preferences-with-ellipsis", comment: "Label: Preferences…")
	static let previousResultControlLabel = String(localized: "button.text.previous-result", comment: "Action: Previous Result")
	static let pinkControlLabel = String(localized: "button.text.pink", comment: "Set Font Color Action: Pink")
	static let primaryTextControlLabel = String(localized: "label.text.primary-text", comment: "Label: Primary Text")
	static let printControlLabel = String(localized: "button.text.print", comment: "Action: Print")
	static let printDocControlLabel = String(localized: "button.text.print-doc", comment: "Action: Print Doc")
	static let printDocEllipsisControlLabel = String(localized: "button.text.print-doc-with-ellipsis", comment: "Action: Print Doc…")
	static let printListControlLabel = String(localized: "button.text.print-list", comment: "Action: Print List")
	static let printListControlEllipsisLabel = String(localized: "button.text.print-list-with-ellipsis", comment: "Label: Print List…")
	static let privacyPolicyControlLabel = String(localized: "label.text.privacy-policy", comment: "Label: Privacy Policy")
	static let purpleControlLabel = String(localized: "button.text.purple", comment: "Set Font Color Action: Purple")

	static let quaternaryTextControlLabel = String(localized: "label.text.quaternary-text", comment: "Label: Quaternary Text")

	static let redControlLabel = String(localized: "button.text.red", comment: "Set Font Color Action: Red")
	static let readableControlLabel = String(localized: "label.text.readable", comment: "Label: Readable")
	static let redoControlLabel = String(localized: "button.text.redo", comment: "Action: Redo")
	static let releaseNotesControlLabel = String(localized: "label.text.release-notes", comment: "Label: Release Notes")
	static let removeControlLabel = String(localized: "button.text.remove", comment: "Action: Remove")
	static let removeICloudAccountTitle = String(localized: "label.text.remove-icloud-account", comment: "Label: Remove iCloud Account")
	static let removeICloudAccountMessage = String(localized: "label.text.remove-icloud-account-message",
												   comment: "Label: Are you sure you want to remove the iCloud Account? All documents in the iCloud Account will be removed from this computer.")
	
	static let referenceLabel = String(localized: "label.text.reference", comment: "Label: Reference: ")
	static let referencesLabel = String(localized: "label.text.references", comment: "Label: References: ")
	static let removeTagControlLabel = String(localized: "button.text.remove-tag", comment: "Action: Remove Tag")
	static let renameControlLabel = String(localized: "button.text.rename", comment: "Action: Rename")
	static let replaceControlLabel = String(localized: "button.text.replace", comment: "Action: Replace")
	static let restoreControlLabel = String(localized: "button.text.restore", comment: "Action: Restore")
	static let restoreDefaultsMessage = String(localized: "label.text.restore-defaults", comment: "Label: Restore Defaults")
	static let restoreDefaultsInformative = String(localized: "label.text.restore-defaults-message",
												   comment: "Label: Are you sure you want to restore the defaults? All your font customizations will be lost.")
	static let rowIndentControlLabel = String(localized: "label.text.row-indent", comment: "Label: Row Indent")
	static let rowSpacingControlLabel = String(localized: "label.text.row-spacing", comment: "Label: Row Spacing")

	static let saveControlLabel = String(localized: "button.text.save", comment: "Action: Save")
	static let scrollModeControlLabel = String(localized: "label.text.scroll-mode", comment: "Label: Scroll Mode")
	static let searchPlaceholder = String(localized: "label.text.search", comment: "Label: Search")
	static let secondaryTextControlLabel = String(localized: "label.text.secondary-text", comment: "Label: Secondary Text")
	static let selectControlLabel = String(localized: "button.text.select", comment: "Action: Select")
	static let settingsControlLabel = String(localized: "label.text.settings", comment: "Label: Settings")
	static let settingsEllipsisControlLabel = String(localized: "label.text.settings-with-ellipsis", comment: "Label: Settings…")
	static let shareControlLabel = String(localized: "button.text.share", comment: "Action: Share")
	static let shareEllipsisControlLabel = String(localized: "button.text.share-with-ellipsis", comment: "Label: Share…")
	static let smallControlLabel = String(localized: "button.text.small", comment: "Action: Small")
	static let sortDocumentsControlLabel = String(localized: "button.text.sort-documents", comment: "Action: Sort Documents")
	static let sortRowsControlLabel = String(localized: "button.text.sort-rows", comment: "Action: Sort Rows")
	static let splitRowControlLabel = String(localized: "button.text.split-row", comment: "Action: Split Row")
	static let statisticsControlLabel = String(localized: "label.text.statistics", comment: "Label: Statistics")
	static let syncControlLabel = String(localized: "button.text.sync", comment: "Label: Sync")
	
	static let tagsLabel = String(localized: "label.text.tags", comment: "Label: Tags")
	static let tagDataEntryPlaceholder = String(localized: "label.text.tag", comment: "Label: Tag")
	static let tealControlLabel = String(localized: "button.text.teal", comment: "Set Font Color Appearance: Teal")
	static let tertiaryTextControlLabel = String(localized: "label.text.tertiary-text", comment: "Label: Tertiary Text")
	static let titleLabel = String(localized: "label.text.title", comment: "Font Label: Title")
	static let togglerSidebarControlLabel = String(localized: "button.text.toggle-sidebar", comment: "Action: Toggle Sidebar")
	static let turnFilterOffControlLabel = String(localized: "button.text.turn-filter-off", comment: "Action: Turn Filter Off")
	static let turnFilterOnControlLabel = String(localized: "button.text.turn-filter-on", comment: "Label: Turn Filter On")
	static let typingControlLabel = String(localized: "label.text.typing", comment: "Label: Typing")
	static let typewriterCenterControlLabel = String(localized: "label.text.typewriter", comment: "Label: Typewriter")

	static let uncompleteControlLabel = String(localized: "button.text.uncomplete", comment: "Action: Uncomplete")
	static let undoControlLabel = String(localized: "button.text.undo", comment: "Action: Undo")
	static let undoMenuControlLabel = String(localized: "label.text.undo-menu", comment: "Label: Undo Menu")
	static let updatedControlLabel = String(localized: "label.text.updated", comment: "Label: Updated")
	static let urlControlLabel = String(localized: "label.text.url", comment: "Label: URL")
	static let useSelectionForFindControlLabel = String(localized: "button.text.use-selection-for-find", comment: "Action: Use Selection For Find")
	static let useMainWindowAsDefaultControlLabel = String(localized: "button.text.use-main-window-as-default", comment: "Action: Use Main Window as Default")
 
	static let websiteControlLabel = String(localized: "label.text.website", comment: "Label: Website")
	static let wideControlLabel = String(localized: "button.text.wide", comment: "Label: Wide")
	static let wordCountLabel = String(localized: "label.text.word-count", comment: "Label: Word Count")

	static let yellowControlLabel = String(localized: "button.text.yellow", comment: "Set Font Color Action: Yellow")

	static let zavalaHelpControlLabel = String(localized: "label.text.zavala-help", comment: "Label: Zavala Help")
	static let zoomInControlLabel = String(localized: "button.text.zoom-in", comment: "Action: Zoom In")
	static let zoomOutControlLabel = String(localized: "button.text.zoom-out", comment: "Action: Zoom Out")

	// MARK: Localizable Functions
	
	static func createdOnLabel(date: Date) -> String {
		let dateString = dateFormatter.string(from: date)
		let timeString = timeFormatter.string(from: date)
		return String(localized: "label.text.created-on-\(dateString)-at-\(timeString)", comment: "Label: Created on <Date> at <Time>")
	}
	
	static func updatedOnLabel(date: Date) -> String {
		let dateString = dateFormatter.string(from: date)
		let timeString = timeFormatter.string(from: date)
		return String(localized: "label.text.updated-on-\(dateString)-at-\(timeString)", comment: "Label: Updated on <Date> at <Time>")
	}
	
	static func deleteOutlinePrompt(outlineTitle: String) -> String {
		return String(localized: "label.text.delete-outline-confirmation-message-\(outlineTitle)", comment: "Alert Title: Are you sure you want to delete the “Outline Title” outline?")
	}
	
	static func deleteTagPrompt(tagName: String) -> String {
		return String(localized: "label.text.delete-tag-confirmation-message-\(tagName)", comment: "Alert Title: Are you sure you want to delete the “Tag Name” tag?")
	}
	
	static func deleteTagsPrompt(tagCount: Int) -> String {
		return String(localized: "label.text.delete-multiple-tags-confirmation-message-\(tagCount)", comment: "Alert Title: Are you sure you want to delete <Tag Count> tags?")
	}
	
	static func deleteOutlinesPrompt(outlineCount: Int) -> String {
		return String(localized: "label.text.delete-outlines-confirmation-message-\(outlineCount)", comment: "Label: Are you sure you want to delete <Outline Count> outlines?")
	}

	
	static func seeDocumentsInPrompt(documentContainerTitle: String) -> String {
		return String(localized: "label.text.see-documents-in-container-\(documentContainerTitle)", comment: "Label:  See documents in “<Document Container Title>”")
	}
	
	static func editDocumentPrompt(documentTitle: String) -> String {
		return String(localized: "label.text.edit-document-\(documentTitle)", comment: "Prompt:  Edit document “<Document Title>”")
	}
	
	static func numberingLevelLabel(level: Int) -> String {
		return String(localized: "label.text.numbering-level-\(level)", comment: "Label: Number Level <Numbering Level>")
	}
	
	static func topicLevelLabel(level: Int) -> String {
		return String(localized: "label.text.topic-level-\(level)", comment: "Label: Topic Level <Topic Level>")
	}
	
	static func noteLevelLabel(level: Int) -> String {
		return String(localized: "label.text.note-level-\(level)", comment: "Label: Note Level <Note Level>")
	}
	
	static func copyrightLabel() -> String {
		let year = String(Calendar.current.component(.year, from: Date()))
		return String(localized: "label.text.copyright-\(year)", comment: "Label: Copyright © Vincode, Inc. 2020-<Current Year>")
	}
	
}


extension LocalizedStringResource {
	
	static let invalidDestinationForOutline = LocalizedStringResource("label.text.intent-error-invalid-destination-outline-entity-id", comment: "Error text: The specified Destination is not a valid for the Outline specified by the Entity ID.")
	
	static let outlineNotBeingViewed = LocalizedStringResource("label.text.intent-error-outline-not-in-view", comment: "Error text: There isn't an Outline currently being viewed.")
	
	static let outlineNotFound = LocalizedStringResource("label.text.intent-error-outline-not-found", comment: "Error text: The requested Outline was not found.")
	
	static let noTagsSelected = LocalizedStringResource("label.text.intent-error-no-tags-selected", comment: "Error text: No Tags are currently selected.")
	
	static let rowContainerNotFound = LocalizedStringResource("label.text.intent-error-no-outline-or-row", comment: "Error text: Unable to find the Outline or Row specified by the Entity ID.")
	
	static let unavailableAccount = LocalizedStringResource("label.text.intent-error-account-not available", comment: "Error text: The specified Account isn't available to be used.")
	
	static let unexpectedError = LocalizedStringResource("label.text.intent-error-unexpected", comment: "An unexpected error occurred. Please try again.")
	
	
	
}
