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

    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		#if targetEnvironment(macCatalyst)
		navigationController?.setNavigationBarHidden(true, animated: animated)
		#endif
	}

	// MARK: Actions
	
	@objc func createOutline(_ sender: Any?) {
	}

}

private extension OutlineListViewController {
	
	private func updateUI() {
		guard isViewLoaded else { return }
		navigationItem.title = outlineProvider?.name ?? NSLocalizedString("Outlines", comment: "Outlines")
	}
	
}
