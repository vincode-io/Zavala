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

enum MainSplitViewControllerError: LocalizedError {
	case unknownOutline
	var errorDescription: String? {
		return L10n.unknownOutline
	}
}

class MainSplitViewController: UISplitViewController, MainCoordinator {
	
	private struct Navigate {
		let container: DocumentContainer
		let document: Document
	}

	weak var sceneDelegate: SceneDelegate?

	var stateRestorationActivity: NSUserActivity {
		let activity = activityManager.stateRestorationActivity
		if traitCollection.userInterfaceIdiom == .mac {
			var userInfo = activity.userInfo == nil ? [AnyHashable: Any]() : activity.userInfo
			userInfo![UserInfoKeys.sidebarWidth] = primaryColumnWidth
			userInfo![UserInfoKeys.timelineWidth] = supplementaryColumnWidth
			activity.userInfo = userInfo
		}
		return activity
	}
	
	var isDeleteEntityUnavailable: Bool {
		return (editorViewController?.isOutlineFunctionsUnavailable ?? true) &&
			(editorViewController?.isDeleteCurrentRowUnavailable ?? true) 
	}

	var activityManager = ActivityManager()
	
	var currentTag: Tag? {
		return sidebarViewController?.currentTag
	}

	var editorViewController: EditorViewController? {
		viewController(for: .secondary) as? EditorViewController
	}
	
	private var sidebarViewController: SidebarViewController? {
		return viewController(for: .primary) as? SidebarViewController
	}
	
	private var timelineViewController: TimelineViewController? {
		viewController(for: .supplementary) as? TimelineViewController
	}
	
	private var lastMainControllerToAppear = MainControllerIdentifier.none
	
	private var lastNavigate: Navigate?
	private var goBackwardStack = [Navigate]()
	private var goForwardStack = [Navigate]()

	private var isGoBackwardUnavailable: Bool {
		return goBackwardStack.isEmpty
	}
	
	private var isGoForwardUnavailable: Bool {
		return goForwardStack.isEmpty
	}
	
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
		let allDocuments = AccountManager.shared.documents
		
		var replacementGoBackwardStack = [Navigate]()
		for navigate in goBackwardStack {
			if allDocuments.contains(navigate.document) {
				replacementGoBackwardStack.append(navigate)
			}
		}
		goBackwardStack = replacementGoBackwardStack
		
		var replacementGoForwardStack = [Navigate]()
		for navigate in goForwardStack {
			if allDocuments.contains(navigate.document) {
				replacementGoForwardStack.append(navigate)
			}
		}
		goForwardStack = replacementGoForwardStack
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
	}
	
	func handle(_ activity: NSUserActivity) {
		guard let userInfo = activity.userInfo else { return }
		handle(userInfo)
	}
	
	func handle(_ userInfo: [AnyHashable: Any]) {
		if let searchIdentifier = userInfo[CSSearchableItemActivityIdentifier] as? String, let documentID = EntityID(description: searchIdentifier) {
			openDocument(documentID)
			return
		}
		
		if let sidebarWidth = userInfo[UserInfoKeys.sidebarWidth] as? CGFloat {
			preferredPrimaryColumnWidth = sidebarWidth
		}
		if let timelineWidth = userInfo[UserInfoKeys.timelineWidth] as? CGFloat {
			preferredSupplementaryColumnWidth = timelineWidth
		}

		guard let documentContainerUserInfo = userInfo[UserInfoKeys.documentContainerID] as? [AnyHashable : AnyHashable],
			  let documentContainerID = EntityID(userInfo: documentContainerUserInfo) else {
				  presentError(MainSplitViewControllerError.unknownOutline)
				  return
			  }

		var candidateContainer: DocumentContainer? = nil
		if let container = AccountManager.shared.findDocumentContainer(documentContainerID) {
			candidateContainer = container
		} else if let container = AccountManager.shared.findDocumentContainer(.allDocuments(documentContainerID.accountID)) {
			candidateContainer = container
		}

		guard let documentContainer = candidateContainer else {
			presentError(MainSplitViewControllerError.unknownOutline)
			return
		}
		
		sidebarViewController?.selectDocumentContainer(documentContainer, isNavigationBranch: true, animated: false) {
			self.lastMainControllerToAppear = .timeline

			guard let documentUserInfo = userInfo[UserInfoKeys.documentID] as? [AnyHashable : AnyHashable],
				  let documentID = EntityID(userInfo: documentUserInfo) else {
					  return
				  }
			
			guard let document = AccountManager.shared.findDocument(documentID) else {
				self.presentError(MainSplitViewControllerError.unknownOutline)
				return
			}
			
			self.handleSelectDocument(document)
		}
	}
	
	func openDocument(_ documentID: EntityID) {
		guard let account = AccountManager.shared.findAccount(accountID: documentID.accountID),
			  let document = account.findDocument(documentID) else { return }
		
		if let sidebarTag = sidebarViewController?.currentTag, document.hasTag(sidebarTag) {
			self.handleSelectDocument(document)
		} else if document.tagCount == 1, let tag = document.tags?.first {
			sidebarViewController?.selectDocumentContainer(TagDocuments(account: account, tag: tag), isNavigationBranch: true, animated: false) {
				self.handleSelectDocument(document)
			}
		} else {
			sidebarViewController?.selectDocumentContainer(AllDocuments(account: account), isNavigationBranch: true, animated: false) {
				self.handleSelectDocument(document)
			}
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
		goBackward()
	}

	@objc func goForwardOne(_ sender: Any?) {
		goForward()
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
		if let accountID = documentContainer?.account?.id.accountID {
			AppDefaults.shared.lastSelectedAccountID = accountID
		}
		
		if let documentContainer = documentContainer {
			activityManager.selectingDocumentContainer(documentContainer)
			if animated {
				show(.supplementary)
			} else {
				UIView.performWithoutAnimation {
					show(.supplementary)
				}
			}
		} else {
			activityManager.invalidateSelectDocumentContainer()
		}
		
		timelineViewController?.setDocumentContainer(documentContainer, isNavigationBranch: isNavigationBranch, completion: completion)
	}
	
}

