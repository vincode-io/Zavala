//
//  SettingsViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 12/29/23.
//

import UIKit
import SwiftUI

class SettingsViewController: UIViewController {

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		let settingsViewController = UIHostingController(rootView: SettingsView())
		view.addChildAndPin(settingsViewController.view)
		addChild(settingsViewController)

		appDelegate.appKitPlugin?.configureSettings(view.window?.nsWindow)
	}

}
