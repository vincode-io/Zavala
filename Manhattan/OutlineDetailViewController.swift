//
//  OutlineDetailViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit

class OutlineDetailViewController: UIViewController {

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