// MARK: TimelineDelegate

extension MainSplitViewController: TimelineDelegate {
	
	func documentSelectionDidChangeTitle(_: TimelineViewController, documentContainer: DocumentContainer, document: Document) {
		activityManager.selectingDocument(documentContainer, document)
	}
	
	func documentSelectionDidChange(_: TimelineViewController, documentContainer: DocumentContainer, document: Document?, isNew: Bool, isNavigationBranch: Bool, animated: Bool) {
		if let lastNavigate = lastNavigate, let document = document, lastNavigate.document != document {
			goBackwardStack.append(lastNavigate)
			self.lastNavigate = nil
		}
		
		if isNavigationBranch {
			goForwardStack.removeAll()
		}

		if let document = document {
			activityManager.selectingDocument(documentContainer, document)
			if animated {
				show(.secondary)
			} else {
				UIView.performWithoutAnimation {
					self.show(.secondary)
				}
			}

			lastNavigate = Navigate(container: documentContainer, document: document)
		} else {
			activityManager.invalidateSelectDocument()
		}
		
		if let search = documentContainer as? Search {
			if search.searchText.isEmpty {
				editorViewController?.edit(nil, isNew: isNew)
			} else {
				editorViewController?.edit(document?.outline, isNew: isNew, searchText: search.searchText)
			}
		} else {
			editorViewController?.edit(document?.outline, isNew: isNew)
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
		return isGoBackwardUnavailable
	}
	
	var editorViewControllerIsGoForwardUnavailable: Bool {
		return isGoForwardUnavailable
	}
	
	func goBackward(_: EditorViewController) {
		goBackward()
	}
	
	func goForward(_: EditorViewController) {
		goForward()
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
			activityManager.invalidateSelectDocumentContainer()
			sidebarViewController?.selectDocumentContainer(nil, isNavigationBranch: false, animated: false)
			return
		}

		if isCollapsed && viewController === timelineViewController && lastMainControllerToAppear == .editor {
			activityManager.invalidateSelectDocument()
			timelineViewController?.selectDocument(nil, isNavigationBranch: false, animated: false)
			return
		}
	}
	
}

// MARK: OpenQuicklyViewControllerDelegate

extension MainSplitViewController: OpenQuicklyViewControllerDelegate {
	
	func quicklyOpenDocument(documentID: EntityID) {
		openDocument(documentID)
	}
	
}

// MARK: Helpers

extension MainSplitViewController {
	
	private func handleSelectDocument(_ document: Document) {
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
			self.timelineViewController?.selectDocument(document, animated: false)
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
	
	private func goBackward() {
		if let lastNavigate = lastNavigate {
			goForwardStack.append(lastNavigate)
		}
		
		lastNavigate = nil
		
		if let navigate = goBackwardStack.popLast() {
			sidebarViewController?.selectDocumentContainer(navigate.container, isNavigationBranch: false, animated: false) {
				self.timelineViewController?.selectDocument(navigate.document, isNavigationBranch: false, animated: false)
			}
		}
	}
	
	private func goForward() {
		if let navigate = goForwardStack.popLast() {
			sidebarViewController?.selectDocumentContainer(navigate.container, isNavigationBranch: false, animated: false) {
				self.timelineViewController?.selectDocument(navigate.document, isNavigationBranch: false, animated: false)
			}
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
			.goBackward,
			.goForward,
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
			.goBackward,
			.goForward,
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
		case .goBackward:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.isGoBackwardUnavailable ?? true
			}
			item.image = AppAssets.goBackward.symbolSizedForCatalyst()
			item.label = L10n.goBackward
			item.toolTip = L10n.goBackward
			item.isBordered = true
			item.action = #selector(goBackwardOne(_:))
			item.target = self
			item.visibilityPriority = .high
			toolbarItem = item
		case .goForward:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.isGoForwardUnavailable ?? true
			}
			item.image = AppAssets.goForward.symbolSizedForCatalyst()
			item.label = L10n.goForward
			item.toolTip = L10n.goForward
			item.isBordered = true
			item.action = #selector(goForwardOne(_:))
			item.target = self
			item.visibilityPriority = .high
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

