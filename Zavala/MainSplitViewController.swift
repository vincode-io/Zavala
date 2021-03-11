//
//  MainSplitViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
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

class MainSplitViewController: UISplitViewController {
	
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
	
	var isOutlineFunctionsUnavailable: Bool {
		return editorViewController?.isOutlineFunctionsUnavailable ?? true
	}
	
	var isShareUnavailable: Bool {
		return editorViewController?.isShareUnavailable ?? true
	}
	
	var isOutlineFiltered: Bool {
		return editorViewController?.isOutlineFiltered ?? false
	}
	
	var isOutlineNotesHidden: Bool {
		return editorViewController?.isOutlineNotesHidden ?? false
	}
	
	var isExportOutlineUnavailable: Bool {
		return timelineViewController?.isExportOutlineUnavailable ?? true
	}
	
	var isDeleteEntityUnavailable: Bool {
		return (timelineViewController?.isDeleteCurrentOutlineUnavailable ?? true) &&
			(editorViewController?.isDeleteCurrentRowUnavailable ?? true) 
	}

	var isInsertRowUnavailable: Bool {
		return editorViewController?.isInsertRowUnavailable ?? true
	}
	
	var isCreateRowUnavailable: Bool {
		return editorViewController?.isCreateRowUnavailable ?? true
	}
	
	var isIndentRowsUnavailable: Bool {
		return editorViewController?.isIndentRowsUnavailable ?? true
	}

	var isOutdentRowsUnavailable: Bool {
		return editorViewController?.isOutdentRowsUnavailable ?? true
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
	
	var isSplitRowUnavailable: Bool {
		return editorViewController?.isSplitRowUnavailable ?? true
	}
	
	var isFormatUnavailable: Bool {
		return editorViewController?.isFormatUnavailable ?? true
	}
	
	var isLinkUnavailable: Bool {
		return editorViewController?.isLinkUnavailable ?? true
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
	
	var isDeleteCompletedRowsUnavailable: Bool {
		return editorViewController?.isDeleteCompletedRowsUnavailable ?? true
	}
	
	var activityManager = ActivityManager()
	
	private var sidebarViewController: SidebarViewController? {
		return viewController(for: .primary) as? SidebarViewController
	}
	
	private var timelineViewController: TimelineViewController? {
		viewController(for: .supplementary) as? TimelineViewController
	}
	
	private var editorViewController: EditorViewController? {
		viewController(for: .secondary) as? EditorViewController
	}
	
	private var lastMainControllerToAppear = MainControllerIdentifier.none
	
	#if targetEnvironment(macCatalyst)
	private var crashReporter = CrashReporter()
	#endif
	
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

		#if targetEnvironment(macCatalyst)
		DispatchQueue.main.async {
			self.crashReporter.check(presentingController: self)
		}
		#endif
	}
	
	func handle(_ activity: NSUserActivity) {
		guard let userInfo = activity.userInfo else { return }
		
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
				self.sceneDelegate?.validateToolbar()
			}
		}
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
	
	@objc func createOutline(_ sender: Any?) {
		selectDefaultDocumentContainerIfNecessary() {
			self.timelineViewController?.createOutline(sender)
		}
	}
	
	@objc func importOPML(_ sender: Any?) {
		selectDefaultDocumentContainerIfNecessary() {
			self.timelineViewController?.importOPML(sender)
		}
	}
	
	@objc func exportMarkdown(_ sender: Any?) {
		timelineViewController?.exportMarkdown(sender)
	}
	
	@objc func exportOPML(_ sender: Any?) {
		timelineViewController?.exportOPML(sender)
	}
	
	@objc func toggleOutlineFilter(_ sender: Any?) {
		editorViewController?.toggleOutlineFilter(sender)
	}
	
	@objc func toggleOutlineHideNotes(_ sender: Any?) {
		editorViewController?.toggleOutlineHideNotes(sender)
	}
	
	@objc func toggleSidebar(_ sender: Any?) {
		UIView.animate(withDuration: 0.25) {
			self.preferredDisplayMode = self.displayMode == .twoBesideSecondary ? .secondaryOnly : .twoBesideSecondary
		}
	}
	
	@objc func insertRow(_ sender: Any?) {
		editorViewController?.insertRow()
	}
	
	@objc func createRow(_ sender: Any?) {
		editorViewController?.createRow()
	}
	
	@objc func indentRows(_ sender: Any?) {
		editorViewController?.indentRows()
	}
	
	@objc func outdentRows(_ sender: Any?) {
		editorViewController?.outdentRows()
	}
	
	@objc func toggleCompleteRows(_ sender: Any?) {
		editorViewController?.toggleCompleteRows()
	}
	
	@objc func createRowNotes(_ sender: Any?) {
		editorViewController?.createRowNotes()
	}
	
	@objc func deleteRowNotes(_ sender: Any?) {
		editorViewController?.deleteRowNotes()
	}
	
	@objc func splitRow(_ sender: Any?) {
		editorViewController?.splitRow()
	}
	
	@objc func outlineToggleBoldface(_ sender: Any?) {
		editorViewController?.outlineToggleBoldface()
	}
	
	@objc func outlineToggleItalics(_ sender: Any?) {
		editorViewController?.outlineToggleItalics()
	}
	
	@objc func link(_ sender: Any?) {
		editorViewController?.link()
	}
	
