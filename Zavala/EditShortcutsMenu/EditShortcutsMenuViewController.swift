//
//  EditShortcutsMenuViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/3/26.
//

import UIKit
import SwiftUI

class EditShortcutsMenuViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

		let hostingController = UIHostingController(rootView: EditShortcutsMenuView())
		view.addChildAndPin(hostingController.view)
		addChild(hostingController)
    }

}
