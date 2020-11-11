//
//  OutlineListViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit
import Templeton

protocol OutlineListDelegate: class  {
	func outlineSelectionDidChange(_: OutlineListViewController, outline: Outline)
}

class OutlineListViewController: UICollectionViewController {
	
	weak var delegate: OutlineListDelegate?
	var outlineProvider: OutlineProvider? {
		didSet {
			updateUI()
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		updateUI()
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: animated)
		}
	}

	// MARK: Actions
	
	@objc func createOutline(_ sender: Any?) {
	}

}

private extension OutlineListViewController {
	
	private func updateUI() {
		guard isViewLoaded else { return }
		view.window?.windowScene?.title = outlineProvider?.name
	}
	
}
