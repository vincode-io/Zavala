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
	
	var isExportOutlineUnavailable: Bool {
		return timelineViewController?.isExportOutlineUnavailable ?? true
	}
	
	var isDeleteEntityUnavailable: Bool {
		return (timelineViewController?.isDeleteCurrentOutlineUnavailable ?? true) &&
			(editorViewController?.isDeleteCurrentRowUnavailable ?? true) 
	}

	var activityManager = ActivityManager()
	
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
	
	// MARK: API
	
	func startUp() {
		sidebarViewController?.navigationController?.delegate = self
		sidebarViewController?.delegate = self
		timelineViewController?.navigationController?.delegate = self
		timelineViewController?.delegate = self
		sidebarViewController?.startUp()
		editorViewController?.delegate = self
	}
	
	func handle(_ activity: NSUserActivity) {
		guard let userInfo = activity.userInfo else { return }
		
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
			  let documentContainerID = EntityID(userInfo: documentContainerUserInfo),
			  let documentContainer = AccountManager.shared.findDocumentContainer(documentContainerID) else { return }

		UIView.performWithoutAnimation {
			show(.primary)
		}

		sidebarViewController?.selectDocumentContainer(documentContainer, animated: false) {
			self.lastMainControllerToAppear = .timeline

			guard let documentUserInfo = userInfo[UserInfoKeys.documentID] as? [AnyHashable : AnyHashable],
				  let documentID = EntityID(userInfo: documentUserInfo),
				  let document = AccountManager.shared.findDocument(documentID) else { return }
			
			self.timelineViewController?.selectDocument(document, animated: false) {
				self.lastMainControllerToAppear = .editor
				self.validateToolbar()
			}
		}
	}
	
	func openDocument(_ documentID: EntityID) {
		guard let account = AccountManager.shared.findAccount(accountID: documentID.accountID),
			  let document = account.findDocument(documentID) else { return }
		
		UIView.performWithoutAnimation {
			show(.primary)
		}

		sidebarViewController?.selectDocumentContainer(AllDocuments(account: account), animated: false) {
			self.timelineViewController?.selectDocument(document, animated: false) {
				self.lastMainControllerToAppear = .editor
				self.validateToolbar()
			}
		}
	}
	
	func openURL(_ urlString: String) {
		guard let url = URL(string: urlString) else { return }
		let vc = SFSafariViewController(url: url)
		vc.modalPresentationStyle = .pageSheet
		present(vc, animated: true)
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

	func showSettings() {
		let settingsNavController = UIStoryboard.settings.instantiateInitialViewController() as! UINavigationController
		settingsNavController.modalPresentationStyle = .formSheet
		present(settingsNavController, animated: true)
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
		
		guard timelineViewController?.isDeleteCurrentOutlineUnavailable ?? true else {
			timelineViewController?.deleteCurrentDocument()
			return
		}
	}
	
	@objc func sync(_ sender: Any?) {
		AccountManager.shared.sync()
	}
	
	@objc func createOutline() {
		selectDefaultDocumentContainerIfNecessary() {
			self.timelineViewController?.createOutline(self)
		}
	}
	
	@objc func importOPML() {
		selectDefaultDocumentContainerIfNecessary() {
			self.timelineViewController?.importOPML(self)
		}
	}
	
	@objc func exportMarkdown() {
		guard let outline = editorViewController?.outline else { return }
		exportMarkdownForOutline(outline)
	}
	
	@objc func exportOPML() {
		guard let outline = editorViewController?.outline else { return }
		exportOPMLForOutline(outline)
	}
	
	@objc func toggleSidebar(_ sender: Any?) {
		UIView.animate(withDuration: 0.25) {
			self.preferredDisplayMode = self.displayMode == .twoBesideSecondary ? .secondaryOnly : .twoBesideSecondary
		}
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
	
	func documentContainerSelectionDidChange(_: SidebarViewController, documentContainer: DocumentContainer?, animated: Bool, completion: (() -> Void)? = nil) {
		if let accountID = documentContainer?.account?.id.accountID {
			AppDefaults.shared.lastSelectedAccountID = accountID
		}
		
		timelineViewController?.setDocumentContainer(documentContainer, completion: completion)
		editorViewController?.edit(nil, isNew: false)

		guard let documentContainer = documentContainer else {
			activityManager.invalidateSelectDocumentContainer()
			return
		}

		activityManager.selectingDocumentContainer(documentContainer)
		if animated {
			show(.supplementary)
		} else {
			UIView.performWithoutAnimation {
				show(.supplementary)
			}
		}
	}
	
}

// MARK: TimelineDelegate

extension MainSplitViewController: TimelineDelegate {
	
	func documentSelectionDidChange(_: TimelineViewController, documentContainer: DocumentContainer, document: Document?, isNew: Bool, animated: Bool) {
		if let document = document {
			activityManager.selectingDocument(documentContainer, document)
			if animated {
				show(.secondary)
			} else {
				UIView.performWithoutAnimation {
					show(.secondary)
				}
			}
		} else {
			activityManager.invalidateSelectDocument()
		}
		
		if let search = documentContainer as? Search {
			editorViewController?.edit(document?.outline, isNew: isNew, searchText: search.searchText)
		} else {
			editorViewController?.edit(document?.outline, isNew: isNew)
		}
	}

	func exportMarkdown(_: TimelineViewController, outline: Outline) {
		exportMarkdownForOutline(outline)
	}
	
	func exportOPML(_: TimelineViewController, outline: Outline) {
		exportOPMLForOutline(outline)
	}
	
}

// MARK: EditorDelegate

extension MainSplitViewController: EditorDelegate {
	
	func validateToolbar(_: EditorViewController) {
		validateToolbar()
	}

	func exportMarkdown(_: EditorViewController, outline: Outline) {
		exportMarkdownForOutline(outline)
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
			sidebarViewController?.selectDocumentContainer(nil, animated: false)
			return
		}

		if isCollapsed && viewController === timelineViewController && lastMainControllerToAppear == .editor {
			activityManager.invalidateSelectDocument()
			timelineViewController?.selectDocument(nil, animated: false)
			return
		}
	}
	
}

