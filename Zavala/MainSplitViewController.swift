//
//  MainSplitViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import CoreSpotlight
import Templeton
import SafariServices

protocol MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { get }
}

enum MainControllerIdentifier {
	case none
	case sidebar
	case timeline
	case editor
}

class MainSplitViewController: UISplitViewController, MainCoordinator {
	
	struct UserInfoKeys {
		static let goBackwardStack = "goBackwardStack"
		static let goForwardStack = "goForwardStack"
		static let sidebarWidth = "sidebarWidth"
		static let timelineWidth = "timelineWidth"
	}
	
	weak var sceneDelegate: SceneDelegate?

	var stateRestorationActivity: NSUserActivity {
		let activity = appDelegate.activityManager.stateRestorationActivity
		var userInfo = activity.userInfo == nil ? [AnyHashable: Any]() : activity.userInfo

		userInfo![UserInfoKeys.goBackwardStack] = goBackwardStack.map { $0.userInfo }
		userInfo![UserInfoKeys.goForwardStack] = goForwardStack.map { $0.userInfo }

		if traitCollection.userInterfaceIdiom == .mac {
			userInfo![UserInfoKeys.sidebarWidth] = primaryColumnWidth
			userInfo![UserInfoKeys.timelineWidth] = supplementaryColumnWidth
		}

		activity.userInfo = userInfo
		return activity
	}
	
	var isDeleteEntityUnavailable: Bool {
		return (editorViewController?.isOutlineFunctionsUnavailable ?? true) &&
			(editorViewController?.isDeleteCurrentRowUnavailable ?? true) 
	}

	var currentDocumentContainer: DocumentContainer? {
		return sidebarViewController?.currentDocumentContainer
	}

	var editorViewController: EditorViewController? {
		viewController(for: .secondary) as? EditorViewController
	}
	
	var isGoBackwardOneUnavailable: Bool {
		return goBackwardStack.isEmpty
	}
	
	var isGoForwardOneUnavailable: Bool {
		return goForwardStack.isEmpty
	}
	
	private var sidebarViewController: SidebarViewController? {
		return viewController(for: .primary) as? SidebarViewController
	}
	
	private var timelineViewController: TimelineViewController? {
		viewController(for: .supplementary) as? TimelineViewController
	}
	
	private var lastMainControllerToAppear = MainControllerIdentifier.none
	
	private var lastPin: Pin?
	private var goBackwardStack = [Pin]()
	private var goForwardStack = [Pin]()

	override func viewDidLoad() {
        super.viewDidLoad()
		primaryBackgroundStyle = .sidebar

		if traitCollection.userInterfaceIdiom == .mac {
			if preferredPrimaryColumnWidth < 1 {
				preferredPrimaryColumnWidth = 200
			}
			if preferredSupplementaryColumnWidth < 1 {
				preferredSupplementaryColumnWidth = 300
			}
			presentsWithGesture = false
		}

		delegate = self
    }
	
	// MARK: Notifications
	
	@objc func accountDocumentsDidChange(_ note: Notification) {
		cleanUpNavigationStacks()
	}

	@objc func accountManagerAccountsDidChange(_ note: Notification) {
		cleanUpNavigationStacks()
	}

	@objc func accountMetadataDidChange(_ note: Notification) {
		cleanUpNavigationStacks()
	}

	// MARK: API
	
