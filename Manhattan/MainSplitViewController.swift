//
//  MainSplitViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit

class MainSplitViewController: UISplitViewController {

	var sidebarViewController: SidebarViewController? {
		viewController(for: .primary) as? SidebarViewController
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
