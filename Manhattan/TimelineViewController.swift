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

private extension TimelineViewController {
	
	private func updateUI() {
		guard isViewLoaded else { return }
		view.window?.windowScene?.title = outlineProvider?.name
	}
	
}
