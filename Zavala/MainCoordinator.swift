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
	static let deleteOutline = #selector(MainCoordinatorResponder.deleteOutline(_:))
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
	static let lockOutline = #selector(MainCoordinatorResponder.lockOutline(_:))
	static let removeLock = #selector(MainCoordinatorResponder.removeLock(_:))
	static let lockNow = #selector(MainCoordinatorResponder.lockNow(_:))
}

@MainActor
@objc public protocol MainCoordinatorResponder {
	@objc func showGetInfo(_ sender: Any?)
	@objc func deleteOutline(_ sender: Any?)
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
	@objc func lockOutline(_ sender: Any?)
	@objc func removeLock(_ sender: Any?)
	@objc func lockNow(_ sender: Any?)
}

@MainActor
protocol MainCoordinator: UIViewController, DocumentsActivityItemsConfigurationDelegate {
	var activityManager: ActivityManager { get }
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

	var isLinkToggledOn: Bool {
		return editorViewController?.isLinkToggledOn ?? false
	}

	var isCodeInlineToggledOn: Bool {
		return editorViewController?.isCodeInlineToggledOn ?? false
	}

	var isHighlightToggledOn: Bool {
		return editorViewController?.isHighlightToggledOn ?? false
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

	func editShortcutsMenu() {
		#if targetEnvironment(macCatalyst)
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.editShortcutsMenu)
		let scene = UIApplication.shared.connectedScenes.first(where: { $0.delegate is EditShortcutsMenuSceneDelegate })
		UIApplication.shared.requestSceneSessionActivation(scene?.session, userActivity: activity, options: nil, errorHandler: nil)
		#else
		let hostingController = UIHostingController(rootView: EditShortcutsMenuView())
		hostingController.modalPresentationStyle = .formSheet
		present(hostingController, animated: true)
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
		var exports = [(data: Data, filename: String)]()
		var imageDirectoryURLs = [URL]()
		
		for outline in outlines {
			if let data = outline.markdownDoc(useSidecar: true).data(using: .utf8) {
				exports.append((data: data, filename: outline.filename(type: .markdown)))
				imageDirectoryURLs.append(contentsOf: writeImageDirectory(for: outline))
			}
		}
		
		export(exports, additionalURLs: imageDirectoryURLs)
	}
	
	func exportMarkdownListsForOutlines(_ outlines: [Outline]) {
		var exports = [(data: Data, filename: String)]()
		var imageDirectoryURLs = [URL]()
		
		for outline in outlines {
			if let data = outline.markdownList(useSidecar: true).data(using: .utf8) {
				exports.append((data: data, filename: outline.filename(type: .markdown)))
				imageDirectoryURLs.append(contentsOf: writeImageDirectory(for: outline))
			}
		}
		
		export(exports, additionalURLs: imageDirectoryURLs)
	}
	
	func exportOPMLsForOutlines(_ outlines: [Outline]) {
		var exports = [(data: Data, filename: String)]()
		var imageDirectoryURLs = [URL]()
		
		for outline in outlines {
			if let data = outline.opml(useSidecar: true).data(using: .utf8) {
				exports.append((data: data, filename: outline.filename(type: .opml)))
				imageDirectoryURLs.append(contentsOf: writeImageDirectory(for: outline))
			}
		}
		
		export(exports, additionalURLs: imageDirectoryURLs)
	}
	
    func export(_ exports: [(data: Data, filename: String)], additionalURLs: [URL] = []) {
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
		
		tempFiles.append(contentsOf: additionalURLs)
		
		let docPicker = UIDocumentPickerViewController(forExporting: tempFiles, asCopy: true)
		docPicker.modalPresentationStyle = .formSheet
		self.present(docPicker, animated: true)
	}
	
	func writeImageDirectory(for outline: Outline) -> [URL] {
		guard let imageGroups = outline.images?.values, !imageGroups.isEmpty else {
			return []
		}
		
		let allImages = imageGroups.flatMap({ $0 })
		guard !allImages.isEmpty else {
			return []
		}
		
		let dirURL = FileManager.default.temporaryDirectory.appendingPathComponent(outline.assetDirectoryName)

		do {
			try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
		} catch {
			self.presentError(title: "Export Error", message: error.localizedDescription)
			return []
		}
		
		for image in allImages {
			guard let data = image.data else { continue }
			let imageURL = dirURL.appendingPathComponent("\(image.id.imageUUID).png")
			do {
				try data.write(to: imageURL)
			} catch {
				self.presentError(title: "Export Error", message: error.localizedDescription)
			}
		}
		
		return [dirURL]
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

	func checkPointOutline() {
		editorViewController?.checkPointOutline()
	}

	func lockOutline() {
		guard let outline = editorViewController?.outline else { return }
		guard outline.isLocked != true else { return }

		Task {
			do {
				try await LockSessionManager.shared.authenticate(
					reason: String(localized: "Lock \(outline.title ?? "Outline")", comment: "Auth prompt: Lock outline")
				)

				let key = try LockKeyManager.createKey(for: outline.id)
				outline.encryptionService = OutlineEncryptionService(key: key)
				outline.update(isLocked: true)

				LockSessionManager.shared.markUnlocked(outline.id)

				await outline.forceSave()
			} catch {
				presentError(title: .errorAlertTitle, message: error.localizedDescription)
			}
		}
	}

	func removeLock() {
		guard let outline = editorViewController?.outline else { return }
		guard outline.isLocked == true else { return }
		guard LockSessionManager.shared.isUnlocked(outline.id) else { return }

		Task {
			do {
				try await LockSessionManager.shared.authenticate(
					reason: String(localized: "Remove lock from \(outline.title ?? "Outline")", comment: "Auth prompt: Remove lock")
				)

				outline.update(isLocked: false)
				outline.encryptionService = nil

				try LockKeyManager.deleteKey(for: outline.id)

				await outline.forceSave()
			} catch {
				presentError(title: .errorAlertTitle, message: error.localizedDescription)
			}
		}
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
	static let codeInline = NSToolbarItem.Identifier("io.vincode.Zavala.codeInline")
	static let highlight = NSToolbarItem.Identifier("io.vincode.Zavala.highlight")
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