	func startUp() {
		sidebarViewController?.navigationController?.delegate = self
		sidebarViewController?.delegate = self
		timelineViewController?.navigationController?.delegate = self
		timelineViewController?.delegate = self
		sidebarViewController?.startUp()
		editorViewController?.delegate = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountDocumentsDidChange(_:)), name: .AccountDocumentsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountManagerAccountsDidChange(_:)), name: .AccountManagerAccountsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountMetadataDidChange(_:)), name: .AccountMetadataDidChange, object: nil)
	}
	
	func handle(_ activity: NSUserActivity, isNavigationBranch: Bool) {
		guard let userInfo = activity.userInfo else { return }
		handle(userInfo, isNavigationBranch: isNavigationBranch)
	}

	func handle(_ userInfo: [AnyHashable: Any], isNavigationBranch: Bool) {
		if let searchIdentifier = userInfo[CSSearchableItemActivityIdentifier] as? String, let documentID = EntityID(description: searchIdentifier) {
			handleDocument(documentID, isNavigationBranch: isNavigationBranch)
			return
		}
		
		if let goBackwardStackUserInfos = userInfo[UserInfoKeys.goBackwardStack] as? [Any] {
			goBackwardStack = goBackwardStackUserInfos.compactMap { Pin(userInfo: $0) }
		}

		if let goForwardStackUserInfos = userInfo[UserInfoKeys.goForwardStack] as? [Any] {
			goForwardStack = goForwardStackUserInfos.compactMap { Pin(userInfo: $0) }
		}

		cleanUpNavigationStacks()
		
		if let sidebarWidth = userInfo[UserInfoKeys.sidebarWidth] as? CGFloat {
			preferredPrimaryColumnWidth = sidebarWidth
		}
		
		if let timelineWidth = userInfo[UserInfoKeys.timelineWidth] as? CGFloat {
			preferredSupplementaryColumnWidth = timelineWidth
		}

		let pin = Pin(userInfo: userInfo[Zavala.UserInfoKeys.pin])
		
		guard let documentContainer = pin.container else {
			return
		}
		
		sidebarViewController?.selectDocumentContainer(documentContainer, isNavigationBranch: isNavigationBranch, animated: false) {
			self.lastMainControllerToAppear = .timeline

			guard let document = pin.document else {
				return
			}
			
			self.handleSelectDocument(document, isNavigationBranch: isNavigationBranch)
		}
	}
	
	func handleDocument(_ documentID: EntityID, isNavigationBranch: Bool) {
		guard let account = AccountManager.shared.findAccount(accountID: documentID.accountID),
			  let document = account.findDocument(documentID) else { return }
		
		if let sidebarTag = sidebarViewController?.currentTag, document.hasTag(sidebarTag) {
			self.handleSelectDocument(document, isNavigationBranch: isNavigationBranch)
		} else if document.tagCount == 1, let tag = document.tags?.first {
			sidebarViewController?.selectDocumentContainer(TagDocuments(account: account, tag: tag), isNavigationBranch: true, animated: false) {
				self.handleSelectDocument(document, isNavigationBranch: isNavigationBranch)
			}
		} else {
			sidebarViewController?.selectDocumentContainer(AllDocuments(account: account), isNavigationBranch: true, animated: false) {
				self.handleSelectDocument(document, isNavigationBranch: isNavigationBranch)
			}
		}
	}
	
	func handlePin(_ pin: Pin) {
		guard let documentContainer = pin.container else { return }
		sidebarViewController?.selectDocumentContainer(documentContainer, isNavigationBranch: true, animated: false) {
			self.timelineViewController?.selectDocument(pin.document, isNavigationBranch: true, animated: false)
		}
	}
	
	func importOPMLs(urls: [URL]) {
		selectDefaultDocumentContainer {
			self.timelineViewController?.importOPMLs(urls: urls)
		}
	}
	
	func showOpenQuickly() {
		if traitCollection.userInterfaceIdiom == .mac {
		
//			let openQuicklyViewController = UIStoryboard.openQuickly.instantiateViewController(withIdentifier: "MacOpenQuicklyViewController") as! MacOpenQuicklyViewController
//			openQuicklyViewController.preferredContentSize = CGSize(width: 300, height: 60)
//			openQuicklyViewController.delegate = self
//			present(openQuicklyViewController, animated: true)
		
		} else {

			let outlineGetInfoNavViewController = UIStoryboard.openQuickly.instantiateViewController(withIdentifier: "OpenQuicklyViewControllerNav") as! UINavigationController
			outlineGetInfoNavViewController.preferredContentSize = CGSize(width: 400, height: 100)
			outlineGetInfoNavViewController.modalPresentationStyle = .formSheet
			let outlineGetInfoViewController = outlineGetInfoNavViewController.topViewController as! OpenQuicklyViewController
			outlineGetInfoViewController.delegate = self
			present(outlineGetInfoNavViewController, animated: true)
			
		}
	}
	
	func goBackwardOne() {
		goBackward(to: 0)
	}
	
	func goForwardOne() {
		goForward(to: 0)
	}

	func validateToolbar() {
		self.sceneDelegate?.validateToolbar()
	}
	
	// MARK: Actions
	
	override func delete(_ sender: Any?) {
		guard editorViewController?.isDeleteCurrentRowUnavailable ?? true else {
			editorViewController?.deleteCurrentRows()
			return
		}
		
		guard editorViewController?.isOutlineFunctionsUnavailable ?? true else {
			timelineViewController?.deleteCurrentDocument()
			return
		}
	}
	
	@objc func sync(_ sender: Any?) {
		AccountManager.shared.sync()
	}
	
	@objc func createOutline(_ sender: Any?) {
		selectDefaultDocumentContainerIfNecessary() {
			self.timelineViewController?.createOutline(sender)
		}
	}
	
	@objc func importOPML() {
		selectDefaultDocumentContainerIfNecessary() {
			self.timelineViewController?.importOPML(self)
		}
	}
	
	@objc func toggleSidebar(_ sender: Any?) {
		UIView.animate(withDuration: 0.25) {
			self.preferredDisplayMode = self.displayMode == .twoBesideSecondary ? .secondaryOnly : .twoBesideSecondary
		}
	}

	@objc func insertImage(_ sender: Any?) {
		insertImage()
	}

	@objc func goBackwardOne(_ sender: Any?) {
		goBackward(to: 0)
	}

	@objc func goForwardOne(_ sender: Any?) {
		goForward(to: 0)
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
		toggleOutlineHideNotes()
	}

	@objc func printDoc(_ sender: Any?) {
		printDoc()
	}

	@objc func printList(_ sender: Any?) {
		printList()
	}

	@objc func collaborate(_ sender: Any?) {
		collaborate()
	}

	@objc func outlineGetInfo(_ sender: Any?) {
		showGetInfo()
	}

	func beginDocumentSearch() {
		sidebarViewController?.beginDocumentSearch()
	}
	
	// MARK: Validations
	
	override func validate(_ command: UICommand) {
		switch command.action {
		case #selector(delete(_:)):
			if isDeleteEntityUnavailable {
				command.attributes = .disabled
			}
		default:
			break
		}
	}
	
}

