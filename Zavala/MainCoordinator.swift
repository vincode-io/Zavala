//
//  MainCoordinator.swift
//  Zavala
//
//  Created by Maurice Parker on 3/17/21.
//

import UIKit

protocol MainCoordinator {
	var editorViewController: EditorViewController? { get }
	var isOutlineActionUnavailable: Bool { get }
	func exportJekyll()
	func exportMarkdown()
	func exportOPML()
	func openURL(_: String)
	func showSettings()
}

extension MainCoordinator {
	
	var isOutlineFunctionsUnavailable: Bool {
		return editorViewController?.isOutlineFunctionsUnavailable ?? true
	}
	
	var isShareUnavailable: Bool {
		return editorViewController?.isShareUnavailable ?? true
	}
	
	var isOutlineFiltered: Bool {
		return editorViewController?.isOutlineFiltered ?? false
	}
	
	var isOutlineNotesHidden: Bool {
		return editorViewController?.isOutlineNotesHidden ?? false
	}

	var isInsertRowUnavailable: Bool {
		return editorViewController?.isInsertRowUnavailable ?? true
	}
	
	var isCreateRowUnavailable: Bool {
		return editorViewController?.isCreateRowUnavailable ?? true
	}
	
	var isCreateRowInsideUnavailable: Bool {
		return editorViewController?.isCreateRowInsideUnavailable ?? true
	}
	
	var isCreateRowOutsideUnavailable: Bool {
		return editorViewController?.isCreateRowOutsideUnavailable ?? true
	}
	
	var isIndentRowsUnavailable: Bool {
		return editorViewController?.isIndentRowsUnavailable ?? true
	}

	var isOutdentRowsUnavailable: Bool {
		return editorViewController?.isOutdentRowsUnavailable ?? true
	}

	var isMoveRowsUpUnavailable: Bool {
		return editorViewController?.isMoveRowsUpUnavailable ?? true
	}

	var isMoveRowsDownUnavailable: Bool {
		return editorViewController?.isMoveRowsDownUnavailable ?? true
	}

	var isMoveRowsLeftUnavailable: Bool {
		return editorViewController?.isMoveRowsLeftUnavailable ?? true
	}

	var isMoveRowsRightUnavailable: Bool {
		return editorViewController?.isMoveRowsRightUnavailable ?? true
	}

	var isToggleRowCompleteUnavailable: Bool {
		return editorViewController?.isToggleRowCompleteUnavailable ?? true
	}
	
	var isCompleteRowsAvailable: Bool {
		return editorViewController?.isCompleteRowsAvailable ?? false
	}

	var isCreateRowNotesUnavailable: Bool {
		return editorViewController?.isCreateRowNotesUnavailable ?? true
	}
	
	var isDeleteRowNotesUnavailable: Bool {
		return editorViewController?.isDeleteRowNotesUnavailable ?? true
	}
	
	var isSplitRowUnavailable: Bool {
		return editorViewController?.isSplitRowUnavailable ?? true
	}
	
	var isFormatUnavailable: Bool {
		return editorViewController?.isFormatUnavailable ?? true
	}
	
	var isInsertImageUnavailable: Bool {
		return editorViewController?.isInsertImageUnavailable ?? true
	}
	
	var isLinkUnavailable: Bool {
		return editorViewController?.isLinkUnavailable ?? true
	}
	
	var isExpandAllInOutlineUnavailable: Bool {
		return editorViewController?.isExpandAllInOutlineUnavailable ?? true
	}

	var isCollapseAllInOutlineUnavailable: Bool {
		return editorViewController?.isCollapseAllInOutlineUnavailable ?? true
	}

	var isExpandAllUnavailable: Bool {
		return editorViewController?.isExpandAllUnavailable ?? true
	}

	var isCollapseAllUnavailable: Bool {
		return editorViewController?.isCollapseAllUnavailable ?? true
	}

	var isExpandUnavailable: Bool {
		return editorViewController?.isExpandUnavailable ?? true
	}

	var isCollapseUnavailable: Bool {
		return editorViewController?.isCollapseUnavailable ?? true
	}
	
	var isCollapseParentRowUnavailable: Bool {
		return editorViewController?.isCollapseParentRowUnavailable ?? true
	}
	
	var isDeleteCompletedRowsUnavailable: Bool {
		return editorViewController?.isDeleteCompletedRowsUnavailable ?? true
	}
	
	func toggleOutlineFilter() {
		editorViewController?.toggleOutlineFilter()
	}
	
	func toggleOutlineHideNotes() {
		editorViewController?.toggleOutlineHideNotes()
	}
	
	func insertRow() {
		editorViewController?.insertRow()
	}
	
	func createRow() {
		editorViewController?.createRow()
	}
	
