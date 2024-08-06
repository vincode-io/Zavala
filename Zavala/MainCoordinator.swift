//
//  MainCoordinator.swift
//  Zavala
//
//  Created by Maurice Parker on 3/17/21.
//

import UIKit
import SwiftUI
import VinOutlineKit

extension Selector {
	static let sync = Selector(("sync:"))
	static let showGetInfo = Selector(("showGetInfo:"))
	static let share = Selector(("share:"))
	static let manageSharing = Selector(("manageSharing:"))
	static let exportPDFDocs = Selector(("exportPDFDocs:"))
	static let exportPDFLists = Selector(("exportPDFLists:"))
	static let exportMarkdownDocs = Selector(("exportMarkdownDocs:"))
	static let exportMarkdownLists = Selector(("exportMarkdownLists:"))
	static let exportOPMLs = Selector(("exportOPMLs:"))
	static let printDocs = Selector(("printDocs:"))
	static let printLists = Selector(("printLists:"))
}

@MainActor
protocol MainCoordinator: UIViewController, DocumentsActivityItemsConfigurationDelegate {
	var editorViewController: EditorViewController? { get }
	var selectedDocuments: [Document] { get }
}

extension MainCoordinator {
	
	var selectedOutlines: [Outline] {
		return selectedDocuments.compactMap { $0.outline }
	}
	
	var isOutlineFunctionsUnavailable: Bool {
		return editorViewController?.isOutlineFunctionsUnavailable ?? true
	}
	
	var isFocusInUnavailable: Bool {
		return editorViewController?.isFocusInUnavailable ?? true
	}
	
	var isFocusOutUnavailable: Bool {
		return editorViewController?.isFocusOutUnavailable ?? true
	}
	
	var isFilterOn: Bool {
		return editorViewController?.isFilterOn ?? false
	}
	
	var isCompletedFiltered: Bool {
		return editorViewController?.isCompletedFiltered ?? false
	}
	