// MARK: SidebarDelegate

extension MainSplitViewController: SidebarDelegate {
	
	func documentContainerSelectionDidChange(_: SidebarViewController, documentContainer: DocumentContainer?, isNavigationBranch: Bool, animated: Bool, completion: (() -> Void)? = nil) {
		if isNavigationBranch, let lastPin = lastPin {
			goBackwardStack.insert(lastPin, at: 0)
			goBackwardStack = Array(goBackwardStack.prefix(10))
			self.lastPin = nil
			goForwardStack.removeAll()
		}

		if let accountID = documentContainer?.account?.id.accountID {
			AppDefaults.shared.lastSelectedAccountID = accountID
		}
		
		if let documentContainer = documentContainer {
			appDelegate.activityManager.selectingDocumentContainer(documentContainer)
			if animated {
				show(.supplementary)
			} else {
				UIView.performWithoutAnimation {
					show(.supplementary)
				}
			}
		} else {
			appDelegate.activityManager.invalidateSelectDocumentContainer()
		}
		
		timelineViewController?.setDocumentContainer(documentContainer, isNavigationBranch: isNavigationBranch, completion: completion)
	}
	
}

// MARK: TimelineDelegate

extension MainSplitViewController: TimelineDelegate {
	
	func documentSelectionDidChange(_: TimelineViewController, documentContainer: DocumentContainer, document: Document?, isNew: Bool, isNavigationBranch: Bool, animated: Bool) {
		// This prevents the same document from entering the backward stack more than once in a row.
		// If the first item on the backward stack equals the new document and there is nothing stored
		// in the last pin, we know they clicked on a document twice without one between.
		if let first = goBackwardStack.first, first.document == document && lastPin == nil{
			goBackwardStack.removeFirst()
		}
		
		if isNavigationBranch, let lastPin = lastPin, let document = document, lastPin.document != document {
			goBackwardStack.insert(lastPin, at: 0)
			goBackwardStack = Array(goBackwardStack.prefix(10))
			self.lastPin = nil
			goForwardStack.removeAll()
		}

		if let document = document {
			appDelegate.activityManager.selectingDocument(documentContainer, document)
			if animated {
				show(.secondary)
			} else {
				UIView.performWithoutAnimation {
					self.show(.secondary)
				}
			}

			lastPin = Pin(container: documentContainer, document: document)
		} else {
			appDelegate.activityManager.invalidateSelectDocument()
		}
		
		if let search = documentContainer as? Search {
			if search.searchText.isEmpty {
				editorViewController?.edit(nil, isNew: isNew)
			} else {
				editorViewController?.edit(document?.outline, isNew: isNew, searchText: search.searchText)
				if let document = document {
					pinWasVisited(Pin(container: documentContainer, document: document))
				}
			}
		} else {
			editorViewController?.edit(document?.outline, isNew: isNew)
			if let document = document {
				pinWasVisited(Pin(container: documentContainer, document: document))
			}
		}
	}

