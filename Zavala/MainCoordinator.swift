//
//  MainCoordinator.swift
//  Zavala
//
//  Created by Maurice Parker on 3/17/21.
//

import UIKit
import Templeton
import SafariServices

protocol MainCoordinator: UIViewController {
	var currentDocumentContainer: DocumentContainer? { get }
	var editorViewController: EditorViewController? { get }
	var isGoBackwardOneUnavailable: Bool { get }
	var isGoForwardOneUnavailable: Bool { get }
	func goBackwardOne()
	func goForwardOne()
}

extension MainCoordinator {
	
	var currentOutline: Outline? {
		return editorViewController?.outline
	}
	
	var isOutlineFunctionsUnavailable: Bool {
		return editorViewController?.isOutlineFunctionsUnavailable ?? true
	}
	
	var isCollaborateUnavailable: Bool {
		return editorViewController?.isCollaborateUnavailable ?? true
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
	
	var isDuplicateRowsUnavailable: Bool {
		return editorViewController?.isDuplicateRowsUnavailable ?? true
	}
	
	var isCreateRowInsideUnavailable: Bool {
		return editorViewController?.isCreateRowInsideUnavailable ?? true
	}
	
	var isCreateRowOutsideUnavailable: Bool {
		return editorViewController?.isCreateRowOutsideUnavailable ?? true
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
	
	func duplicateRows() {
		editorViewController?.duplicateCurrentRows()
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
	
	func printDoc() {
		editorViewController?.printDoc()
	}
	
	func printList() {
		editorViewController?.printList()
	}
	
	func collaborate() {
		editorViewController?.collaborate()
	}
	
	func share() {
		editorViewController?.share()
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
	
	func openURL(_ urlString: String) {
		guard let url = URL(string: urlString) else { return }
		let vc = SFSafariViewController(url: url)
		vc.modalPresentationStyle = .pageSheet
		present(vc, animated: true)
	}

	func showSettings() {
		let settingsNavController = UIStoryboard.settings.instantiateInitialViewController() as! UINavigationController
		settingsNavController.modalPresentationStyle = .formSheet
		present(settingsNavController, animated: true)
	}
	
	func showGetInfo() {
		guard let outline = editorViewController?.outline else { return }
		showGetInfo(outline: outline)
	}
	
	func showGetInfo(outline: Outline) {
		if traitCollection.userInterfaceIdiom == .mac {
		
			let outlineGetInfoViewController = UIStoryboard.dialog.instantiateController(ofType: MacOutlineGetInfoViewController.self)
			outlineGetInfoViewController.preferredContentSize = CGSize(width: 400, height: 182)
			outlineGetInfoViewController.outline = outline
			present(outlineGetInfoViewController, animated: true)
		
		} else {
			
			let outlineGetInfoNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "OutlineGetInfoViewControllerNav") as! UINavigationController
			outlineGetInfoNavViewController.preferredContentSize = CGSize(width: 400, height: 250)
			outlineGetInfoNavViewController.modalPresentationStyle = .formSheet
			let outlineGetInfoViewController = outlineGetInfoNavViewController.topViewController as! OutlineGetInfoViewController
			outlineGetInfoViewController.outline = outline
			present(outlineGetInfoNavViewController, animated: true)
			
		}
	}

	func exportPDFDoc() {
		guard let outline = editorViewController?.outline else { return }
		exportPDFDocForOutline(outline)
	}
	
	func exportPDFList() {
		guard let outline = editorViewController?.outline else { return }
		exportPDFListForOutline(outline)
	}
	
	func exportMarkdownDoc() {
		guard let outline = editorViewController?.outline else { return }
		exportMarkdownDocForOutline(outline)
	}
	
	func exportMarkdownList() {
		guard let outline = editorViewController?.outline else { return }
		exportMarkdownListForOutline(outline)
	}
	
	func exportOPML() {
		guard let outline = editorViewController?.outline else { return }
		exportOPMLForOutline(outline)
	}
	
	func exportPDFDocForOutline(_ outline: Outline) {
		let printDoc = outline.printDoc()
		exportPDFForOutline(outline, attrString: printDoc)
	}
	
	func exportPDFListForOutline(_ outline: Outline) {
		let printList = outline.printList()
		exportPDFForOutline(outline, attrString: printList)
	}
	
	func exportPDFForOutline(_ outline: Outline, attrString: NSAttributedString) {
		let textView = UITextView()
		textView.attributedText = attrString
		let data = textView.generatePDF()
		
		export(data as Data, fileName: outline.fileName(withSuffix: "pdf"))
	}
	
	func exportMarkdownDocForOutline(_ outline: Outline) {
		let markdown = outline.markdownDoc()
		export(markdown, fileName: outline.fileName(withSuffix: "md"))
	}
	
	func exportMarkdownListForOutline(_ outline: Outline) {
		let markdown = outline.markdownList()
		export(markdown, fileName: outline.fileName(withSuffix: "md"))
	}
	
	func exportOPMLForOutline(_ outline: Outline) {
		let opml = outline.opml()
		export(opml, fileName: outline.fileName(withSuffix: "opml"))
	}
	
	func export(_ string: String, fileName: String) {
		guard let data = string.data(using: .utf8) else { return }
		export(data, fileName: fileName)
	}
	
	func export(_ data: Data, fileName: String) {
		let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
		
		do {
			try data.write(to: tempFile)
		} catch {
			self.presentError(title: "Export Error", message: error.localizedDescription)
		}
		
		let docPicker = UIDocumentPickerViewController(forExporting: [tempFile], asCopy: true)
		docPicker.modalPresentationStyle = .formSheet
		self.present(docPicker, animated: true)
	}
	
	func pinWasVisited(_ pin: Pin) {
		NotificationCenter.default.post(name: .PinWasVisited, object: pin, userInfo: nil)
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
	static let navigation = NSToolbarItem.Identifier("io.vincode.Zavala.navigation")
	static let goBackward = NSToolbarItem.Identifier("io.vincode.Zavala.goBackward")
	static let goForward = NSToolbarItem.Identifier("io.vincode.Zavala.goForward")
	static let insertImage = NSToolbarItem.Identifier("io.vincode.Zavala.insertImage")
	static let link = NSToolbarItem.Identifier("io.vincode.Zavala.link")
	static let boldface = NSToolbarItem.Identifier("io.vincode.Zavala.boldface")
	static let italic = NSToolbarItem.Identifier("io.vincode.Zavala.italic")
	static let expandAllInOutline = NSToolbarItem.Identifier("io.vincode.Zavala.expandAllInOutline")
	static let collapseAllInOutline = NSToolbarItem.Identifier("io.vincode.Zavala.collapseAllInOutline")
	static let moveRight = NSToolbarItem.Identifier("io.vincode.Zavala.moveRight")
	static let moveLeft = NSToolbarItem.Identifier("io.vincode.Zavala.moveLeft")
	static let moveUp = NSToolbarItem.Identifier("io.vincode.Zavala.moveUp")
	static let moveDown = NSToolbarItem.Identifier("io.vincode.Zavala.moveDown")
	static let printDoc = NSToolbarItem.Identifier("io.vincode.Zavala.printDoc")
	static let printList = NSToolbarItem.Identifier("io.vincode.Zavala.printList")
	static let collaborate = NSToolbarItem.Identifier("io.vincode.Zavala.share")
	static let share = NSToolbarItem.Identifier("io.vincode.Zavala.sendCopy")
	static let getInfo = NSToolbarItem.Identifier("io.vincode.Zavala.getInfo")
}

#endif
