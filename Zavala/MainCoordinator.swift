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
	static let showGetInfo = #selector(MainCoordinatorResponder.showGetInfo(_:))
	static let share = #selector(MainCoordinatorResponder.share(_:))
	static let manageSharing = #selector(MainCoordinatorResponder.manageSharing(_:))
	static let exportPDFDocs = #selector(MainCoordinatorResponder.exportPDFDocs(_:))
	static let exportPDFLists = #selector(MainCoordinatorResponder.exportPDFLists(_:))
	static let exportMarkdownDocs = #selector(MainCoordinatorResponder.exportMarkdownDocs(_:))
	static let exportMarkdownLists = #selector(MainCoordinatorResponder.exportMarkdownLists(_:))
	static let exportOPMLs = #selector(MainCoordinatorResponder.exportOPMLs(_:))
	static let printDocs = #selector(MainCoordinatorResponder.printDocs(_:))
	static let printLists = #selector(MainCoordinatorResponder.printLists(_:))
	static let copyDocumentLink = #selector(MainCoordinatorResponder.copyDocumentLink(_:))
}

@MainActor
@objc public protocol MainCoordinatorResponder {
	@objc func showGetInfo(_ sender: Any?)
	@objc func share(_ sender: Any?)
	@objc func manageSharing(_ sender: Any?)
	@objc func exportPDFDocs(_ sender: Any?)
	@objc func exportPDFLists(_ sender: Any?)
	@objc func exportMarkdownDocs(_ sender: Any?)
	@objc func exportMarkdownLists(_ sender: Any?)
	@objc func exportOPMLs(_ sender: Any?)
	@objc func printDocs(_ sender: Any?)
	@objc func printLists(_ sender: Any?)
	@objc func copyDocumentLink(_ sender: Any?)
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
	
	var isManageSharingUnavailable: Bool {
		return !(selectedDocuments.count == 1 && selectedDocuments.first!.isCollaborating)
	}
	
	var isEditingTopic: Bool {
		return editorViewController?.isEditingTopic ?? false
	}
	
	var isEditingNotes: Bool {
		return editorViewController?.isEditingNote ?? false
	}

	func copyDocumentLink() {
		UIPasteboard.general.url = selectedDocuments.first?.id.url
	}
	
	func showSettings() {
		#if targetEnvironment(macCatalyst)
		let userActivity = NSUserActivity(activityType: NSUserActivity.ActivityType.showSettings)
		let scene = UIApplication.shared.connectedScenes.first(where: { $0.delegate is SettingsSceneDelegate})
		UIApplication.shared.requestSceneSessionActivation(scene?.session, userActivity: userActivity, options: nil, errorHandler: nil)
		#else
		let settingsViewController = UIHostingController(rootView: SettingsView())
		settingsViewController.modalPresentationStyle = .formSheet
		present(settingsViewController, animated: true)
		#endif
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
			hostingController.preferredContentSize = CGSize(width: 350, height: 570)
		} else {
			hostingController.preferredContentSize = CGSize(width: 425, height: 705)
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
	static let sortDocuments = NSToolbarItem.Identifier("io.vincode.Zavala.sortDocuments")
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
