//
//  EditorContainerViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/17/21.
//

import UIKit
import CoreSpotlight
import Templeton
import SafariServices

class EditorContainerViewController: UIViewController, MainCoordinator {

	var editorViewController: EditorViewController? {
		return children.first as? EditorViewController
	}
	
	var isOutlineActionUnavailable: Bool = false
	
	weak var sceneDelegate: OutlineEditorSceneDelegate?
	
	var stateRestorationActivity: NSUserActivity {
		return activityManager.stateRestorationActivity
	}

	var activityManager = ActivityManager()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		editorViewController?.delegate = self
		NotificationCenter.default.addObserver(self, selector: #selector(documentTitleDidChange(_:)), name: .DocumentTitleDidChange, object: nil)
    }
    
	@objc func documentTitleDidChange(_ note: Notification) {
		sceneDelegate?.window?.windowScene?.title = editorViewController?.outline?.title
	}

	func handle(_ activity: NSUserActivity) {
		guard activity.activityType != NSUserActivity.ActivityType.newOutline else {
			newOutline()
			return
		}
		
		guard let userInfo = activity.userInfo else { return }
		
		if let searchIdentifier = userInfo[CSSearchableItemActivityIdentifier] as? String, let documentID = EntityID(description: searchIdentifier) {
			openDocument(documentID)
			return
		}
		
		if let entityUserInfo = userInfo[UserInfoKeys.documentID] as? [AnyHashable: AnyHashable], let documentID = EntityID(userInfo: entityUserInfo) {
			openDocument(documentID)
			return
		}
		
		sceneDelegate?.closeWindow()
	}
	
	func openDocument(_ documentID: EntityID) {
		if let document = AccountManager.shared.findDocument(documentID), let outline = document.outline {
			sceneDelegate?.window?.windowScene?.title = outline.title
			activityManager.selectingDocument(nil, document)
			editorViewController?.edit(outline, isNew: false)
		}
	}

	func newOutline() {
		let accountID = AppDefaults.shared.lastSelectedAccountID
		
		guard let account = AccountManager.shared.findAccount(accountID: accountID) ?? AccountManager.shared.activeAccounts.first else { return }
		guard let outline = account.createOutline().outline else { return }
		outline.update(ownerName: AppDefaults.shared.ownerName, ownerEmail: AppDefaults.shared.ownerEmail, ownerURL: AppDefaults.shared.ownerURL)

		editorViewController?.edit(outline, isNew: true)
	}

	func shutdown() {
		editorViewController?.edit(nil, isNew: false)
	}
	
