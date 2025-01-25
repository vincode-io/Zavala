//
//  MainSplitViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import SwiftUI
import CoreSpotlight
import SafariServices
import VinOutlineKit
import VinUtility

extension Selector {
	static let goBackwardOne = #selector(MainSplitViewController.goBackwardOne(_:))
	static let goForwardOne = #selector(MainSplitViewController.goForwardOne(_:))
}

protocol MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { get }
}

enum MainControllerIdentifier {
	case none
	case collections
	case documents
	case editor
}

class MainSplitViewController: UISplitViewController, MainCoordinator, MainCoordinatorResponder, FileActionResponder {
	
	struct UserInfoKeys {
		static let goBackwardStack = "goBackwardStack"
		static let goForwardStack = "goForwardStack"
		static let collectionsWidth = "collectionsWidth"
		static let documentsWidth = "documentsWidth"
		static let collectionsExpandedState = "collectionsExpandedState"
		static let documentSortOrderState = "documentSortOrders"
	}
	
	weak var sceneDelegate: SceneDelegate?

	var stateRestorationActivity: NSUserActivity {
		let activity = activityManager.stateRestorationActivity
		var userInfo = activity.userInfo == nil ? [AnyHashable: Any]() : activity.userInfo

		userInfo![UserInfoKeys.goBackwardStack] = goBackwardStack.map { $0.userInfo }
		userInfo![UserInfoKeys.goForwardStack] = goForwardStack.map { $0.userInfo }

		if traitCollection.userInterfaceIdiom == .mac {
			userInfo![UserInfoKeys.collectionsWidth] = primaryColumnWidth
			userInfo![UserInfoKeys.documentsWidth] = supplementaryColumnWidth
		}

		userInfo![UserInfoKeys.collectionsExpandedState] = collectionsViewController?.expandedState
		userInfo![UserInfoKeys.documentSortOrderState] = documentsViewController?.documentSortOrderState

		activity.userInfo = userInfo
		return activity
	}
	
	var selectedDocuments: [Document] {
		return documentsViewController?.selectedDocuments ?? []
	}
	
	var selectedDocumentContainers: [DocumentContainer]? {
		return collectionsViewController?.selectedDocumentContainers
	}
    
    var selectedTags: [Tag]? {
        return collectionsViewController?.selectedTags
    }
	
	var selectedOutlines: [Outline]? {
		return documentsViewController?.selectedDocuments.compactMap({ $0.outline })
	}

	var editorViewController: EditorViewController? {
		viewController(for: .secondary) as? EditorViewController
	}
	
    private let activityManager = ActivityManager()
	
	private var collectionsViewController: CollectionsViewController? {
		return viewController(for: .primary) as? CollectionsViewController
	}
	
