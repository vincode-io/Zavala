//
//  DetailViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import Templeton

class DetailViewController: UIViewController {

	var outline: Outline? {
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
	@objc func toggleOutlineIsFavorite(_ sender: Any?) {
		
	}
	
}

private extension DetailViewController {
	
	private func updateUI() {
		guard isViewLoaded else { return }
		navigationItem.title = outline?.name
	}
	
}
