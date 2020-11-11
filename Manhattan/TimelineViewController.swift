//
//  TimelineViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit
import Templeton

protocol TimelineDelegate: class  {
	func outlineSelectionDidChange(_: TimelineViewController, outline: Outline)
}

class TimelineViewController: UICollectionViewController {
	
	weak var delegate: TimelineDelegate?
	var outlineProvider: OutlineProvider? {
		didSet {
			updateUI()
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		}

		updateUI()
	}

	// MARK: Actions
	
	@objc func createOutline(_ sender: Any?) {
	}

}

private extension TimelineViewController {
	
	private func updateUI() {
		guard isViewLoaded else { return }
		navigationItem.title = outlineProvider?.name
		view.window?.windowScene?.title = outlineProvider?.name
	}
	
}
