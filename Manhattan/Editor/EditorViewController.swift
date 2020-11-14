//
//  DetailViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import Templeton

class EditorViewController: UICollectionViewController {

	var outline: Outline? {
		didSet {
			guard isViewLoaded else { return }
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

private extension EditorViewController {
	
	private func updateUI() {
		navigationItem.title = outline?.name
		navigationItem.largeTitleDisplayMode = .never
	}
	
}