	private var documentsViewController: DocumentsViewController? {
		viewController(for: .supplementary) as? DocumentsViewController
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
			maximumPrimaryColumnWidth = 250
			maximumSupplementaryColumnWidth = 350
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
		collectionsViewController?.navigationController?.delegate = self
		collectionsViewController?.delegate = self
		documentsViewController?.navigationController?.delegate = self
		documentsViewController?.delegate = self
		collectionsViewController?.startUp()
		editorViewController?.delegate = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountDocumentsDidChange(_:)), name: .AccountDocumentsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountManagerAccountsDidChange(_:)), name: .AccountManagerAccountsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountMetadataDidChange(_:)), name: .AccountMetadataDidChange, object: nil)
	}
	
	func handle(_ activity: NSUserActivity, isNavigationBranch: Bool) async {
		guard let userInfo = activity.userInfo else { return }
		await handle(userInfo, isNavigationBranch: isNavigationBranch)
	}

	func handle(_ userInfo: [AnyHashable: Any], isNavigationBranch: Bool) async {
		if let searchIdentifier = userInfo[CSSearchableItemActivityIdentifier] as? String, let entityID = EntityID(description: searchIdentifier) {
			await handleDocument(entityID, isNavigationBranch: isNavigationBranch)
			return
		}
		
		if let goBackwardStackUserInfos = userInfo[UserInfoKeys.goBackwardStack] as? [Any] {
			goBackwardStack = goBackwardStackUserInfos.compactMap { Pin(accountManager: appDelegate.accountManager, userInfo: $0) }
		}

		if let goForwardStackUserInfos = userInfo[UserInfoKeys.goForwardStack] as? [Any] {
			goForwardStack = goForwardStackUserInfos.compactMap { Pin(accountManager: appDelegate.accountManager, userInfo: $0) }
		}

		cleanUpNavigationStacks()
		
		if let collectionsWidth = userInfo[UserInfoKeys.collectionsWidth] as? CGFloat, collectionsWidth != 0 {
			preferredPrimaryColumnWidth = collectionsWidth
		}
		
		if let documentsWidth = userInfo[UserInfoKeys.documentsWidth] as? CGFloat, documentsWidth != 0 {
			preferredSupplementaryColumnWidth = documentsWidth
		}
		
		if let collectionsExpandedState = userInfo[UserInfoKeys.collectionsExpandedState] as? [[AnyHashable: AnyHashable]] {
			collectionsViewController?.expandedState = collectionsExpandedState
		}

		if let documentSortOrderState = userInfo[UserInfoKeys.documentSortOrderState] as? [[AnyHashable: AnyHashable]: [AnyHashable: AnyHashable]] {
			documentsViewController?.documentSortOrderState = documentSortOrderState
		}

		let pin = Pin(accountManager: appDelegate.accountManager, userInfo: userInfo[Pin.UserInfoKeys.pin])
		
		guard let documentContainers = pin.containers, !documentContainers.isEmpty else {
			return
		}
		
		await collectionsViewController?.selectDocumentContainers(documentContainers, isNavigationBranch: isNavigationBranch, animated: false)
		lastMainControllerToAppear = .documents

		guard let document = pin.document else {
			return
		}
		
		handleSelectDocument(document, isNavigationBranch: isNavigationBranch)
	}
	
	func handleDocument(_ entityID: EntityID, isNavigationBranch: Bool) async {
		guard let account = appDelegate.accountManager.findAccount(accountID: entityID.accountID),
			  let document = account.findDocument(entityID) else {
			presentError(title: .documentNotFoundTitle, message: .documentNotFoundMessage)
			return
		}
		
		let selectRow = entityID.isRow ? entityID : nil
		
		if let collectionsTags = selectedTags, document.hasAnyTag(collectionsTags) {
			self.handleSelectDocument(document, selectRow: selectRow, isNavigationBranch: isNavigationBranch)
		} else if document.tagCount == 1, let tag = document.tags?.first {
			await collectionsViewController?.selectDocumentContainers([TagDocuments(account: account, tag: tag)], isNavigationBranch: true, animated: false)
			handleSelectDocument(document, selectRow: selectRow, isNavigationBranch: isNavigationBranch)
		} else {
			await collectionsViewController?.selectDocumentContainers([AllDocuments(account: account)], isNavigationBranch: true, animated: false)
			handleSelectDocument(document, selectRow: selectRow, isNavigationBranch: isNavigationBranch)
		}
	}
	
	func handlePin(_ pin: Pin) async {
		guard let documentContainers = pin.containers else { return }
		await collectionsViewController?.selectDocumentContainers(documentContainers, isNavigationBranch: true, animated: false)
		documentsViewController?.selectDocument(pin.document, isNavigationBranch: true, animated: false)
	}
	
	func importOPMLs(urls: [URL]) {
		Task {
			await selectDefaultDocumentContainerIfNecessary()
			documentsViewController?.importOPMLs(urls: urls)
		}
	}
	
	func validateToolbar() {
		self.sceneDelegate?.validateToolbar()
	}
	
	// MARK: Actions
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .sync:
			return appDelegate.accountManager.isSyncAvailable
		case .manageSharing:
			return !isManageSharingUnavailable
		case .share, .showGetInfo, .exportPDFDocs, .exportPDFLists, .exportMarkdownDocs, .exportMarkdownLists, .exportOPMLs, .printDocs, .printLists:
			return !isOutlineFunctionsUnavailable
		case .goBackwardOne:
			return !goBackwardStack.isEmpty
		case .goForwardOne:
			return !goForwardStack.isEmpty
		case .copyDocumentLink:
			return selectedDocuments.count == 1
		default:
			return super.canPerformAction(action, withSender: sender)
		}
	}
	
	@objc func sync(_ sender: Any?) {
		Task {
			await appDelegate.accountManager.sync()
		}
	}
	
	@objc func createOutline(_ sender: Any?) {
		Task {
			await selectDefaultDocumentContainerIfNecessary()
			documentsViewController?.createOutline(animated: false)
		}
	}
	
	@objc func importOPML(_ sender: Any?) {
		Task {
			await selectDefaultDocumentContainerIfNecessary()
			documentsViewController?.importOPML()
		}
	}
	
	@objc func goBackwardOne(_ sender: Any?) {
		goBackward(to: 0)
	}

	@objc func goForwardOne(_ sender: Any?) {
		goForward(to: 0)
	}

	@objc func exportPDFDocs(_ sender: Any?) {
		exportPDFDocs()
	}

	@objc func exportPDFLists(_ sender: Any?) {
		exportPDFLists()
	}

	@objc func exportMarkdownDocs(_ sender: Any?) {
		exportMarkdownDocs()
	}

	@objc func exportMarkdownLists(_ sender: Any?) {
		exportMarkdownLists()
	}

	@objc func exportOPMLs(_ sender: Any?) {
		exportOPMLs()
	}

	@objc func printDocs(_ sender: Any?) {
		printDocs()
	}

	@objc func printLists(_ sender: Any?) {
		printLists()
	}

	@objc func showGetInfo(_ sender: Any?) {
		showGetInfo()
	}

	@objc func share(_ sender: Any?) {
		documentsViewController?.share()
	}
	
	@objc func manageSharing(_ sender: Any?) {
		documentsViewController?.manageSharing()
	}
	
	@objc func showSettings(_ sender: Any?) {
		showSettings()
	}
	
	@objc func copyDocumentLink(_ sender: Any?) {
		copyDocumentLink()
	}
	
	@objc func showOpenQuickly(_ sender: Any?) {
		if traitCollection.userInterfaceIdiom == .mac {
		
			let openQuicklyViewController = UIStoryboard.openQuickly.instantiateController(ofType: MainOpenQuicklyViewController.self)
			openQuicklyViewController.preferredContentSize = CGSize(width: 300, height: 60)
			openQuicklyViewController.delegate = self
			present(openQuicklyViewController, animated: true)
		
		} else {

			let outlineGetInfoNavViewController = UIStoryboard.openQuickly.instantiateViewController(withIdentifier: "OpenQuicklyViewControllerNav") as! UINavigationController
			outlineGetInfoNavViewController.preferredContentSize = CGSize(width: 400, height: 100)
			outlineGetInfoNavViewController.modalPresentationStyle = .formSheet
			let outlineGetInfoViewController = outlineGetInfoNavViewController.topViewController as! OpenQuicklyViewController
			outlineGetInfoViewController.delegate = self
			present(outlineGetInfoNavViewController, animated: true)
			
		}
	}
	
}

