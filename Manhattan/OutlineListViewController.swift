//
//  OutlineListViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit
import Templeton

class OutlineListViewController: UICollectionViewController {

	var outlineProvider: OutlineProvider?
	
    override func viewDidLoad() {
        super.viewDidLoad()

    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		#if targetEnvironment(macCatalyst)
		navigationController?.setNavigationBarHidden(true, animated: animated)
		#endif
	}
}