	func showGetInfo(_: TimelineViewController, outline: Outline) {
		showGetInfo(outline: outline)
	}
	
	func exportPDFDoc(_: TimelineViewController, outline: Outline) {
		exportPDFDocForOutline(outline)
	}
	
	func exportPDFList(_: TimelineViewController, outline: Outline) {
		exportPDFListForOutline(outline)
	}
	
	func exportMarkdownDoc(_: TimelineViewController, outline: Outline) {
		exportMarkdownDocForOutline(outline)
	}
	
	func exportMarkdownList(_: TimelineViewController, outline: Outline) {
		exportMarkdownListForOutline(outline)
	}
	
	func exportOPML(_: TimelineViewController, outline: Outline) {
		exportOPMLForOutline(outline)
	}
	
}

// MARK: EditorDelegate

extension MainSplitViewController: EditorDelegate {
	var editorViewControllerIsGoBackUnavailable: Bool {
		return isGoBackwardOneUnavailable
	}
	
	var editorViewControllerIsGoForwardUnavailable: Bool {
		return isGoForwardOneUnavailable
	}
	
	var editorViewControllerGoBackwardStack: [Pin] {
		return goBackwardStack
	}
	
	var editorViewControllerGoForwardStack: [Pin] {
		return goForwardStack
	}
	
	func goBackward(_: EditorViewController, to: Int) {
		goBackward(to: to)
	}
	
	func goForward(_: EditorViewController, to: Int) {
		goForward(to: to)
	}
	
	
	func createOutline(_: EditorViewController, title: String) -> Outline? {
		return timelineViewController?.createOutline(title: title)
	}
	
	func validateToolbar(_: EditorViewController) {
		validateToolbar()
	}

	func showGetInfo(_: EditorViewController, outline: Outline) {
		showGetInfo(outline: outline)
	}
	
	func exportPDFDoc(_: EditorViewController, outline: Outline) {
		exportPDFDocForOutline(outline)
	}
	
	func exportPDFList(_: EditorViewController, outline: Outline) {
		exportPDFListForOutline(outline)
	}
	
	func exportMarkdownDoc(_: EditorViewController, outline: Outline) {
		exportMarkdownDocForOutline(outline)
	}
	
	func exportMarkdownList(_: EditorViewController, outline: Outline) {
		exportMarkdownListForOutline(outline)
	}
	
	func exportOPML(_: EditorViewController, outline: Outline) {
		exportOPMLForOutline(outline)
	}

}

// MARK: UISplitViewControllerDelegate

extension MainSplitViewController: UISplitViewControllerDelegate {
	
	func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
		switch proposedTopColumn {
		case .supplementary:
			if timelineViewController?.documentContainer != nil {
				return .supplementary
			} else {
				return .primary
			}
		case .secondary:
			if editorViewController?.outline != nil {
				return .secondary
			} else {
				if timelineViewController?.documentContainer != nil {
					return .supplementary
				} else {
					return .primary
				}
			}
		default:
			return .primary
		}
	}
	
}

// MARK: UINavigationControllerDelegate

extension MainSplitViewController: UINavigationControllerDelegate {
	
	func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
		if UIApplication.shared.applicationState == .background {
			return
		}
		
		defer {
			if let mainController = viewController as? MainControllerIdentifiable {
				lastMainControllerToAppear = mainController.mainControllerIdentifer
			} else if let mainController = (viewController as? UINavigationController)?.topViewController as? MainControllerIdentifiable {
				lastMainControllerToAppear = mainController.mainControllerIdentifer
			}
		}

		// If we are showing the Feeds and only the feeds start clearing stuff
		if isCollapsed && viewController === sidebarViewController && lastMainControllerToAppear == .timeline {
			appDelegate.activityManager.invalidateSelectDocumentContainer()
			sidebarViewController?.selectDocumentContainer(nil, isNavigationBranch: false, animated: false)
			return
		}

