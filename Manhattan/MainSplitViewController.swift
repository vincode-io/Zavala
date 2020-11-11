//
//  MainSplitViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import Templeton

class MainSplitViewController: UISplitViewController {

	var sidebarViewController: SidebarViewController? {
		let navController = viewController(for: .primary) as? UINavigationController
		return navController?.topViewController as? SidebarViewController
	}
	
	var outlineListViewController: OutlineListViewController? {
		viewController(for: .supplementary) as? OutlineListViewController
	}
	
	var outlineDetailViewController: OutlineDetailViewController? {
		viewController(for: .supplementary) as? OutlineDetailViewController
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
		outlineListViewController?.delegate = self
    }
	
	// MARK: Actions
	
	@objc func createFolder(_ sender: Any?) {
		sidebarViewController?.createFolder(sender)
	}
	
	@objc func createOutline(_ sender: Any?) {
		outlineListViewController?.createOutline(sender)
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
	
	func sidebarSelectionDidChange(_: SidebarViewController, outlineProvider: OutlineProvider?) {
		outlineListViewController?.outlineProvider = outlineProvider
		show(.supplementary)
	}
	
}

// MARK: OutlineListDelegate

extension MainSplitViewController: OutlineListDelegate {
	
	func outlineSelectionDidChange(_: OutlineListViewController, outline: Outline) {
		
	}
	
}

// MARK: UISplitViewControllerDelegate

extension MainSplitViewController: UISplitViewControllerDelegate {
	
	func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
		switch proposedTopColumn {
		case .supplementary:
			if outlineListViewController?.outlineProvider != nil {
				return .supplementary
			} else {
				return .primary
			}
		case .secondary:
			if outlineDetailViewController?.outline != nil {
				return .secondary
			} else {
				if outlineListViewController?.outlineProvider != nil {
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