	func exportJekyll() {
		#if targetEnvironment(macCatalyst)
		let openJekyllExportViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "MacJekyllExportViewController") as! MacJekyllExportViewController
		openJekyllExportViewController.preferredContentSize = CGSize(width: 500, height: 150)
//		openJekyllExportViewController.delegate = self
		present(openJekyllExportViewController, animated: true)
		#endif
	}

	func exportMarkdown() {
		guard let outline = editorViewController?.outline else { return }
		exportMarkdownForOutline(outline)
	}
	
	func exportOPML() {
		guard let outline = editorViewController?.outline else { return }
		exportOPMLForOutline(outline)
	}
	
	func openURL(_ urlString: String) {
		guard let url = URL(string: urlString) else { return }
		let vc = SFSafariViewController(url: url)
		vc.modalPresentationStyle = .pageSheet
		present(vc, animated: true)
	}
	
	func showSettings() {
		// No need to implement this since it is used on iOS only
	}
	
	// MARK: Actions
	
	override func delete(_ sender: Any?) {
		guard editorViewController?.isDeleteCurrentRowUnavailable ?? true else {
			editorViewController?.deleteCurrentRows()
			return
		}
	}

	@objc func deleteOutline(_ sender: Any?) {
		guard let outline = editorViewController?.outline else { return }
		let document = Document.outline(outline)
		
		func delete() {
			document.account?.deleteDocument(document)
			sceneDelegate?.closeWindow()
		}

		guard !document.isEmpty else {
			delete()
			return
		}
		
		let deleteAction = UIAlertAction(title: L10n.delete, style: .destructive) { _ in
			delete()
		}
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel)
		
		let alert = UIAlertController(title: L10n.deleteOutlinePrompt(document.title ?? ""), message: L10n.deleteOutlineMessage, preferredStyle: .alert)
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		alert.preferredAction = deleteAction
		
		present(alert, animated: true, completion: nil)
	}

	@objc func sync(_ sender: Any?) {
		AccountManager.shared.sync()
	}

	@objc func insertImage(_ sender: Any?) {
		insertImage()
	}

	@objc func link(_ sender: Any?) {
		link()
	}

	@objc func toggleOutlineFilter(_ sender: Any?) {
		toggleOutlineFilter()
	}

	@objc func outlineToggleBoldface(_ sender: Any?) {
		outlineToggleBoldface()
	}

	@objc func outlineToggleItalics(_ sender: Any?) {
		outlineToggleItalics()
	}

	@objc func expandAllInOutline(_ sender: Any?) {
		expandAllInOutline()
	}

	@objc func collapseAllInOutline(_ sender: Any?) {
		collapseAllInOutline()
	}

	@objc func indentRows(_ sender: Any?) {
		indentRows()
	}

	@objc func outdentRows(_ sender: Any?) {
		outdentRows()
	}

	@objc func moveRowsUp(_ sender: Any?) {
		moveRowsUp()
	}

	@objc func moveRowsDown(_ sender: Any?) {
		moveRowsDown()
	}

	@objc func toggleOutlineHideNotes(_ sender: Any?) {
		toggleOutlineHideNotes()
	}

	@objc func printDocument(_ sender: Any?) {
		printDocument()
	}

	@objc func share(_ sender: Any?) {
		share()
	}

	@objc func outlineGetInfo(_ sender: Any?) {
		outlineGetInfo()
	}

	// MARK: Validation
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case #selector(delete(_:)):
			return !(editorViewController?.isDeleteCurrentRowUnavailable ?? true)
		default:
			return super.canPerformAction(action, withSender: sender)
		}
	}
	
}

// MARK: Helpers

extension EditorContainerViewController: EditorDelegate {
	
	func validateToolbar(_: EditorViewController) {
		sceneDelegate?.validateToolbar()
	}
	
	// These aren't used when running in the EditorContainerViewController
	func exportMarkdown(_: EditorViewController, outline: Outline) {}
	func exportMarkdownPost(_: EditorViewController, outline: Outline) {}
	func exportOPML(_: EditorViewController, outline: Outline) {}

}

// MARK: Helpers

extension EditorContainerViewController {
	
	private func exportMarkdownForOutline(_ outline: Outline) {
		let markdown = outline.markdown()
		export(markdown, fileName: outline.fileName(withSuffix: "md"))
	}
	
	private func exportOPMLForOutline(_ outline: Outline) {
		let opml = outline.opml()
		export(opml, fileName: outline.fileName(withSuffix: "opml"))
	}
	
	private func export(_ string: String, fileName: String) {
		let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
		
		do {
			try string.write(to: tempFile, atomically: true, encoding: String.Encoding.utf8)
		} catch {
			self.presentError(title: "Export Error", message: error.localizedDescription)
		}
		
		let docPicker = UIDocumentPickerViewController(forExporting: [tempFile], asCopy: true)
		docPicker.modalPresentationStyle = .formSheet
		self.present(docPicker, animated: true)
	}
}

// MARK: Toolbar

#if targetEnvironment(macCatalyst)

