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
	
	var currentDocumentContainer: DocumentContainer? = nil

	var selectedOutlines: [Outline]? {
		guard let outline = editorViewController?.outline else { return nil }
		return [outline]
	}
	
	var editorViewController: EditorViewController? {
		return children.first as? EditorViewController
	}

	var isExportAndPrintUnavailable: Bool {
		return editorViewController?.isOutlineFunctionsUnavailable ?? true
	}
	
	var isGoBackwardOneUnavailable: Bool = false
	var isGoForwardOneUnavailable: Bool = false

	weak var sceneDelegate: OutlineEditorSceneDelegate?
	
	var stateRestorationActivity: NSUserActivity {
		return activityManager.stateRestorationActivity
	}

    private let activityManager = ActivityManager()
    
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
			let document = newOutlineDocument()
			editorViewController?.edit(document?.outline, isNew: true)
			if let document = document {
				pinWasVisited(Pin(document: document))
			}
			return
		}
		
		guard let userInfo = activity.userInfo else { return }
		
		if let searchIdentifier = userInfo[CSSearchableItemActivityIdentifier] as? String, let documentID = EntityID(description: searchIdentifier) {
			openDocument(documentID)
			return
		}
		
		let pin = Pin(userInfo: userInfo[Pin.UserInfoKeys.pin])
		if let documentID = pin.documentID {
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
			pinWasVisited(Pin(document: document))
		}
	}

	func newOutlineDocument(title: String? = nil) -> Document? {
		let accountID = AppDefaults.shared.lastSelectedAccountID
		
		guard let account = AccountManager.shared.findAccount(accountID: accountID) ?? AccountManager.shared.activeAccounts.first else { return nil }
		let document = account.createOutline(title: title)
		document.outline?.update(ownerName: AppDefaults.shared.ownerName, ownerEmail: AppDefaults.shared.ownerEmail, ownerURL: AppDefaults.shared.ownerURL)
		
		return document
	}

	func goBackwardOne() {	}
	func goForwardOne() { }
	
	func shutdown() {
		activityManager.invalidateSelectDocument()
		editorViewController?.edit(nil, isNew: false)
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
		alert.addAction(deleteAction)
		alert.addAction(cancelAction)
		alert.preferredAction = deleteAction
		
		present(alert, animated: true, completion: nil)
	}

	override func selectAll(_ sender: Any?) {
		if !(editorViewController?.isSelectAllRowsUnavailable ?? true) {
			editorViewController?.selectAllRows()
		}
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
		toggleCompletedFilter()
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

	@objc func moveRowsRight(_ sender: Any?) {
		moveRowsRight()
	}

	@objc func moveRowsLeft(_ sender: Any?) {
		moveRowsLeft()
	}

	@objc func moveRowsUp(_ sender: Any?) {
		moveRowsUp()
	}

	@objc func moveRowsDown(_ sender: Any?) {
		moveRowsDown()
	}

	@objc func toggleOutlineHideNotes(_ sender: Any?) {
		toggleNotesFilter()
	}

	@objc func printDoc(_ sender: Any?) {
		printDocs()
	}

	@objc func printList(_ sender: Any?) {
		printLists()
	}

	@objc func collaborate(_ sender: Any?) {
		collaborate()
	}

	@objc func outlineGetInfo(_ sender: Any?) {
		showGetInfo()
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

// MARK: EditorDelegate

extension EditorContainerViewController: EditorDelegate {

	// These aren't used when running in the EditorContainerViewController
	var editorViewControllerIsGoBackUnavailable: Bool { return true }
	var editorViewControllerIsGoForwardUnavailable: Bool { return true  }
	var editorViewControllerGoBackwardStack: [Pin] { return [Pin]() }
	var editorViewControllerGoForwardStack: [Pin] { return [Pin]() }
	func goBackward(_ : EditorViewController, to: Int) {}
	func goForward(_ : EditorViewController, to: Int) {}

	func createNewOutline(_: EditorViewController, title: String) -> Outline? {
		return newOutlineDocument(title: title)?.outline
	}

	func validateToolbar(_: EditorViewController) {
		sceneDelegate?.validateToolbar()
	}
	
	// These aren't used when running in the EditorContainerViewController
	func showGetInfo(_: EditorViewController, outline: Outline) { }
	func exportPDFDoc(_: EditorViewController, outline: Outline) {}
	func exportPDFList(_: EditorViewController, outline: Outline) {}
	func exportMarkdownDoc(_: EditorViewController, outline: Outline) {}
	func exportMarkdownList(_: EditorViewController, outline: Outline) {}
	func exportOPML(_: EditorViewController, outline: Outline) {}
	func printDoc(_: EditorViewController, outline: Outline) { }
	func printList(_: EditorViewController, outline: Outline) { }

	func zoomImage(_: EditorViewController, image: UIImage, transitioningDelegate: UIViewControllerTransitioningDelegate) {
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.viewImage)
		if let pngData = image.pngData() {
			activity.userInfo = [UIImage.UserInfoKeys.pngData: pngData]
		}
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
	}

}

// MARK: Toolbar

#if targetEnvironment(macCatalyst)

extension EditorContainerViewController: NSToolbarDelegate {
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return [
			.moveLeft,
			.moveRight,
			.space,
			.insertImage,
			.link,
			.boldface,
			.italic,
			.space,
			.collaborate,
			.share,
			.space,
			.toggleCompletedFilter,
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
			.toggleCompletedFilter,
			.expandAllInOutline,
			.collapseAllInOutline,
			.moveLeft,
			.moveRight,
			.moveUp,
			.moveDown,
			.printDoc,
			.printList,
			.collaborate,
			.share,
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
					item.image = AppAssets.bold.symbolSizedForCatalyst(pointSize: 18.0, color: .systemBlue)
				} else {
					item.image = AppAssets.bold.symbolSizedForCatalyst(pointSize: 18.0)
				}
				return self?.editorViewController?.isFormatUnavailable ?? true
			}
			item.image = AppAssets.bold.symbolSizedForCatalyst(pointSize: 18.0)
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
					item.image = AppAssets.italic.symbolSizedForCatalyst(pointSize: 18.0, color: .systemBlue)
				} else {
					item.image = AppAssets.italic.symbolSizedForCatalyst(pointSize: 18.0)
				}
				return self?.editorViewController?.isFormatUnavailable ?? true
			}
			item.image = AppAssets.italic.symbolSizedForCatalyst(pointSize: 18.0)
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
		case .moveRight:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isMoveRowsRightUnavailable ?? true
			}
			item.image = AppAssets.moveRight.symbolSizedForCatalyst()
			item.label = L10n.moveRight
			item.toolTip = L10n.moveRight
			item.isBordered = true
			item.action = #selector(moveRowsRight(_:))
			item.target = self
			toolbarItem = item
		case .moveLeft:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isMoveRowsLeftUnavailable ?? true
			}
			item.image = AppAssets.moveLeft.symbolSizedForCatalyst()
			item.label = L10n.moveLeft
			item.toolTip = L10n.moveLeft
			item.isBordered = true
			item.action = #selector(moveRowsLeft(_:))
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
		case .toggleCompletedFilter:
			let item = ValidatingMenuToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] item in
				guard let self = self else { return false }
				
				if self.editorViewController?.isFilterOn ?? false {
					item.image = AppAssets.filterActive.symbolSizedForCatalyst(color: .accentColor)
				} else {
					item.image = AppAssets.filterInactive.symbolSizedForCatalyst()
				}
				
				let turnFilterOnAction = UIAction() { [weak self] _ in
					DispatchQueue.main.async {
						   self?.toggleFilterOn()
					   }
				}
				
				turnFilterOnAction.title = self.isFilterOn ? L10n.turnFilterOff : L10n.turnFilterOn
				
				let turnFilterOnMenu = UIMenu(title: "", options: .displayInline, children: [turnFilterOnAction])
				
				let filterCompletedAction = UIAction(title: L10n.filterCompleted) { [weak self] _ in
					DispatchQueue.main.async {
						   self?.toggleCompletedFilter()
					   }
				}
				filterCompletedAction.state = self.isCompletedFiltered ? .on : .off
				filterCompletedAction.attributes = self.isFilterOn ? [] : .disabled

				let filterNotesAction = UIAction(title: L10n.filterNotes) { [weak self] _ in
					DispatchQueue.main.async {
						   self?.toggleNotesFilter()
					   }
				}
				filterNotesAction.state = self.isNotesFiltered ? .on : .off
				filterNotesAction.attributes = self.isFilterOn ? [] : .disabled

				let filterOptionsMenu = UIMenu(title: "", options: .displayInline, children: [filterCompletedAction, filterNotesAction])

				item.itemMenu = UIMenu(title: "", children: [turnFilterOnMenu, filterOptionsMenu])
				
				return self.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = AppAssets.filterInactive.symbolSizedForCatalyst()
			item.label = L10n.filter
			item.toolTip = L10n.filter
			item.isBordered = true
			item.target = self
			item.showsIndicator = false
			toolbarItem = item
		case .printDoc:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = AppAssets.printDoc.symbolSizedForCatalyst()
			item.label = L10n.printDoc
			item.toolTip = L10n.printDoc
			item.isBordered = true
			item.action = #selector(printDoc(_:))
			item.target = self
			toolbarItem = item
		case .printList:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = AppAssets.printList.symbolSizedForCatalyst()
			item.label = L10n.printList
			item.toolTip = L10n.printList
			item.isBordered = true
			item.action = #selector(printList(_:))
			item.target = self
			toolbarItem = item
		case .collaborate:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				if self?.editorViewController?.isDocumentCollaborating ?? false {
					item.image = AppAssets.collaborating.symbolSizedForCatalyst()
				} else if self?.editorViewController?.isCollaborateUnavailable ?? true {
					item.image = AppAssets.statelessCollaborate.symbolSizedForCatalyst()
				} else {
					item.image = AppAssets.collaborate.symbolSizedForCatalyst()
				}
				return self?.editorViewController?.isCollaborateUnavailable ?? true
			}
			item.image = AppAssets.collaborate.symbolSizedForCatalyst()
			item.label = L10n.collaborate
			item.toolTip = L10n.collaborate
			item.isBordered = true
			item.action = #selector(collaborate(_:))
			item.target = self
			toolbarItem = item
		case .share:
			let item = NSSharingServicePickerToolbarItem(itemIdentifier: .share)
			item.label = L10n.share
			item.toolTip = L10n.share
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
			let data = outline.markdownList().data(using: .utf8)
			completion(data, nil)
			return nil
		}
		
		return [itemProvider]
	}
	
}

#endif
