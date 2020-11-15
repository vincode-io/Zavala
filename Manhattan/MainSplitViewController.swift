//
//  MainSplitViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import Templeton

public extension Notification.Name {
	static let UserDidAddFolder = Notification.Name(rawValue: "UserDidAddFolder")
	static let UserDidAddOutline = Notification.Name(rawValue: "UserDidAddOutline")
}

class MainSplitViewController: UISplitViewController {

	private var sidebarViewController: SidebarViewController? {
		let navController = viewController(for: .primary) as? UINavigationController
		return navController?.topViewController as? SidebarViewController
	}
	
	private var timelineViewController: TimelineViewController? {
		viewController(for: .supplementary) as? TimelineViewController
	}
	
	private var editorViewController: EditorViewController? {
		viewController(for: .secondary) as? EditorViewController
	}
	
	private var activityManager = ActivityManager()

	var stateRestorationActivity: NSUserActivity {
		let activity = activityManager.stateRestorationActivity
//		var userInfo = activity.userInfo == nil ? [AnyHashable: Any]() : activity.userInfo
//		userInfo![UserInfoKey.windowState] = windowState()
//		activity.userInfo = userInfo
		return activity
	}
	
	var isCreateFolderUnavailable: Bool {
		return sidebarViewController?.isCreateFolderUnavailable ?? true
	}
	
	var isCreateOutlineUnavailable: Bool {
		return timelineViewController?.isCreateOutlineUnavailable ?? true
	}
	
	var isDeleteEntityUnavailable: Bool {
		return (sidebarViewController?.isDeleteEntityUnavailable ?? true) && (timelineViewController?.isDeleteEntityUnavailable ?? true)
	}

	override func viewDidLoad() {
        super.viewDidLoad()
		primaryBackgroundStyle = .sidebar
		if traitCollection.userInterfaceIdiom == .mac {
			preferredPrimaryColumnWidth = 200
			preferredSupplementaryColumnWidth = 300
		}

		delegate = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(userDidAddFolder(_:)), name: .UserDidAddFolder, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(userDidAddOutline(_:)), name: .UserDidAddOutline, object: nil)
    }
	
	// MARK: API
	func startUp() {
		sidebarViewController?.delegate = self
		timelineViewController?.delegate = self
		sidebarViewController?.startUp()
	}
	
	func handle(_ activity: NSUserActivity) {
		guard let userInfo = activity.userInfo,
			  let outlineProviderUserInfo = userInfo[UserInfoKeys.outlineProviderID] as? [AnyHashable : AnyHashable],
			  let outlineProviderID = EntityID(userInfo: outlineProviderUserInfo),
			  let outlineProvider = AccountManager.shared.findOutlineProvider(outlineProviderID) else { return }

		sidebarViewController?.selectOutlineProvider(outlineProvider, animated: false)

		guard let outlineUserInfo = userInfo[UserInfoKeys.outlineID] as? [AnyHashable : AnyHashable],
			  let outlineID = EntityID(userInfo: outlineUserInfo),
			  let outline = AccountManager.shared.findOutline(outlineID) else { return }
		
		timelineViewController?.selectOutline(outline, animated: false)
	}
	
	// MARK: Notifications
	
	@objc func userDidAddFolder(_ note: Notification) {
		guard let folder = note.userInfo?[UserInfoKeys.folder] as? Folder else { return }
		sidebarViewController?.selectOutlineProvider(folder, animated: true)
	}
	
	@objc func userDidAddOutline(_ note: Notification) {
		guard let outline = note.userInfo?[UserInfoKeys.outline] as? Outline else { return }
		timelineViewController?.selectOutline(outline, animated: true)
	}
	
	// MARK: Actions
	
	@objc func createFolder(_ sender: Any?) {
		sidebarViewController?.createFolder(sender)
	}
	
	@objc func createOutline(_ sender: Any?) {
		timelineViewController?.createOutline(sender)
	}
	
	@objc func deleteEntity(_ sender: Any?) {
		if timelineViewController?.isDeleteEntityUnavailable ?? true {
			sidebarViewController?.deleteCurrentFolder()
		} else {
			timelineViewController?.deleteCurrentOutline()
		}
	}
	
	@objc func toggleOutlineIsFavorite(_ sender: Any?) {
		editorViewController?.toggleOutlineIsFavorite(sender)
	}
	
	@objc func toggleSidebar(_ sender: Any?) {
		UIView.animate(withDuration: 0.25) {
			self.preferredDisplayMode = self.displayMode == .twoBesideSecondary ? .secondaryOnly : .twoBesideSecondary
		}
	}
	
}

// MARK: SidebarDelegate

extension MainSplitViewController: SidebarDelegate {
	
	func outlineProviderSelectionDidChange(_: SidebarViewController, outlineProvider: OutlineProvider?) {
		timelineViewController?.outlineProvider = outlineProvider
		editorViewController?.outline = nil

		guard let outlineProvider = outlineProvider else {
			activityManager.invalidateSelectOutlineProvider()
			return
		}

		activityManager.selectingOutlineProvider(outlineProvider)
		show(.supplementary)
	}
	
}

// MARK: OutlineListDelegate

extension MainSplitViewController: TimelineDelegate {
	
	func outlineSelectionDidChange(_: TimelineViewController, outlineProvider: OutlineProvider, outline: Outline?) {
		guard let outline = outline else {
			activityManager.invalidateSelectOutline()
			return
		}

		activityManager.selectingOutline(outlineProvider, outline)
		show(.secondary)
		editorViewController?.outline = outline
	}
	
}

// MARK: UISplitViewControllerDelegate

extension MainSplitViewController: UISplitViewControllerDelegate {
	
	func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
		switch proposedTopColumn {
		case .supplementary:
			if timelineViewController?.outlineProvider != nil {
				return .supplementary
			} else {
				return .primary
			}
		case .secondary:
			if editorViewController?.outline != nil {
				return .secondary
			} else {
				if timelineViewController?.outlineProvider != nil {
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

// MARK: Helpers

extension MainSplitViewController {
	
}

#if targetEnvironment(macCatalyst)

extension NSToolbarItem.Identifier {
	static let newOutline = NSToolbarItem.Identifier("io.vincode.Manhattan.newOutline")
	static let toggleOutlineIsFavorite = NSToolbarItem.Identifier("io.vincode.Manhattan.toggleOutlineIsFavorite")
}

extension MainSplitViewController: NSToolbarDelegate {
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		let identifiers: [NSToolbarItem.Identifier] = [
			.toggleSidebar,
			.flexibleSpace,
			.newOutline,
			.supplementarySidebarTrackingSeparatorItemIdentifier,
			.flexibleSpace,
			.toggleOutlineIsFavorite
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
			item.label = NSLocalizedString("New Outline", comment: "New Outline")
			item.action = #selector(createOutline(_:))
			item.target = self
			toolbarItem = item
		case .toggleOutlineIsFavorite:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
			item.checkForUnavailable = { [weak self] item in
				if self?.editorViewController?.outline?.isFavorite ?? false {
					item.image = AppAssets.favoriteSelected
				} else {
					item.image = AppAssets.favoriteUnselected
				}
				return self?.editorViewController?.isToggleFavoriteUnavailable ?? true
			}
			item.image = AppAssets.favoriteUnselected
			item.label = NSLocalizedString("Toggle Favorite", comment: "Toggle Favorite")
			item.action = #selector(toggleOutlineIsFavorite(_:))
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