	@objc func expandAllInOutline(_ sender: Any?) {
		editorViewController?.expandAllInOutline()
	}
	
	@objc func collapseAllInOutline(_ sender: Any?) {
		editorViewController?.collapseAllInOutline()
	}
	
	@objc func expandAll(_ sender: Any?) {
		editorViewController?.expandAll()
	}
	
	@objc func collapseAll(_ sender: Any?) {
		editorViewController?.collapseAll()
	}
	
	@objc func expand(_ sender: Any?) {
		editorViewController?.expand()
	}
	
	@objc func collapse(_ sender: Any?) {
		editorViewController?.collapse()
	}
	
	@objc func deleteCompletedRows(_ sender: Any?) {
		editorViewController?.deleteCompletedRows()
	}
	
	@objc func printDocument(_ sender: Any?) {
		editorViewController?.printOutline()
	}
	
	@objc func share(_ sender: Any?) {
		editorViewController?.share()
	}
	
	@objc func sendCopy(_ sender: Any?) {
		editorViewController?.sendCopy()
	}
	
	@objc func beginDocumentSearch(_ sender: Any?) {
		sidebarViewController?.beginDocumentSearch()
	}
	
	@objc func beginInDocumentSearch(_ sender: Any?) {
		editorViewController?.beginInDocumentSearch()
	}
	
	@objc func useSelectionForSearch(_ sender: Any?) {
		editorViewController?.useSelectionForSearch()
	}
	
	@objc func nextInDocumentSearch(_ sender: Any?) {
		editorViewController?.nextInDocumentSearch()
	}
	
	@objc func previousInDocumentSearch(_ sender: Any?) {
		editorViewController?.previousInDocumentSearch()
	}
	
	@objc func outlineGetInfo(_ sender: Any?) {
		editorViewController?.showOutlineGetInfo()
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
	
	// MARK: API
	
	func showReleaseNotes() {
		openURL(AppAssets.releaseNotesURL)
	}
	
	func showGitHubRepository() {
		openURL(AppAssets.githubRepositoryURL)
	}
	
	func showBugTracker() {
		openURL(AppAssets.bugTrackerURL)
	}
	
	func showSettings() {
		let settingsNavController = UIStoryboard.settings.instantiateInitialViewController() as! UINavigationController
		settingsNavController.modalPresentationStyle = .formSheet
		present(settingsNavController, animated: true)
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
		
		editorViewController?.edit(document?.outline, isNew: isNew)
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

// MARK: Helpers

extension MainSplitViewController {
	
	private func openURL(_ urlString: String) {
		guard let url = URL(string: urlString) else { return }
		let vc = SFSafariViewController(url: url)
		vc.modalPresentationStyle = .pageSheet
		present(vc, animated: true)
	}

	private func selectDefaultDocumentContainerIfNecessary(completion: @escaping () -> Void) {
		guard sidebarViewController?.selectedAccount == nil else {
			completion()
			return
		}
		
		let accountID = AppDefaults.shared.lastSelectedAccountID
		
		guard let account = AccountManager.shared.findAccount(accountID: accountID) else {
			completion()
			return
		}
		
		let documentContainer = account.documentContainers[0]
		
		sidebarViewController?.selectDocumentContainer(documentContainer, animated: true) {
			completion()
		}
	}
	
}

#if targetEnvironment(macCatalyst)

extension NSToolbarItem.Identifier {
	static let sync = NSToolbarItem.Identifier("io.vincode.Zavala.refresh")
	static let importOPML = NSToolbarItem.Identifier("io.vincode.Zavala.importOPML")
	static let newOutline = NSToolbarItem.Identifier("io.vincode.Zavala.newOutline")
	static let toggleOutlineFilter = NSToolbarItem.Identifier("io.vincode.Zavala.toggleOutlineFilter")
	static let toggleOutlineNotesHidden = NSToolbarItem.Identifier("io.vincode.Zavala.toggleOutlineNotesHidden")
	static let link = NSToolbarItem.Identifier("io.vincode.Zavala.link")
	static let boldface = NSToolbarItem.Identifier("io.vincode.Zavala.boldface")
	static let italic = NSToolbarItem.Identifier("io.vincode.Zavala.italic")
	static let expandAllInOutline = NSToolbarItem.Identifier("io.vincode.Zavala.expandAllInOutline")
	static let collapseAllInOutline = NSToolbarItem.Identifier("io.vincode.Zavala.collapseAllInOutline")
	static let printDocument = NSToolbarItem.Identifier("io.vincode.Zavala.print")
	static let share = NSToolbarItem.Identifier("io.vincode.Zavala.share")
	static let sendCopy = NSToolbarItem.Identifier("io.vincode.Zavala.sendCopy")
}

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
			.print,
			.share,
			.sendCopy,
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
			item.image = AppAssets.importEntity
			item.label = L10n.importOPML
			item.toolTip = L10n.importOPML
			item.isBordered = true
			item.action = #selector(importOPML(_:))
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
			item.action = #selector(createOutline(_:))
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
			item.label = L10n.expandAllInOutline
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
			item.label = L10n.collapseAllInOutline
			item.toolTip = L10n.collapseAllInOutline
			item.isBordered = true
			item.action = #selector(collapseAllInOutline(_:))
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
			let data = outline.markdown().data(using: .utf8)
			completion(data, nil)
			return nil
		}
		
		return [itemProvider]
	}
	
}

#endif