	func createRowInside() {
		editorViewController?.createRowInside()
	}
	
	func createRowOutside() {
		editorViewController?.createRowOutside()
	}
	
	func indentRows() {
		editorViewController?.indentCurrentRows()
	}
	
	func outdentRows() {
		editorViewController?.outdentCurrentRows()
	}
	
	func moveRowsUp() {
		editorViewController?.moveCurrentRowsUp()
	}
	
	func moveRowsDown() {
		editorViewController?.moveCurrentRowsDown()
	}
	
	func moveRowsLeft() {
		editorViewController?.moveRowsLeft()
	}
	
	func moveRowsRight() {
		editorViewController?.moveRowsRight()
	}
	
	func toggleCompleteRows() {
		editorViewController?.toggleCompleteRows()
	}
	
	func createRowNotes() {
		editorViewController?.createRowNotes()
	}
	
	func deleteRowNotes() {
		editorViewController?.deleteRowNotes()
	}
	
	func splitRow() {
		editorViewController?.splitRow()
	}
	
	func outlineToggleBoldface() {
		editorViewController?.outlineToggleBoldface()
	}
	
	func outlineToggleItalics() {
		editorViewController?.outlineToggleItalics()
	}
	
	func insertImage() {
		editorViewController?.insertImage()
	}
	
	func link() {
		editorViewController?.link()
	}
	
	func copyDocumentLink() {
		let documentURL = editorViewController?.outline?.id.url
		UIPasteboard.general.url = documentURL
	}
	
	func expandAllInOutline() {
		editorViewController?.expandAllInOutline()
	}
	
	func collapseAllInOutline() {
		editorViewController?.collapseAllInOutline()
	}
	
	func expandAll() {
		editorViewController?.expandAll()
	}
	
	func collapseAll() {
		editorViewController?.collapseAll()
	}
	
	func expand() {
		editorViewController?.expand()
	}
	
	func collapse() {
		editorViewController?.collapse()
	}
	
	func collapseParentRow() {
		editorViewController?.collapseParentRow()
	}
	
	func deleteCompletedRows() {
		editorViewController?.deleteCompletedRows()
	}
	
	func printDocument() {
		editorViewController?.printOutline()
	}
	
	func share() {
		editorViewController?.share()
	}
	
	func sendCopy() {
		editorViewController?.sendCopy()
	}
	
	func beginInDocumentSearch() {
		editorViewController?.beginInDocumentSearch()
	}
	
	func useSelectionForSearch() {
		editorViewController?.useSelectionForSearch()
	}
	
	func nextInDocumentSearch() {
		editorViewController?.nextInDocumentSearch()
	}
	
	func previousInDocumentSearch() {
		editorViewController?.previousInDocumentSearch()
	}
	
	func outlineGetInfo() {
		editorViewController?.showOutlineGetInfo()
	}
	
}

#if targetEnvironment(macCatalyst)

extension NSToolbarItem.Identifier {
	static let sync = NSToolbarItem.Identifier("io.vincode.Zavala.refresh")
	static let importOPML = NSToolbarItem.Identifier("io.vincode.Zavala.importOPML")
	static let newOutline = NSToolbarItem.Identifier("io.vincode.Zavala.newOutline")
	static let toggleOutlineFilter = NSToolbarItem.Identifier("io.vincode.Zavala.toggleOutlineFilter")
	static let toggleOutlineNotesHidden = NSToolbarItem.Identifier("io.vincode.Zavala.toggleOutlineNotesHidden")
	static let delete = NSToolbarItem.Identifier("io.vincode.Zavala.delete")
	static let insertImage = NSToolbarItem.Identifier("io.vincode.Zavala.insertImage")
	static let link = NSToolbarItem.Identifier("io.vincode.Zavala.link")
	static let boldface = NSToolbarItem.Identifier("io.vincode.Zavala.boldface")
	static let italic = NSToolbarItem.Identifier("io.vincode.Zavala.italic")
	static let expandAllInOutline = NSToolbarItem.Identifier("io.vincode.Zavala.expandAllInOutline")
	static let collapseAllInOutline = NSToolbarItem.Identifier("io.vincode.Zavala.collapseAllInOutline")
	static let indent = NSToolbarItem.Identifier("io.vincode.Zavala.indent")
	static let outdent = NSToolbarItem.Identifier("io.vincode.Zavala.outdent")
	static let printDocument = NSToolbarItem.Identifier("io.vincode.Zavala.print")
	static let share = NSToolbarItem.Identifier("io.vincode.Zavala.share")
	static let sendCopy = NSToolbarItem.Identifier("io.vincode.Zavala.sendCopy")
	static let getInfo = NSToolbarItem.Identifier("io.vincode.Zavala.getInfo")
}

#endif
