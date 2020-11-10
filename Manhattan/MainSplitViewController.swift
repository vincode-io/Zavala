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

        // Do any additional setup after loading the view.
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
}