// MARK: CollectionsDelegate

extension MainSplitViewController: CollectionsDelegate {
	
	func documentContainerSelectionsDidChange(_: CollectionsViewController,
											  documentContainers: [DocumentContainer],
											  isNavigationBranch: Bool,
											  animated: Bool) async {
		
		// The window might not be quite available at launch, so put a slight delay in to help it get there
		Task { @MainActor in
			self.view.window?.windowScene?.title = documentContainers.title
		}
		
		if isNavigationBranch, let lastPin {
			goBackwardStack.insert(lastPin, at: 0)
			goBackwardStack = Array(goBackwardStack.prefix(10))
			self.lastPin = nil
			goForwardStack.removeAll()
		}

        if let accountID = documentContainers.first?.account?.id.accountID {
			AppDefaults.shared.lastSelectedAccountID = accountID
		}
		
        if !documentContainers.isEmpty {
            activityManager.selectingDocumentContainers(documentContainers)
			
			// In theory, we shouldn't need to do anything with the supplementary view when we aren't
			// navigating because we should be using navigation buttons and already be looking at the
			// editor view.
			if isNavigationBranch {
				if animated {
					show(.supplementary)
				} else {
					UIView.performWithoutAnimation {
						show(.supplementary)
					}
				}
			}
		} else {
			activityManager.invalidateSelectDocumentContainers()
		}
		
		await documentsViewController?.setDocumentContainers(documentContainers, isNavigationBranch: isNavigationBranch)
	}

}

// MARK: DocumentsDelegate

extension MainSplitViewController: DocumentsDelegate {
	