		if isCollapsed && viewController === timelineViewController && lastMainControllerToAppear == .editor {
			appDelegate.activityManager.invalidateSelectDocument()
			timelineViewController?.selectDocument(nil, isNavigationBranch: false, animated: false)
			return
		}
	}
	
}

// MARK: OpenQuicklyViewControllerDelegate

extension MainSplitViewController: OpenQuicklyViewControllerDelegate {
	
	func quicklyOpenDocument(documentID: EntityID) {
		handleDocument(documentID, isNavigationBranch: true)
	}
	
}

// MARK: Helpers

extension MainSplitViewController {
	
	private func handleSelectDocument(_ document: Document, isNavigationBranch: Bool) {
		// This is done because the restore state navigation used to rely on the fact that
		// the TimeliniewController used a diffable datasource that didn't complete until after
		// some navigation had occurred. Changing this assumption broke state restoration
		// on the iPhone.
		//
		// When TimelineViewController was rewritten without diffable datasources, was when this
		// assumption was broken. Rather than rewrite how we handle navigation (which would
		// not be easy. SidebarViewController still uses a diffable datasource), we made it
		// look like it still works the same way by dispatching to the next run loop to occur.
		//
		// Someday this should be refactored. How the UINavigationControllerDelegate works would
		// be the main challenge.
		DispatchQueue.main.async {
			self.timelineViewController?.selectDocument(document, isNavigationBranch: isNavigationBranch, animated: false)
			self.lastMainControllerToAppear = .editor
			self.validateToolbar()
		}
	}
	
	private func selectDefaultDocumentContainerIfNecessary(completion: @escaping () -> Void) {
		guard sidebarViewController?.selectedAccount == nil else {
			completion()
			return
		}

		selectDefaultDocumentContainer(completion: completion)
	}
	
	private func selectDefaultDocumentContainer(completion: @escaping () -> Void) {
		let accountID = AppDefaults.shared.lastSelectedAccountID
		
		guard let account = AccountManager.shared.findAccount(accountID: accountID) ?? AccountManager.shared.activeAccounts.first else {
			completion()
			return
		}
		
		let documentContainer = account.documentContainers[0]
		
		sidebarViewController?.selectDocumentContainer(documentContainer, isNavigationBranch: true, animated: true) {
			completion()
		}
	}
	
	private func cleanUpNavigationStacks() {
		let allDocumentIDs = AccountManager.shared.activeDocuments.map { $0.id }
		
		var replacementGoBackwardStack = [Pin]()
		for pin in goBackwardStack {
			if let documentID = pin.documentID {
				if allDocumentIDs.contains(documentID) {
					replacementGoBackwardStack.append(pin)
				}
			} else {
				replacementGoBackwardStack.append(pin)
			}
		}
		goBackwardStack = replacementGoBackwardStack
		
		var replacementGoForwardStack = [Pin]()
		for pin in goForwardStack {
			if let documentID = pin.documentID {
				if allDocumentIDs.contains(documentID) {
					replacementGoForwardStack.append(pin)
				}
			} else {
				replacementGoForwardStack.append(pin)
			}
		}
		goForwardStack = replacementGoForwardStack
		
		if let lastPinDocumentID = lastPin?.documentID, !allDocumentIDs.contains(lastPinDocumentID) {
			self.lastPin = nil
		}
	}
	
	private func goBackward(to: Int) {
		guard to < goBackwardStack.count else { return }
		
		if let lastPin = lastPin {
			goForwardStack.insert(lastPin, at: 0)
		}
		
		for _ in 0..<to {
			let pin = goBackwardStack.removeFirst()
			goForwardStack.insert(pin, at: 0)
		}
		
		let pin = goBackwardStack.removeFirst()
		lastPin = pin
		sidebarViewController?.selectDocumentContainer(pin.container, isNavigationBranch: false, animated: false) {
			self.timelineViewController?.selectDocument(pin.document, isNavigationBranch: false, animated: false)
		}
	}
	