extension MainSplitViewController: OpenQuicklyViewControllerDelegate {
	
	func quicklyOpenDocument(documentID: EntityID) {
		openDocument(documentID)
	}
	
}

// MARK: Helpers

extension MainSplitViewController {
	
	private func selectDefaultDocumentContainerIfNecessary(completion: @escaping () -> Void) {
		guard sidebarViewController?.selectedAccount == nil else {
			completion()
			return
		}
		
		let accountID = AppDefaults.shared.lastSelectedAccountID
		
		guard let account = AccountManager.shared.findAccount(accountID: accountID) ?? AccountManager.shared.activeAccounts.first else {
			completion()
			return
		}
		
		let documentContainer = account.documentContainers[0]
		
		sidebarViewController?.selectDocumentContainer(documentContainer, animated: true) {
			completion()
		}
	}
	
	private func exportMarkdownForOutline(_ outline: Outline) {
		let markdown = outline.markdownOutline()
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

#if targetEnvironment(macCatalyst)

extension MainSplitViewController: NSToolbarDelegate {
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return [
			.toggleSidebar,
			.flexibleSpace,
			.newOutline,
			.supplementarySidebarTrackingSeparatorItemIdentifier,
			.link,
			.boldface,
			.italic,
			.flexibleSpace,
			.share,
			.sendCopy,
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
			.link,
			.boldface,
			.italic,
			.toggleOutlineNotesHidden,
			.toggleOutlineFilter,
			.expandAllInOutline,
			.collapseAllInOutline,
			.indent,
			.outdent,
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
		case .sync:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { _ in
				return !AccountManager.shared.isSyncAvailable
			}
			item.image = AppAssets.sync
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
			item.image = AppAssets.importDocument
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
			item.image = AppAssets.createEntity
			item.label = L10n.newOutline
			item.toolTip = L10n.newOutline
			item.isBordered = true
			item.action = #selector(createOutline)
			item.target = self
			toolbarItem = item
		case .link:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.editorViewController?.isLinkUnavailable ?? true
			}
			item.image = AppAssets.link
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
					item.image = AppAssets.bold.tinted(color: UIColor.systemBlue)
				} else {
					item.image = AppAssets.bold
				}
				return self?.editorViewController?.isFormatUnavailable ?? true
			}
			item.image = AppAssets.bold
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
					item.image = AppAssets.italic.tinted(color:	UIColor.systemBlue)
				} else {
					item.image = AppAssets.italic
				}
				return self?.editorViewController?.isFormatUnavailable ?? true
			}
			item.image = AppAssets.italic
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
			item.image = AppAssets.expandAll
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
			item.image = AppAssets.collapseAll
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
			item.image = AppAssets.indent
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
			item.image = AppAssets.outdent
			item.label = L10n.outdent
			item.toolTip = L10n.outdent
			item.isBordered = true
			item.action = #selector(outdentRows(_:))
			item.target = self
			toolbarItem = item
		case .toggleOutlineFilter:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] item in
				if self?.editorViewController?.isOutlineFiltered ?? false {
					item.image = AppAssets.filterActive
					item.label = L10n.showCompleted
					item.toolTip = L10n.showCompleted
				} else {
					item.image = AppAssets.filterInactive
					item.label = L10n.hideCompleted
					item.toolTip = L10n.hideCompleted
				}
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = AppAssets.filterInactive
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
					item.image = AppAssets.hideNotesActive
					item.label = L10n.showNotes
					item.toolTip = L10n.showNotes
				} else {
					item.image = AppAssets.hideNotesInactive
					item.label = L10n.hideNotes
					item.toolTip = L10n.hideNotes
				}
				return self?.editorViewController?.isOutlineFunctionsUnavailable ?? true
			}
			item.image = AppAssets.hideNotesInactive
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
			item.image = AppAssets.print
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
					item.image = AppAssets.shared
				} else if self?.editorViewController?.isShareUnavailable ?? true {
					item.image = AppAssets.statelessShare
				} else {
					item.image = AppAssets.share
				}
				return self?.editorViewController?.isShareUnavailable ?? true
			}
			item.image = AppAssets.share
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
			item.image = AppAssets.getInfo
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
			let data = outline.markdownOutline().data(using: .utf8)
			completion(data, nil)
			return nil
		}
		
		return [itemProvider]
	}
	
}

#endif