	func documentSelectionDidChange(_: DocumentsViewController,
									documentContainers: [DocumentContainer],
									documents: [Document],
									selectRow: EntityID?,
									isNew: Bool,
									isNavigationBranch: Bool,
									animated: Bool) {
		
		// Don't overlay the Document Container title if we are just switching Document Containers
		if !documents.isEmpty {
			view.window?.windowScene?.title = documents.title
		}
		
		guard documents.count == 1, let document = documents.first else {
			activityManager.invalidateSelectDocument()
			editorViewController?.edit(nil, isNew: isNew)
			if documents.isEmpty {
				editorViewController?.showMessage(.noSelectionLabel)
			} else {
				editorViewController?.showMessage(.multipleSelectionsLabel)
			}
			return
		}
		
		// This prevents the same document from entering the backward stack more than once in a row.
		// If the first item on the backward stack equals the new document and there is nothing stored
		// in the last pin, we know they clicked on a document twice without one between.
		if let first = goBackwardStack.first, first.document == document && lastPin == nil{
			goBackwardStack.removeFirst()
		}
		
		if isNavigationBranch, let lastPin, lastPin.document != document {
			goBackwardStack.insert(lastPin, at: 0)
			goBackwardStack = Array(goBackwardStack.prefix(10))
			self.lastPin = nil
			goForwardStack.removeAll()
		}

		activityManager.selectingDocument(documentContainers, document)
		
		if animated {
			show(.secondary)
		} else {
			UIView.performWithoutAnimation {
				self.show(.secondary)
			}
		}

		lastPin = Pin(accountManager: appDelegate.accountManager, containers: documentContainers, document: document)
		
        if let search = documentContainers.first as? Search {
			if search.searchText.isEmpty {
				editorViewController?.edit(nil, isNew: isNew)
			} else {
				editorViewController?.edit(document.outline, isNew: isNew, searchText: search.searchText)
				pinWasVisited(Pin(accountManager: appDelegate.accountManager, containers: documentContainers, document: document))
			}
		} else {
			editorViewController?.edit(document.outline, selectRow: selectRow, isNew: isNew)
			pinWasVisited(Pin(accountManager: appDelegate.accountManager, containers: documentContainers, document: document))
		}
	}

	func showGetInfo(_: DocumentsViewController, outline: Outline) {
		showGetInfo(outline: outline)
	}
	
	func exportPDFDocs(_: DocumentsViewController, outlines: [Outline]) {
		exportPDFDocsForOutlines(outlines)
	}
	
	func exportPDFLists(_: DocumentsViewController, outlines: [Outline]) {
		exportPDFListsForOutlines(outlines)
	}
	
	func exportMarkdownDocs(_: DocumentsViewController, outlines: [Outline]) {
		exportMarkdownDocsForOutlines(outlines)
	}
	
	func exportMarkdownLists(_: DocumentsViewController, outlines: [Outline]) {
		exportMarkdownListsForOutlines(outlines)
	}
	
	func exportOPMLs(_: DocumentsViewController, outlines: [Outline]) {
		exportOPMLsForOutlines(outlines)
	}
	
	func printDocs(_: DocumentsViewController, outlines: [Outline]) {
		printDocsForOutlines(outlines)
	}
	
	func printLists(_: DocumentsViewController, outlines: [Outline]) {
		printListsForOutlines(outlines)
	}
	
}

// MARK: EditorDelegate

extension MainSplitViewController: EditorDelegate {
	
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
	
	func createNewOutline(_: EditorViewController, title: String) -> Outline? {
        return documentsViewController?.createOutlineDocument(title: title)?.outline
	}
	
	func validateToolbar(_: EditorViewController) {
		validateToolbar()
	}

	func showGetInfo(_: EditorViewController, outline: Outline) {
		showGetInfo(outline: outline)
	}
	
	func exportPDFDoc(_: EditorViewController, outline: Outline) {
		exportPDFDocsForOutlines([outline])
	}
	
	func exportPDFList(_: EditorViewController, outline: Outline) {
		exportPDFListsForOutlines([outline])
	}
	
	func exportMarkdownDoc(_: EditorViewController, outline: Outline) {
		exportMarkdownDocsForOutlines([outline])
	}
	
	func exportMarkdownList(_: EditorViewController, outline: Outline) {
		exportMarkdownListsForOutlines([outline])
	}
	
