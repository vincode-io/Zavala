//
//  EditorContainerViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/17/21.
//

import UIKit
import CoreSpotlight
import SafariServices
import VinOutlineKit
import VinUtility

class EditorContainerViewController: UIViewController, MainCoordinator {
		
	var currentDocumentContainer: DocumentContainer? = nil

	var selectedDocuments: [Document] {
		guard let editorViewController else { return []	}
		return editorViewController.selectedDocuments
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
			if let document {
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
		} else {
			Task {
				self.presentError(title: .documentNotFoundTitle, message: .documentNotFoundMessage) {
					self.sceneDelegate?.closeWindow()
				}
			}
		}
	}

	func newOutlineDocument(title: String? = nil) -> Document? {
		let accountID = AppDefaults.shared.lastSelectedAccountID
		
		guard let account = AccountManager.shared.findAccount(accountID: accountID) ?? AccountManager.shared.activeAccounts.first else { return nil }
		let document = account.createOutline(title: title)
		
		let defaults = AppDefaults.shared
		document.outline?.update(checkSpellingWhileTyping: defaults.checkSpellingWhileTyping,
								 correctSpellingAutomatically: defaults.correctSpellingAutomatically,
								 autoLinkingEnabled: defaults.autoLinkingEnabled,
								 ownerName: defaults.ownerName,
								 ownerEmail: defaults.ownerEmail,
								 ownerURL: defaults.ownerURL)
		
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
		
		let deleteAction = UIAlertAction(title: .deleteControlLabel, style: .destructive) { _ in
			delete()
		}
		
		let cancelAction = UIAlertAction(title: .cancelControlLabel, style: .cancel)
		
		let alert = UIAlertController(title: .deleteOutlinePrompt(outlineTitle: document.title ?? ""),
																					message: .deleteOutlineMessage,
																					preferredStyle: .alert)
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
		Task {
			await AccountManager.shared.sync()
		}
	}

	@objc func insertImage(_ sender: Any?) {
		insertImage()
	}

	@objc func createOrDeleteNotes(_ sender: Any?) {
		createOrDeleteNotes()
	}

