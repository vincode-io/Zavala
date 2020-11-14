//
//  MainSplitViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import Templeton

class MainSplitViewController: UISplitViewController {

	private var sidebarViewController: SidebarViewController? {
		let navController = viewController(for: .primary) as? UINavigationController
		return navController?.topViewController as? SidebarViewController
	}
	
	private var timelineViewController: TimelineViewController? {
		viewController(for: .supplementary) as? TimelineViewController
	}
	
	private var detailViewController: EditorViewController? {
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
	
    override func viewDidLoad() {
        super.viewDidLoad()
		primaryBackgroundStyle = .sidebar
		if traitCollection.userInterfaceIdiom == .mac {
			preferredPrimaryColumnWidth = 200
			preferredSupplementaryColumnWidth = 300
		}

		delegate = self
		sidebarViewController?.delegate = self
		timelineViewController?.delegate = self
    }
	
	// MARK: API
	func startUp() {
		sidebarViewController?.startUp()
	}
	
	func handle(_ activity: NSUserActivity) {
		guard let activityType = ActivityType(rawValue: activity.activityType) else { return }
		switch activityType {
		case .restoration:
			break
		case .selectOutlineProvider:
			handleSelectOutlineProvider(activity.userInfo)
		case .selectOutline:
			handleSelectOutline(activity.userInfo)
		}
	}
	
	// MARK: Actions
	
	@objc func createFolder(_ sender: Any?) {
		sidebarViewController?.createFolder(sender)
	}
	
	@objc func createOutline(_ sender: Any?) {
		timelineViewController?.createOutline(sender)
	}
	
	@objc func toggleOutlineIsFavorite(_ sender: Any?) {
		
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
		timelineViewController?.changeOutlineProvider(outlineProvider) { [weak self] in
			guard let outlineProvider = outlineProvider else {
				self?.activityManager.invalidateSelectOutlineProvider()
				return
			}

			self?.activityManager.selectingOutlineProvider(outlineProvider)
			self?.show(.supplementary)
		}
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
		detailViewController?.outline = outline
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
			if detailViewController?.outline != nil {
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
	
	private func handleSelectOutlineProvider(_ userInfo: [AnyHashable : Any]?) {
		guard let userInfo = userInfo,
			  let outlineProviderUserInfo = userInfo[ActivityUserInfoKeys.outlineProviderID] as? [AnyHashable : AnyHashable],
			  let outlineProviderID = EntityID(userInfo: outlineProviderUserInfo),
			  let outlineProvider = AccountManager.shared.findOutlineProvider(outlineProviderID) else {
			return
		}
		
		sidebarViewController?.selectOutlineProvider(outlineProvider)
	}
	
	private func handleSelectOutline(_ userInfo: [AnyHashable : Any]?) {
		guard let userInfo = userInfo,
			  let outlineProviderUserInfo = userInfo[ActivityUserInfoKeys.outlineProviderID] as? [AnyHashable : AnyHashable],
			  let outlineProviderID = EntityID(userInfo: outlineProviderUserInfo),
			  let outlineProvider = AccountManager.shared.findOutlineProvider(outlineProviderID),
			  let outlineUserInfo = userInfo[ActivityUserInfoKeys.outlineID] as? [AnyHashable : AnyHashable],
			  let outlineID = EntityID(userInfo: outlineUserInfo) else {
			return
		}
		
		sidebarViewController?.selectOutlineProvider(outlineProvider)
		timelineViewController?.selectOutline(outlineID)
	}
	
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
//			.toggleOutlineIsFavorite
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
			item.checkForUnavailable = { [weak self] in
				return self?.timelineViewController?.isCreateOutlineUnavailable ?? true
			}
			item.image = AppAssets.createEntity
			item.label = NSLocalizedString("New Outline", comment: "New Outline")
			item.action = #selector(createOutline(_:))
			item.target = self
			toolbarItem = item
		case .toggleOutlineIsFavorite:
			let item = ValidatingToolbarItem(itemIdentifier: itemIdentifier)
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