extension EditorContainerViewController: NSToolbarDelegate {
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return [
			.insertImage,
			.link,
			.boldface,
			.italic,
			.space,
			.share,
			.sendCopy,
			.space,
			.toggleOutlineFilter,
		]
	}
	
	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return [
			.delete,
			.sync,
			.insertImage,
			.link,
			.boldface,
			.italic,
			.toggleOutlineNotesHidden,
			.toggleOutlineFilter,
			.expandAllInOutline,
			.collapseAllInOutline,
			.indent,
			.outdent,
			.moveUp,
			.moveDown,
			.print,
			.share,
			.sendCopy,
			.getInfo,
			.space,
			.flexibleSpace
		]
	}
	
	func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
		
		var toolbarItem: NSToolbarItem?
		
		switch itemIdentifier {
		case .delete:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return false
			}
			item.image = AppAssets.delete.symbolSizedForCatalyst()
			item.label = L10n.deleteOutline
			item.toolTip = L10n.deleteOutline
			item.isBordered = true
			item.action = #selector(deleteOutline(_:))
			item.target = self
			toolbarItem = item
		case .sync:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !AccountManager.shared.isSyncAvailable
			}
			item.image = AppAssets.sync.symbolSizedForCatalyst()
			item.label = L10n.sync
			item.toolTip = L10n.sync
			item.isBordered = true
			item.action = #selector(sync(_:))
			item.target = self
			toolbarItem = item
		case .insertImage:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isInsertImageUnavailable ?? true
			}
			item.image = AppAssets.insertImage.symbolSizedForCatalyst()
			item.label = L10n.insertImage
			item.toolTip = L10n.insertImage
			item.isBordered = true
			item.action = #selector(insertImage(_:))
			item.target = self
			toolbarItem = item
		case .link:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isLinkUnavailable ?? true
			}
			item.image = AppAssets.link.symbolSizedForCatalyst()
			item.label = L10n.link
			item.toolTip = L10n.link
			item.isBordered = true
			item.action = #selector(link(_:))
			item.target = self
			toolbarItem = item
		case .boldface:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				if self?.editorViewController?.isBoldToggledOn ?? false {
					item.image = AppAssets.bold.symbolSizedForCatalyst(pointSize: 22.0, color: .systemBlue)
				} else {
					item.image = AppAssets.bold.symbolSizedForCatalyst(pointSize: 22.0)
				}
				return self?.editorViewController?.isFormatUnavailable ?? true
			}
			item.image = AppAssets.bold.symbolSizedForCatalyst(pointSize: 22.0)
			item.label = L10n.bold
			item.toolTip = L10n.bold
			item.isBordered = true
			item.action = #selector(outlineToggleBoldface(_:))
			item.target = self
			toolbarItem = item
		case .italic:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				if self?.editorViewController?.isItalicToggledOn ?? false {
					item.image = AppAssets.italic.symbolSizedForCatalyst(pointSize: 22.0, color: .systemBlue)
				} else {
					item.image = AppAssets.italic.symbolSizedForCatalyst(pointSize: 22.0)
				}
				return self?.editorViewController?.isFormatUnavailable ?? true
			}
			item.image = AppAssets.italic.symbolSizedForCatalyst(pointSize: 22.0)
			item.label = L10n.italic
			item.toolTip = L10n.italic
			item.isBordered = true
			item.action = #selector(outlineToggleItalics(_:))
			item.target = self
			toolbarItem = item
		case .expandAllInOutline:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isExpandAllInOutlineUnavailable ?? true
			}
			item.image = AppAssets.expandAll.symbolSizedForCatalyst()
			item.label = L10n.expand
			item.toolTip = L10n.expandAllInOutline
			item.isBordered = true
			item.action = #selector(expandAllInOutline(_:))
			item.target = self
			toolbarItem = item
		case .collapseAllInOutline:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isCollapseAllInOutlineUnavailable ?? true
			}
			item.image = AppAssets.collapseAll.symbolSizedForCatalyst()
			item.label = L10n.collapse
			item.toolTip = L10n.collapseAllInOutline
			item.isBordered = true
			item.action = #selector(collapseAllInOutline(_:))
			item.target = self
			toolbarItem = item
		case .indent:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isIndentRowsUnavailable ?? true
			}
			item.image = AppAssets.indent.symbolSizedForCatalyst()
			item.label = L10n.indent
			item.toolTip = L10n.indent
			item.isBordered = true
			item.action = #selector(indentRows(_:))
			item.target = self
			toolbarItem = item
		case .outdent:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isOutdentRowsUnavailable ?? true
			}
			item.image = AppAssets.outdent.symbolSizedForCatalyst()
			item.label = L10n.outdent
			item.toolTip = L10n.outdent
			item.isBordered = true
			item.action = #selector(outdentRows(_:))
			item.target = self
			toolbarItem = item
		case .moveUp:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isMoveRowsUpUnavailable ?? true
			}
			item.image = AppAssets.moveUp.symbolSizedForCatalyst()
			item.label = L10n.moveUp
			item.toolTip = L10n.moveUp
			item.isBordered = true
			item.action = #selector(moveRowsUp(_:))
			item.target = self
			toolbarItem = item
		case .moveDown:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isMoveRowsDownUnavailable ?? true
			}
			item.image = AppAssets.moveDown.symbolSizedForCatalyst()
			item.label = L10n.moveDown
			item.toolTip = L10n.moveDown
			item.isBordered = true
			item.action = #selector(moveRowsDown(_:))
			item.target = self
			toolbarItem = item
		case .toggleOutlineFilter:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] item in
				if self?.editorViewController?.isOutlineFiltered ?? false {
					item.image = AppAssets.filterActive.symbolSizedForCatalyst()
					item.label = L10n.showCompleted
					item.toolTip = L10n.showCompleted
				} else {
					item.image = AppAssets.filterInactive.symbolSizedForCatalyst()
					item.label = L10n.hideCompleted
					item.toolTip = L10n.hideCompleted
				}
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = AppAssets.filterInactive.symbolSizedForCatalyst()
			item.label = L10n.hideCompleted
			item.toolTip = L10n.hideCompleted
			item.isBordered = true
			item.action = #selector(toggleOutlineFilter(_:))
			item.target = self
			toolbarItem = item
		case .toggleOutlineNotesHidden:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] item in
				if self?.editorViewController?.isOutlineNotesHidden ?? false {
					item.image = AppAssets.hideNotesActive.symbolSizedForCatalyst()
					item.label = L10n.showNotes
					item.toolTip = L10n.showNotes
				} else {
					item.image = AppAssets.hideNotesInactive.symbolSizedForCatalyst()
					item.label = L10n.hideNotes
					item.toolTip = L10n.hideNotes
				}
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = AppAssets.hideNotesInactive.symbolSizedForCatalyst()
			item.label = L10n.hideNotes
			item.toolTip = L10n.hideNotes
			item.isBordered = true
			item.action = #selector(toggleOutlineHideNotes(_:))
			item.target = self
			toolbarItem = item
		case .print:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = AppAssets.print.symbolSizedForCatalyst()
			item.label = L10n.print
			item.toolTip = L10n.print
			item.isBordered = true
			item.action = #selector(printDocument(_:))
			item.target = self
			toolbarItem = item
		case .share:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				if self?.editorViewController?.isDocumentShared ?? false {
					item.image = AppAssets.shared.symbolSizedForCatalyst()
				} else if self?.editorViewController?.isShareUnavailable ?? true {
					item.image = AppAssets.statelessShare.symbolSizedForCatalyst()
				} else {
					item.image = AppAssets.share.symbolSizedForCatalyst()
				}
				return self?.editorViewController?.isShareUnavailable ?? true
			}
			item.image = AppAssets.share.symbolSizedForCatalyst()
			item.label = L10n.share
			item.toolTip = L10n.share
			item.isBordered = true
			item.action = #selector(share(_:))
			item.target = self
			toolbarItem = item
		case .sendCopy:
			let item = NSSharingServicePickerToolbarItem(itemIdentifier: .sendCopy)
			item.label = L10n.sendCopy
			item.toolTip = L10n.sendCopy
			item.activityItemsConfiguration = self
			toolbarItem = item
		case .getInfo:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = AppAssets.getInfo.symbolSizedForCatalyst()
			item.label = L10n.getInfo
			item.toolTip = L10n.getInfo
			item.isBordered = true
			item.action = #selector(outlineGetInfo(_:))
			item.target = self
			toolbarItem = item
		case .toggleSidebar:
			toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
		default:
			toolbarItem = nil
		}
		
		return toolbarItem
	}
}

extension EditorContainerViewController: UIActivityItemsConfigurationReading {
	
	var itemProvidersForActivityItemsConfiguration: [NSItemProvider] {
		guard let outline = editorViewController?.outline else {
			return [NSItemProvider]()
		}
		
		let itemProvider = NSItemProvider()
		
		itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
			let data = outline.markdown().data(using: .utf8)
			completion(data, nil)
			return nil
		}
		
		return [itemProvider]
	}
	
}

#endif
