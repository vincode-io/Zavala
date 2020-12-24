//
//  MainSplitViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import Templeton

public extension Notification.Name {
	static let UserDidAddFolder = Notification.Name(rawValue: "UserDidAddFolder")
}

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
	
	private var activityManager = ActivityManager()

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
	
	var isOutlineFiltered: Bool {
		return editorViewController?.isOutlineFiltered ?? false
	}
	
	var isCreateFolderUnavailable: Bool {
		return sidebarViewController?.isCreateFolderUnavailable ?? true
	}
	
	var isCreateOutlineUnavailable: Bool {
		return timelineViewController?.isCreateOutlineUnavailable ?? true
	}
	
	var isExportOutlineUnavailable: Bool {
		return timelineViewController?.isExportOutlineUnavailable ?? true
	}
	
	var isDeleteEntityUnavailable: Bool {
		return (sidebarViewController?.isDeleteCurrentFolderUnavailable ?? true) &&
			(timelineViewController?.isDeleteCurrentOutlineUnavailable ?? true) &&
			(editorViewController?.isDeleteCurrentHeadlineUnavailable ?? true) 
	}

	var isCreateHeadlineUnavailable: Bool {
		return editorViewController?.isCreateHeadlineUnavailable ?? true
	}
	
	var isIndentHeadlineUnavailable: Bool {
		return editorViewController?.isIndentHeadlineUnavailable ?? true
	}

	var isOutdentHeadlineUnavailable: Bool {
		return editorViewController?.isOutdentHeadlineUnavailable ?? true
	}

	var isToggleHeadlineCompleteUnavailable: Bool {
		return editorViewController?.isToggleHeadlineCompleteUnavailable ?? true
	}
	
	var isCurrentHeadlineComplete: Bool {
		return editorViewController?.isCurrentHeadlineComplete ?? false
	}

	var isCreateHeadlineNoteUnavailable: Bool {
		return editorViewController?.isCreateHeadlineNoteUnavailable ?? true
	}
	
	var isDeleteHeadlineNoteUnavailable: Bool {
		return editorViewController?.isDeleteHeadlineNoteUnavailable ?? true
	}
	
	var isCurrentHeadlineNoteEmpty: Bool {
		return editorViewController?.isCurrentHeadlineNoteEmpty ?? false
	}

	var isSplitHeadlineUnavailable: Bool {
		return editorViewController?.isSplitHeadlineUnavailable ?? true
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
		
		NotificationCenter.default.addObserver(self, selector: #selector(userDidAddFolder(_:)), name: .UserDidAddFolder, object: nil)
    }
	
	// MARK: API
	
	func startUp() {
		sidebarViewController?.navigationController?.delegate = self
		sidebarViewController?.delegate = self
		timelineViewController?.navigationController?.delegate = self
		timelineViewController?.delegate = self
		sidebarViewController?.startUp()
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

		sidebarViewController?.selectDocumentContainer(documentContainer, animated: false)
		lastMainControllerToAppear = .timeline

		guard let documentUserInfo = userInfo[UserInfoKeys.documentID] as? [AnyHashable : AnyHashable],
			  let documentID = EntityID(userInfo: documentUserInfo),
			  let document = AccountManager.shared.findDocument(documentID) else { return }
		
		timelineViewController?.selectDocument(document, animated: false)
		lastMainControllerToAppear = .editor
	}
	
	// MARK: Notifications
	
	@objc func userDidAddFolder(_ note: Notification) {
		guard let folder = note.userInfo?[UserInfoKeys.folder] as? Folder else { return }
		sidebarViewController?.selectDocumentContainer(folder, animated: true)
	}
	
	// MARK: Actions
	
	override func delete(_ sender: Any?) {
		guard editorViewController?.isDeleteCurrentHeadlineUnavailable ?? true else {
			editorViewController?.deleteCurrentHeadline()
			return
		}
		
		guard timelineViewController?.isDeleteCurrentOutlineUnavailable ?? true else {
			timelineViewController?.deleteCurrentOutline()
			return
		}
		
		sidebarViewController?.deleteCurrentFolder()
	}
	
	@objc func createFolder(_ sender: Any?) {
		sidebarViewController?.createFolder(sender)
	}
	
	@objc func createOutline(_ sender: Any?) {
		timelineViewController?.createOutline(sender)
	}
	
	@objc func importOPML(_ sender: Any?) {
		timelineViewController?.importOPML(sender)
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
	
	@objc func toggleSidebar(_ sender: Any?) {
		UIView.animate(withDuration: 0.25) {
			self.preferredDisplayMode = self.displayMode == .twoBesideSecondary ? .secondaryOnly : .twoBesideSecondary
		}
	}
	
	@objc func createHeadline(_ sender: Any?) {
		editorViewController?.createHeadline()
	}
	
	@objc func indentHeadline(_ sender: Any?) {
		editorViewController?.indentHeadline()
	}
	
	@objc func outdentHeadline(_ sender: Any?) {
		editorViewController?.outdentHeadline()
	}
	
	@objc func toggleCompleteHeadline(_ sender: Any?) {
		editorViewController?.toggleCompleteHeadline()
	}
	
	@objc func createHeadlineNote(_ sender: Any?) {
		editorViewController?.createHeadlineNote()
	}
	
	@objc func deleteHeadlineNote(_ sender: Any?) {
		editorViewController?.deleteHeadlineNote()
	}
	
	@objc func splitHeadline(_ sender: Any?) {
		editorViewController?.splitHeadline()
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
	
	// MARK: Validations
	
	override func validate(_ command: UICommand) {
		print(command)
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
	
	func restoreArchive() {
		sidebarViewController?.restoreArchive()
	}
	
	func restoreArchive(url: URL) {
		sidebarViewController?.restoreArchive(url: url)
	}
	
	func archiveAccount(type: AccountType) {
		sidebarViewController?.archiveAccount(type: type)
	}
	
}

// MARK: SidebarDelegate

extension MainSplitViewController: SidebarDelegate {
	
	func documentContainerSelectionDidChange(_: SidebarViewController, documentContainer: DocumentContainer?, animated: Bool) {
		timelineViewController?.documentContainer = documentContainer
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
		
		guard let outline = document?.outline else {
			editorViewController?.edit(nil, isNew: isNew)
			return
		}
		
		editorViewController?.edit(outline, isNew: isNew)
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

#if targetEnvironment(macCatalyst)

extension NSToolbarItem.Identifier {
	static let newOutline = NSToolbarItem.Identifier("io.vincode.Zavala.newOutline")
	static let toggleOutlineFilter = NSToolbarItem.Identifier("io.vincode.Zavala.toggleOutlineFilter")
	static let link = NSToolbarItem.Identifier("io.vincode.Zavala.link")
	static let boldface = NSToolbarItem.Identifier("io.vincode.Zavala.boldface")
	static let italic = NSToolbarItem.Identifier("io.vincode.Zavala.italic")
}

extension MainSplitViewController: NSToolbarDelegate {
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		let identifiers: [NSToolbarItem.Identifier] = [
			.toggleSidebar,
			.flexibleSpace,
			.supplementarySidebarTrackingSeparatorItemIdentifier,
			.newOutline,
			.space,
			.link,
			.boldface,
			.italic,
			.flexibleSpace,
			.toggleOutlineFilter,
		]
		return identifiers
	}
	
	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return toolbarDefaultItemIdentifiers(toolbar)
	}
	
	func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
		
		var toolbarItem: NSToolbarItem?
		
		switch itemIdentifier {
		case .newOutline:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] _ in
				return self?.timelineViewController?.isCreateOutlineUnavailable ?? true
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
		case .toggleSidebar:
			toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
			
		default:
			toolbarItem = nil
		}
		
		return toolbarItem
	}
}

#endif