	func exportOPML(_: EditorViewController, outline: Outline) {
		exportOPMLsForOutlines([outline])
	}

	func printDoc(_: EditorViewController, outline: Outline) {
		printDocsForOutlines([outline])
	}
	
	func printList(_: EditorViewController, outline: Outline) {
		printListsForOutlines([outline])
	}
	
	func zoomImage(_: EditorViewController, image: UIImage, transitioningDelegate: UIViewControllerTransitioningDelegate) {
		if traitCollection.userInterfaceIdiom == .mac {
			let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.viewImage)
			if let pngData = image.pngData() {
				activity.userInfo = [UIImage.UserInfoKeys.pngData: pngData]
			}
			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
		} else {
			let imageVC = UIStoryboard.image.instantiateController(ofType: ImageViewController.self)
			imageVC.image = image
			imageVC.modalPresentationStyle = .currentContext
			imageVC.transitioningDelegate = transitioningDelegate
			present(imageVC, animated: true)
		}
	}

}

// MARK: UISplitViewControllerDelegate

extension MainSplitViewController: UISplitViewControllerDelegate {
	
	func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
		switch proposedTopColumn {
		case .supplementary:
            if let containers = documentsViewController?.documentContainers, !containers.isEmpty {
				return .supplementary
			} else {
				return .primary
			}
		case .secondary:
			if editorViewController?.outline != nil {
				return .secondary
			} else {
                if let containers = documentsViewController?.documentContainers, !containers.isEmpty {
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
		if isCollapsed && viewController === collectionsViewController && lastMainControllerToAppear == .documents {
			Task {
				await collectionsViewController?.selectDocumentContainers(nil, isNavigationBranch: false, animated: false)
			}
			return
		}

		if isCollapsed && viewController === documentsViewController && lastMainControllerToAppear == .editor {
			activityManager.invalidateSelectDocument()
			documentsViewController?.selectDocument(nil, isNavigationBranch: false, animated: false)
			return
		}
	}
	
}

// MARK: OpenQuicklyViewControllerDelegate

extension MainSplitViewController: OpenQuicklyViewControllerDelegate {
	
	func quicklyOpenDocument(documentID: EntityID) {
		Task {
			await handleDocument(documentID, isNavigationBranch: true)
		}
	}
	
}

// MARK: Helpers

private extension MainSplitViewController {
	
	func handleSelectDocument(_ document: Document, selectRow: EntityID? = nil, isNavigationBranch: Bool) {
		self.documentsViewController?.selectDocument(document, selectRow: selectRow, isNavigationBranch: isNavigationBranch, animated: false)
		self.lastMainControllerToAppear = .editor
		self.validateToolbar()
	}
	
	func selectDefaultDocumentContainerIfNecessary() async {
		guard collectionsViewController?.selectedAccount == nil else {
			return
		}

		await selectDefaultDocumentContainer()
	}
	
	func selectDefaultDocumentContainer() async {
		let accountID = AppDefaults.shared.lastSelectedAccountID
		
		guard let account = appDelegate.accountManager.findAccount(accountID: accountID) ?? appDelegate.accountManager.activeAccounts.first else {
			return
		}
		
		let documentContainer = account.documentContainers[0]
		
		await collectionsViewController?.selectDocumentContainers([documentContainer], isNavigationBranch: true, animated: true)
	}
	
	func cleanUpNavigationStacks() {
		let allDocumentIDs = appDelegate.accountManager.activeDocuments.map { $0.id }
		
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
	
	func goBackward(to: Int) {
		Task {
			guard to < goBackwardStack.count else { return }
			
			if let lastPin {
				goForwardStack.insert(lastPin, at: 0)
			}
			
			for _ in 0..<to {
				let pin = goBackwardStack.removeFirst()
				goForwardStack.insert(pin, at: 0)
			}
			
			let pin = goBackwardStack.removeFirst()
			lastPin = pin
			
			await collectionsViewController?.selectDocumentContainers(pin.containers, isNavigationBranch: false, animated: false)
			documentsViewController?.selectDocument(pin.document, isNavigationBranch: false, animated: false)
		}
	}
	
	func goForward(to:  Int) {
		Task {
			guard to < goForwardStack.count else { return }

			if let lastPin {
				goBackwardStack.insert(lastPin, at: 0)
			}
			
			for _ in 0..<to {
				let pin = goForwardStack.removeFirst()
				goBackwardStack.insert(pin, at: 0)
			}
			
			let pin = goForwardStack.removeFirst()
		
			await collectionsViewController?.selectDocumentContainers(pin.containers, isNavigationBranch: false, animated: false)
			documentsViewController?.selectDocument(pin.document, isNavigationBranch: false, animated: false)
		}
	}
	
}

#if targetEnvironment(macCatalyst)

extension MainSplitViewController: NSToolbarDelegate {
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return [
			.toggleSidebar,
			.primarySidebarTrackingSeparatorItemIdentifier,
			.navigation,
			.flexibleSpace,
			.sortDocuments,
			.newOutline,
			.supplementarySidebarTrackingSeparatorItemIdentifier,
			.moveLeft,
			.moveRight,
			.space,
			.insertImage,
			.link,
			.boldface,
			.italic,
			.flexibleSpace,
			.share,
			.space,
			.focus,
			.filter,
		]
	}
	
	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return [
			.sync,
			.toggleSidebar,
			.supplementarySidebarTrackingSeparatorItemIdentifier,
			.sortDocuments,
			.importOPML,
			.newOutline,
			.navigation,
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
		case .sync:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !appDelegate.accountManager.isSyncAvailable
			}
			item.image = .sync.symbolSizedForCatalyst()
			item.label = .syncControlLabel
			item.toolTip = .syncControlLabel
			item.isBordered = true
			item.action = .sync
			item.target = self
			toolbarItem = item
		case .sortDocuments:
			let item = ValidatingMenuToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				guard let currentSortOrder = self?.documentsViewController?.currentSortOrder else { return false }
				
				let sortByTitleAction = UIAction(title: .titleLabel) { _ in
					Task { @MainActor in
						UIApplication.shared.sendAction(.sortByTitle, to: nil, from: nil, for: nil)
					}
				}
				sortByTitleAction.state = currentSortOrder.field == .title ? .on : .off
				
				let sortByCreatedAction = UIAction(title: .createdControlLabel) { _ in
					Task { @MainActor in
						UIApplication.shared.sendAction(.sortByCreated, to: nil, from: nil, for: nil)
					}
				}
				sortByCreatedAction.state = currentSortOrder.field == .created ? .on : .off
				
				let sortByUpdatedAction = UIAction(title: .updatedControlLabel) { _ in
					Task { @MainActor in
						UIApplication.shared.sendAction(.sortByUpdated, to: nil, from: nil, for: nil)
					}
				}
				sortByUpdatedAction.state = currentSortOrder.field == .updated ? .on : .off
				
				let sortAscendingAction = UIAction(title: .ascendingControlLabel) { _ in
					Task { @MainActor in
						UIApplication.shared.sendAction(.sortAscending, to: nil, from: nil, for: nil)
					}
				}
				sortAscendingAction.state = currentSortOrder.ordered == .ascending ? .on : .off
				
				let sortDescendingAction = UIAction(title: .descendingControlLabel) { _ in
					Task { @MainActor in
						UIApplication.shared.sendAction(.sortDescending, to: nil, from: nil, for: nil)
					}
				}
				sortDescendingAction.state = currentSortOrder.ordered == .descending ? .on : .off
				
				let sortByMenu = UIMenu(title: "", options: .displayInline, children: [sortByTitleAction, sortByCreatedAction, sortByUpdatedAction])
				let sortOrderedMenu = UIMenu(title: "", options: .displayInline, children: [sortAscendingAction, sortDescendingAction])

				item.itemMenu = UIMenu(title: "", children: [sortByMenu, sortOrderedMenu])
				
				return self?.documentsViewController?.documentContainers?.count != 1
			}
			item.image = .sort.symbolSizedForCatalyst(pointSize: 15)
			item.label = .sortDocumentsControlLabel
			item.toolTip = .sortDocumentsControlLabel
			item.isBordered = true
			item.target = self
			item.showsIndicator = false
			toolbarItem = item
		case .importOPML:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return false
			}
			item.image = .importDocument.symbolSizedForCatalyst()
			item.label = .importOPMLControlLabel
			item.toolTip = .importOPMLControlLabel
			item.isBordered = true
			item.action = .importOPML
			toolbarItem = item
		case .newOutline:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return false
			}
			item.image = .createEntity.symbolSizedForCatalyst()
			item.label = .newOutlineControlLabel
			item.toolTip = .newOutlineControlLabel
			item.isBordered = true
			item.action = .createOutline
			toolbarItem = item
		case .insertImage:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !UIResponder.valid(action: .insertImage)
			}
			item.image = .insertImage.symbolSizedForCatalyst()
			item.label = .insertImageControlLabel
			item.toolTip = .insertImageControlLabel
			item.isBordered = true
			item.action = .insertImage
			toolbarItem = item
		case .navigation:
			let groupItem = NSToolbarItemGroup(itemIdentifier: .navigation)
			groupItem.visibilityPriority = .high
			groupItem.controlRepresentation = .expanded
			groupItem.label = .navigationControlLabel
			
			let goBackwardItem = ValidatingMenuToolbarItem(itemIdentifier: .goBackward)
			
			goBackwardItem.checkForUnavailable = { [weak self] toolbarItem in
				guard let self else { return true }
				var backwardItems = [UIAction]()
				for (index, pin) in self.goBackwardStack.enumerated() {
					backwardItems.append(UIAction(title: pin.document?.title ?? .noTitleLabel) { [weak self] _ in
						Task { @MainActor in
							self?.goBackward(to: index)
						}
					})
				}
				toolbarItem.itemMenu = UIMenu(title: "", children: backwardItems)
				
				return goBackwardStack.isEmpty
			}
			
			goBackwardItem.image = .goBackward.symbolSizedForCatalyst()
			goBackwardItem.label = .goBackwardControlLabel
			goBackwardItem.toolTip = .goBackwardControlLabel
			goBackwardItem.isBordered = true
			goBackwardItem.action = .goBackwardOne
			goBackwardItem.target = self
			goBackwardItem.showsIndicator = false

			let goForwardItem = ValidatingMenuToolbarItem(itemIdentifier: .goForward)
			
			goForwardItem.checkForUnavailable = { [weak self] toolbarItem in
				guard let self else { return true }
				var forwardItems = [UIAction]()
				for (index, pin) in self.goForwardStack.enumerated() {
					forwardItems.append(UIAction(title: pin.document?.title ?? .noTitleLabel) { [weak self] _ in
						Task { @MainActor in
							self?.goForward(to: index)
						}
					})
				}
				toolbarItem.itemMenu = UIMenu(title: "", children: forwardItems)
				
				return goForwardStack.isEmpty
			}
			
			goForwardItem.image = .goForward.symbolSizedForCatalyst()
			goForwardItem.label = .goForwardControlLabel
			goForwardItem.toolTip = .goForwardControlLabel
			goForwardItem.isBordered = true
			goForwardItem.action = .goForwardOne
			goForwardItem.target = self
			goForwardItem.showsIndicator = false
			
			groupItem.subitems = [goBackwardItem, goForwardItem]
			
			toolbarItem = groupItem
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
			item.action = .createOrDeleteNotes
			toolbarItem = item
		case .boldface:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				guard let self else { return true }
				if self.editorViewController?.isBoldToggledOn ?? false {
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
			item.checkForUnavailable = { _ in
				return !UIResponder.valid(action: .expandAllInOutline)
			}
			item.image = .expandAll.symbolSizedForCatalyst()
			item.label = .expandControlLabel
			item.toolTip = .expandAllInOutlineControlLabel
			item.isBordered = true
			item.action = .expandAllInOutline
			toolbarItem = item
		case .collapseAllInOutline:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !UIResponder.valid(action: .collapseAllInOutline)
			}
			item.image = .collapseAll.symbolSizedForCatalyst()
			item.label = .collapseControlLabel
			item.toolTip = .collapseAllInOutlineControlLabel
			item.isBordered = true
			item.action = .collapseAllInOutline
			toolbarItem = item
		case .moveLeft:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !UIResponder.valid(action: .moveCurrentRowsLeft)
			}
			item.image = .moveLeft.symbolSizedForCatalyst()
			item.label = .moveLeftControlLabel
			item.toolTip = .moveLeftControlLabel
			item.isBordered = true
			item.action = .moveCurrentRowsLeft
			toolbarItem = item
		case .moveRight:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !UIResponder.valid(action: .moveCurrentRowsRight)
			}
			item.image = .moveRight.symbolSizedForCatalyst()
			item.label = .moveRightControlLabel
			item.toolTip = .moveRightControlLabel
			item.isBordered = true
			item.action = .moveCurrentRowsRight
			toolbarItem = item
		case .moveUp:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !UIResponder.valid(action: .moveCurrentRowsUp)
			}
			item.image = .moveUp.symbolSizedForCatalyst()
			item.label = .moveUpControlLabel
			item.toolTip = .moveUpControlLabel
			item.isBordered = true
			item.action = .moveCurrentRowsUp
			toolbarItem = item
		case .moveDown:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !UIResponder.valid(action: .moveCurrentRowsDown)
			}
			item.image = .moveDown.symbolSizedForCatalyst()
			item.label = .moveDownControlLabel
			item.toolTip = .moveDownControlLabel
			item.isBordered = true
			item.action = .moveCurrentRowsDown
			toolbarItem = item
		case .focus:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				if UIResponder.valid(action: .focusOut) {
					item.image = .focusActive.symbolSizedForCatalyst(pointSize: 17, color: .accentColor)
					item.label = .focusOutControlLabel
					item.toolTip = .focusOutControlLabel
				} else {
					item.image = .focusInactive.symbolSizedForCatalyst(pointSize: 17)
					item.label = .focusInControlLabel
					item.toolTip = .focusInControlLabel
				}
				return !UIResponder.valid(action: .toggleFocus)
			}
			item.image = .focusInactive.symbolSizedForCatalyst()
			item.label = .focusInControlLabel
			item.toolTip = .focusInControlLabel
			item.isBordered = true
			item.action = .toggleFocus
			toolbarItem = item
		case .filter:
			let item = ValidatingMenuToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] item in
				guard let self else { return false }
				
				let isFilterOn = self.editorViewController?.isFilterOn ?? false
				
				if isFilterOn {
					item.image = .filterActive.symbolSizedForCatalyst(pointSize: 17, color: .accentColor)
				} else {
					item.image = .filterInactive.symbolSizedForCatalyst(pointSize: 17)
				}
				
				let turnFilterOnAction = UIAction() { _ in
					Task { @MainActor in
						UIApplication.shared.sendAction(.toggleFilterOn, to: nil, from: nil, for: nil)
					}
				}
				
				turnFilterOnAction.title = isFilterOn ? .turnFilterOffControlLabel : .turnFilterOnControlLabel
				
				let turnFilterOnMenu = UIMenu(title: "", options: .displayInline, children: [turnFilterOnAction])
				
				let filterCompletedAction = UIAction(title: .filterCompletedControlLabel) { _ in
					Task { @MainActor in
						UIApplication.shared.sendAction(.toggleCompletedFilter, to: nil, from: nil, for: nil)
					}
				}
				filterCompletedAction.state = self.editorViewController?.isCompletedFiltered ?? false ? .on : .off
				filterCompletedAction.attributes = isFilterOn ? [] : .disabled

				let filterNotesAction = UIAction(title: .filterNotesControlLabel) { _ in
					Task { @MainActor in
						UIApplication.shared.sendAction(.toggleNotesFilter, to: nil, from: nil, for: nil)
					}
				}
				filterNotesAction.state = self.editorViewController?.isNotesFiltered ?? false ? .on : .off
				filterNotesAction.attributes = isFilterOn ? [] : .disabled

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
			item.checkForUnavailable = { _ in
				return !UIResponder.valid(action: .printDocs)
			}
			item.image = .printDoc.symbolSizedForCatalyst()
			item.label = .printDocControlLabel
			item.toolTip = .printDocControlLabel
			item.isBordered = true
			item.action = .printDocs
			item.target = self
			toolbarItem = item
		case .printList:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !UIResponder.valid(action: .printLists)
			}
			item.image = .printList.symbolSizedForCatalyst()
			item.label = .printListControlLabel
			item.toolTip = .printListControlLabel
			item.isBordered = true
			item.action = .printLists
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
			item.checkForUnavailable = { _ in
				return !UIResponder.valid(action: .showGetInfo)
			}
			item.image = .getInfo.symbolSizedForCatalyst()
			item.label = .getInfoControlLabel
			item.toolTip = .getInfoControlLabel
			item.isBordered = true
			item.action = .showGetInfo
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