	var isNotesFiltered: Bool {
		return editorViewController?.isNotesFiltered ?? false
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
	
	var isCopyRowLinkUnavailable: Bool {
		return editorViewController?.isCopyRowLinkUnavailable ?? true
	}
	
	var isInsertImageUnavailable: Bool {
		return editorViewController?.isInsertImageUnavailable ?? true
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
	
	var isManageSharingUnavailable: Bool {
		return !(selectedDocuments.count == 1 && selectedDocuments.first!.isCollaborating)
	}
	
	var isEditingTopic: Bool {
		return editorViewController?.isEditingTopic ?? false
	}
	
	var isEditingNotes: Bool {
		return editorViewController?.isEditingNote ?? false
	}

	func duplicateRows() {
		editorViewController?.duplicateCurrentRows()
	}
	
	func focusIn() {
		editorViewController?.focusIn()
	}
	
	func focusOut() {
		editorViewController?.focusOut()
	}
	
	func toggleFocus() {
		editorViewController?.toggleFocus()
	}
	
	func toggleFilterOn() {
		editorViewController?.toggleFilterOn()
	}
	
	func toggleCompletedFilter() {
		editorViewController?.toggleCompletedFilter()
	}
	
	func toggleNotesFilter() {
		editorViewController?.toggleNotesFilter()
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
		editorViewController?.moveCurrentRowsLeft()
	}
	
	func moveRowsRight() {
		editorViewController?.moveCurrentRowsRight()
	}
	
	func toggleCompleteRows() {
		editorViewController?.toggleCompleteRows()
	}
	
	func moveCursorToCurrentRowTopic() {
		editorViewController?.moveCursorToCurrentRowTopic()
	}
	
	func moveCursorToCurrentRowNote() {
		editorViewController?.moveCursorToCurrentRowNote()
	}
	
	func createRowNotes() {
		editorViewController?.createRowNotes()
	}
	
	func deleteRowNotes() {
		editorViewController?.deleteRowNotes()
	}
	
	func insertImage() {
		editorViewController?.insertImage()
	}
	
	func createOrDeleteNotes() {
		editorViewController?.createOrDeleteNotes()
	}
	
	func copyRowLink() {
		editorViewController?.copyRowLink()
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
	
	func deleteCurrentRows() {
		editorViewController?.deleteCurrentRows()
	}
	
	func deleteCompletedRows() {
		editorViewController?.deleteCompletedRows()
	}
	
	func showGetInfo() {
		guard let outline = editorViewController?.outline else { return }
		showGetInfo(outline: outline)
	}
	
	func showGetInfo(outline: Outline) {
		let getInfoView = GetInfoView(outline: outline)
		let hostingController = UIHostingController(rootView: getInfoView)
		hostingController.modalPresentationStyle = .formSheet

		if traitCollection.userInterfaceIdiom == .mac {
			hostingController.preferredContentSize = CGSize(width: 350, height: 520)
		} else {
			hostingController.preferredContentSize = CGSize(width: 425, height: 660)
		}

		present(hostingController, animated: true)
	}
	
	func exportPDFDocs() {
		exportPDFDocsForOutlines(selectedOutlines)
	}
	
	func exportPDFLists() {
		exportPDFListsForOutlines(selectedOutlines)
	}
	
	func exportMarkdownDocs() {
		exportMarkdownDocsForOutlines(selectedOutlines)
	}
	
	func exportMarkdownLists() {
		exportMarkdownListsForOutlines(selectedOutlines)
	}
	
	func exportOPMLs() {
		exportOPMLsForOutlines(selectedOutlines)
	}
	
	func exportPDFDocsForOutlines(_ outlines: [Outline]) {
        let pdfs = outlines.map { (outline: $0, attrString: $0.printDoc()) }
		exportPDFsForOutline(pdfs)
	}
	
	func exportPDFListsForOutlines(_ outlines: [Outline]) {
        let pdfs = outlines.map { (outline: $0, attrString: $0.printList()) }
		exportPDFsForOutline(pdfs)
	}
	
    func exportPDFsForOutline(_ pdfs: [(outline: Outline, attrString: NSAttributedString)]) {
        var exports = [(data: Data, filename: String)]()
        
        for pdf in pdfs {
            let textView = UITextView()
            textView.attributedText = pdf.attrString
            let data = textView.generatePDF()
			let filename = pdf.outline.filename(type: .pdf)
            exports.append((data: data, filename: filename))
        }
		
		export(exports)
	}
	
	func exportMarkdownDocsForOutlines(_ outlines: [Outline]) {
        export(outlines.compactMap {
            if let data = $0.markdownDoc().data(using: .utf8) {
				return (data: data, filename: $0.filename(type: .markdown))
            }
            return nil
        })
	}
	
	func exportMarkdownListsForOutlines(_ outlines: [Outline]) {
        export(outlines.compactMap {
            if let data = $0.markdownList().data(using: .utf8) {
                return (data: data, filename: $0.filename(type: .markdown))
            }
            return nil
        })
	}
	
	func exportOPMLsForOutlines(_ outlines: [Outline]) {
        export(outlines.compactMap {
            if let data = $0.opml().data(using: .utf8) {
				return (data: data, filename: $0.filename(type: .opml))
            }
            return nil
        })
	}
	
    func export(_ exports: [(data: Data, filename: String)]) {
        var tempFiles = [URL]()
        for export in exports {
            let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(export.filename)
            do {
                try export.data.write(to: tempFile)
            } catch {
                self.presentError(title: "Export Error", message: error.localizedDescription)
            }
            tempFiles.append(tempFile)
        }
		
		let docPicker = UIDocumentPickerViewController(forExporting: tempFiles, asCopy: true)
		docPicker.modalPresentationStyle = .formSheet
		self.present(docPicker, animated: true)
	}
	
	func printLists() {
		printListsForOutlines(selectedOutlines)
	}
	
	func printListsForOutlines(_ outlines: [Outline]) {
		var pdfs = [Data]()

		for outline in outlines {
			let textView = UITextView()
			textView.attributedText = outline.printList()
			pdfs.append(textView.generatePDF())
		}
		
		let title = ListFormatter.localizedString(byJoining: outlines.compactMap({ $0.title }).sorted())
		printPDFs(pdfs, title: title)
	}

	func printDocs() {
		printDocsForOutlines(selectedOutlines)
	}

	func printDocsForOutlines(_ outlines: [Outline]) {
		var pdfs = [Data]()

		for outline in outlines {
			let textView = UITextView()
			textView.attributedText = outline.printDoc()
			pdfs.append(textView.generatePDF())
		}
		
		let title = ListFormatter.localizedString(byJoining: outlines.compactMap({ $0.title }).sorted())
		printPDFs(pdfs, title: title)
	}

	func pinWasVisited(_ pin: Pin) {
		NotificationCenter.default.post(name: .PinWasVisited, object: pin, userInfo: nil)
	}
	
}

// MARK: Helpers

private extension MainCoordinator {
	
	func printPDFs(_ pdfs: [Data], title: String) {
		let pic = UIPrintInteractionController()
		
		let printInfo = UIPrintInfo(dictionary: nil)
		printInfo.outputType = .grayscale
		printInfo.jobName = title
		pic.printInfo = printInfo
		
		pic.printingItems = pdfs
		
		pic.present(animated: true)
	}
	
}

#if targetEnvironment(macCatalyst)

extension NSToolbarItem.Identifier {
	static let sync = NSToolbarItem.Identifier("io.vincode.Zavala.refresh")
	static let importOPML = NSToolbarItem.Identifier("io.vincode.Zavala.importOPML")
	static let newOutline = NSToolbarItem.Identifier("io.vincode.Zavala.newOutline")
	static let filter = NSToolbarItem.Identifier("io.vincode.Zavala.toggleOutlineFilter")
	static let focus = NSToolbarItem.Identifier("io.vincode.Zavala.focus")
	static let delete = NSToolbarItem.Identifier("io.vincode.Zavala.delete")
	static let navigation = NSToolbarItem.Identifier("io.vincode.Zavala.navigation")
	static let goBackward = NSToolbarItem.Identifier("io.vincode.Zavala.goBackward")
	static let goForward = NSToolbarItem.Identifier("io.vincode.Zavala.goForward")
	static let insertImage = NSToolbarItem.Identifier("io.vincode.Zavala.insertImage")
	static let link = NSToolbarItem.Identifier("io.vincode.Zavala.link")
	static let note = NSToolbarItem.Identifier("io.vincode.Zavala.note")
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
	static let share = NSToolbarItem.Identifier("io.vincode.Zavala.sendCopy")
	static let getInfo = NSToolbarItem.Identifier("io.vincode.Zavala.getInfo")
}

#endif