	@objc func toggleOutlineFilter(_ sender: Any?) {
		toggleCompletedFilter()
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

	@objc func toggleFocus(_ sender: Any?) {
		toggleFocus()
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

	@objc func outlineGetInfo(_ sender: Any?) {
		showGetInfo()
	}

	@objc func share(_ sender: Any?) {
		editorViewController?.share()
	}
	
	@objc func manageSharing(_ sender: Any?) {
		guard let shareRecord = selectedDocuments.first!.shareRecord, let container = AccountManager.shared.cloudKitAccount?.cloudKitContainer else {
			return
		}
		
		let controller = UICloudSharingController(share: shareRecord, container: container)
		controller.delegate = self
		self.present(controller, animated: true)
	}
	

	// MARK: Validation
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .delete:
			return !(editorViewController?.isDeleteCurrentRowUnavailable ?? true)
		case .share:
			return !isOutlineFunctionsUnavailable
		case .manageSharing:
			return !isManageSharingUnavailable
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

// MARK: UICloudSharingControllerDelegate

extension EditorContainerViewController: UICloudSharingControllerDelegate {
	
	func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
	}
	
	func itemTitle(for csc: UICloudSharingController) -> String? {
		return nil
	}
	
	func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
		Task { 
			try await Task.sleep(for: .seconds(2))
			await AccountManager.shared.sync()
		}
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
			.share,
			.space,
			.focus,
			.filter,
		]
	}
	
	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return [
			.delete,
			.sync,
			.insertImage,
			.link,
			.note,
			.boldface,
			.italic,
			.focus,
			.filter,
			.expandAllInOutline,
			.collapseAllInOutline,
			.moveLeft,
			.moveRight,
			.moveUp,
			.moveDown,
			.printDoc,
			.printList,
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
			item.image = .delete.symbolSizedForCatalyst()
			item.label = .deleteOutlineControlLabel
			item.toolTip = .deleteOutlineControlLabel
			item.isBordered = true
			item.action = #selector(deleteOutline(_:))
			item.target = self
			toolbarItem = item
		case .sync:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !AccountManager.shared.isSyncAvailable
			}
			item.image = .sync.symbolSizedForCatalyst()
			item.label = .syncControlLabel
			item.toolTip = .syncControlLabel
			item.isBordered = true
			item.action = #selector(sync(_:))
			item.target = self
			toolbarItem = item
		case .insertImage:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isInsertImageUnavailable ?? true
			}
			item.image = .insertImage.symbolSizedForCatalyst()
			item.label = .insertImageControlLabel
			item.toolTip = .insertImageControlLabel
			item.isBordered = true
			item.action = #selector(insertImage(_:))
			item.target = self
			toolbarItem = item
		case .link:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.image = .link.symbolSizedForCatalyst()
			item.label = .linkControlLabel
			item.toolTip = .linkControlLabel
			item.isBordered = true
			item.action = .editLink
			toolbarItem = item
		case .note:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				if !(self?.editorViewController?.isCreateRowNotesUnavailable ?? true) {
					item.image = .noteAdd.symbolSizedForCatalyst()
					item.label = .addNoteControlLabel
					item.toolTip = .addNoteControlLabel
					return false
				} else if !(self?.editorViewController?.isDeleteRowNotesUnavailable ?? true) {
					item.image = .noteDelete.symbolSizedForCatalyst()
					item.label = .deleteNoteControlLabel
					item.toolTip = .deleteNoteControlLabel
					return false
				} else {
					item.image = .noteAdd.symbolSizedForCatalyst()
					item.label = .addNoteControlLabel
					item.toolTip = .addNoteControlLabel
					return true
				}
			}
			item.image = .noteAdd.symbolSizedForCatalyst()
			item.label = .addNoteControlLabel
			item.toolTip = .addNoteControlLabel
			item.isBordered = true
			item.action = #selector(createOrDeleteNotes(_:))
			item.target = self
			toolbarItem = item
		case .boldface:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				if self?.editorViewController?.isBoldToggledOn ?? false {
					item.image = .bold.symbolSizedForCatalyst(pointSize: 18.0, color: .systemBlue)
				} else {
					item.image = .bold.symbolSizedForCatalyst(pointSize: 18.0)
				}
				return !UIResponder.valid(action: .toggleBoldface)
			}
			item.image = .bold.symbolSizedForCatalyst(pointSize: 18.0)
			item.label = .boldControlLabel
			item.toolTip = .boldControlLabel
			item.isBordered = true
			item.action = .toggleBoldface
			toolbarItem = item
		case .italic:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				if self?.editorViewController?.isItalicToggledOn ?? false {
					item.image = .italic.symbolSizedForCatalyst(pointSize: 18.0, color: .systemBlue)
				} else {
					item.image = .italic.symbolSizedForCatalyst(pointSize: 18.0)
				}
				return !UIResponder.valid(action: .toggleItalics)
			}
			item.image = .italic.symbolSizedForCatalyst(pointSize: 18.0)
			item.label = .italicControlLabel
			item.toolTip = .italicControlLabel
			item.isBordered = true
			item.action = .toggleItalics
			toolbarItem = item
		case .expandAllInOutline:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isExpandAllInOutlineUnavailable ?? true
			}
			item.image = .expandAll.symbolSizedForCatalyst()
			item.label = .expandControlLabel
			item.toolTip = .expandAllInOutlineControlLabel
			item.isBordered = true
			item.action = #selector(expandAllInOutline(_:))
			item.target = self
			toolbarItem = item
		case .collapseAllInOutline:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isCollapseAllInOutlineUnavailable ?? true
			}
			item.image = .collapseAll.symbolSizedForCatalyst()
			item.label = .collapseControlLabel
			item.toolTip = .collapseAllInOutlineControlLabel
			item.isBordered = true
			item.action = #selector(collapseAllInOutline(_:))
			item.target = self
			toolbarItem = item
		case .moveRight:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isMoveRowsRightUnavailable ?? true
			}
			item.image = .moveRight.symbolSizedForCatalyst()
			item.label = .moveRightControlLabel
			item.toolTip = .moveRightControlLabel
			item.isBordered = true
			item.action = #selector(moveRowsRight(_:))
			item.target = self
			toolbarItem = item
		case .moveLeft:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isMoveRowsLeftUnavailable ?? true
			}
			item.image = .moveLeft.symbolSizedForCatalyst()
			item.label = .moveLeftControlLabel
			item.toolTip = .moveLeftControlLabel
			item.isBordered = true
			item.action = #selector(moveRowsLeft(_:))
			item.target = self
			toolbarItem = item
		case .moveUp:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isMoveRowsUpUnavailable ?? true
			}
			item.image = .moveUp.symbolSizedForCatalyst()
			item.label = .moveUpControlLabel
			item.toolTip = .moveUpControlLabel
			item.isBordered = true
			item.action = #selector(moveRowsUp(_:))
			item.target = self
			toolbarItem = item
		case .moveDown:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isMoveRowsDownUnavailable ?? true
			}
			item.image = .moveDown.symbolSizedForCatalyst()
			item.label = .moveDownControlLabel
			item.toolTip = .moveDownControlLabel
			item.isBordered = true
			item.action = #selector(moveRowsDown(_:))
			item.target = self
			toolbarItem = item
		case .focus:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				if self?.editorViewController?.isFocusOutUnavailable ?? true {
					item.image = .focusInactive.symbolSizedForCatalyst(pointSize: 17)
					item.label = .focusInControlLabel
					item.toolTip = .focusInControlLabel
				} else {
					item.image = .focusActive.symbolSizedForCatalyst(pointSize: 17, color: .accentColor)
					item.label = .focusOutControlLabel
					item.toolTip = .focusOutControlLabel
				}
				return self?.editorViewController?.isFocusInUnavailable ?? true && self?.editorViewController?.isFocusOutUnavailable ?? true
			}
			item.image = .focusInactive.symbolSizedForCatalyst()
			item.label = .focusInControlLabel
			item.toolTip = .focusInControlLabel
			item.isBordered = true
			item.action = #selector(toggleFocus(_:))
			item.target = self
			toolbarItem = item
		case .filter:
			let item = ValidatingMenuToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] item in
				guard let self else { return false }
				
				if self.editorViewController?.isFilterOn ?? false {
					item.image = .filterActive.symbolSizedForCatalyst(pointSize: 17, color: .accentColor)
				} else {
					item.image = .filterInactive.symbolSizedForCatalyst(pointSize: 17)
				}
				
				let turnFilterOnAction = UIAction() { [weak self] _ in
					Task { @MainActor in
						self?.toggleFilterOn()
					}
				}
				
				turnFilterOnAction.title = self.isFilterOn ? .turnFilterOffControlLabel : .turnFilterOnControlLabel
				
				let turnFilterOnMenu = UIMenu(title: "", options: .displayInline, children: [turnFilterOnAction])
				
				let filterCompletedAction = UIAction(title: .filterCompletedControlLabel) { [weak self] _ in
					Task { @MainActor in
						self?.toggleCompletedFilter()
					}
				}
				filterCompletedAction.state = self.isCompletedFiltered ? .on : .off
				filterCompletedAction.attributes = self.isFilterOn ? [] : .disabled

				let filterNotesAction = UIAction(title: .filterNotesControlLabel) { [weak self] _ in
					Task { @MainActor in
						self?.toggleNotesFilter()
					}
				}
				filterNotesAction.state = self.isNotesFiltered ? .on : .off
				filterNotesAction.attributes = self.isFilterOn ? [] : .disabled

				let filterOptionsMenu = UIMenu(title: "", options: .displayInline, children: [filterCompletedAction, filterNotesAction])

				item.itemMenu = UIMenu(title: "", children: [turnFilterOnMenu, filterOptionsMenu])
				
				return self.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = .filterInactive.symbolSizedForCatalyst()
			item.label = .filterControlLabel
			item.toolTip = .filterControlLabel
			item.isBordered = true
			item.target = self
			item.showsIndicator = false
			toolbarItem = item
		case .printDoc:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = .printDoc.symbolSizedForCatalyst()
			item.label = .printDocControlLabel
			item.toolTip = .printDocControlLabel
			item.isBordered = true
			item.action = #selector(printDoc(_:))
			item.target = self
			toolbarItem = item
		case .printList:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = .printList.symbolSizedForCatalyst()
			item.label = .printListControlLabel
			item.toolTip = .printListControlLabel
			item.isBordered = true
			item.action = #selector(printList(_:))
			item.target = self
			toolbarItem = item
		case .share:
			let item = NSSharingServicePickerToolbarItem(itemIdentifier: .share)
			item.label = .shareControlLabel
			item.toolTip = .shareControlLabel
			item.activityItemsConfiguration = DocumentsActivityItemsConfiguration(delegate: self)
			toolbarItem = item
		case .getInfo:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = .getInfo.symbolSizedForCatalyst()
			item.label = .getInfoControlLabel
			item.toolTip = .getInfoControlLabel
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

#endif