	private func goForward(to:  Int) {
		guard to < goForwardStack.count else { return }

		if let lastPin = lastPin {
			goBackwardStack.insert(lastPin, at: 0)
		}
		
		for _ in 0..<to {
			let pin = goForwardStack.removeFirst()
			goBackwardStack.insert(pin, at: 0)
		}
		
		let pin = goForwardStack.removeFirst()
		sidebarViewController?.selectDocumentContainer(pin.container, isNavigationBranch: false, animated: false) {
			self.timelineViewController?.selectDocument(pin.document, isNavigationBranch: false, animated: false)
		}
	}
	
}

#if targetEnvironment(macCatalyst)

extension MainSplitViewController: NSToolbarDelegate {
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return [
			.toggleSidebar,
			.flexibleSpace,
			.newOutline,
			.supplementarySidebarTrackingSeparatorItemIdentifier,
			.insertImage,
			.link,
			.boldface,
			.italic,
			.space,
			.collaborate,
			.share,
			.flexibleSpace,
			.navigation,
			.space,
			.toggleOutlineFilter,
		]
	}
	
	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return [
			.sync,
			.toggleSidebar,
			.supplementarySidebarTrackingSeparatorItemIdentifier,
			.importOPML,
			.newOutline,
			.navigation,
			.insertImage,
			.link,
			.boldface,
			.italic,
			.toggleOutlineNotesHidden,
			.toggleOutlineFilter,
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
		case .importOPML:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return false
			}
			item.image = AppAssets.importDocument.symbolSizedForCatalyst()
			item.label = L10n.importOPML
			item.toolTip = L10n.importOPML
			item.isBordered = true
			item.action = #selector(importOPML)
			item.target = self
			toolbarItem = item
		case .newOutline:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return false
			}
			item.image = AppAssets.createEntity.symbolSizedForCatalyst()
			item.label = L10n.newOutline
			item.toolTip = L10n.newOutline
			item.isBordered = true
			item.action = #selector(createOutline(_:))
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
		case .navigation:
			let groupItem = NSToolbarItemGroup(itemIdentifier: .navigation)
			groupItem.visibilityPriority = .high
			groupItem.controlRepresentation = .expanded
			groupItem.label = L10n.navigation
			
			let goBackwardItem = ValidatingMenuToolbarItem(itemIdentifier: .goBackward)
			
			goBackwardItem.checkForUnavailable = { [weak self] toolbarItem in
				guard let self = self else { return true }
				var backwardItems = [UIAction]()
				for (index, pin) in self.goBackwardStack.enumerated() {
					backwardItems.append(UIAction(title: pin.document?.title ?? L10n.noTitle) { [weak self] _ in
						DispatchQueue.main.async {
							self?.goBackward(to: index)
						}
					})
				}
				toolbarItem.itemMenu = UIMenu(title: "", children: backwardItems)
				
				return self.isGoBackwardOneUnavailable
			}
			
			goBackwardItem.image = AppAssets.goBackward.symbolSizedForCatalyst()
			goBackwardItem.label = L10n.goBackward
			goBackwardItem.toolTip = L10n.goBackward
			goBackwardItem.isBordered = true
			goBackwardItem.action = #selector(goBackwardOne(_:))
			goBackwardItem.target = self
			goBackwardItem.showsIndicator = false

			let goForwardItem = ValidatingMenuToolbarItem(itemIdentifier: .goForward)
			
			goForwardItem.checkForUnavailable = { [weak self] toolbarItem in
				guard let self = self else { return true }
				var forwardItems = [UIAction]()
				for (index, pin) in self.goForwardStack.enumerated() {
					forwardItems.append(UIAction(title: pin.document?.title ?? L10n.noTitle) { [weak self] _ in
						DispatchQueue.main.async {
							self?.goForward(to: index)
						}
					})
				}
				toolbarItem.itemMenu = UIMenu(title: "", children: forwardItems)
				
				return self.isGoForwardOneUnavailable
			}
			
			goForwardItem.image = AppAssets.goForward.symbolSizedForCatalyst()
			goForwardItem.label = L10n.goForward
			goForwardItem.toolTip = L10n.goForward
			goForwardItem.isBordered = true
			goForwardItem.action = #selector(goForwardOne(_:))
			goForwardItem.target = self
			goForwardItem.showsIndicator = false
			
			groupItem.subitems = [goBackwardItem, goForwardItem]
			
			toolbarItem = groupItem
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

extension MainSplitViewController: UIActivityItemsConfigurationReading {
	
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

