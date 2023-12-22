//
//  AboutViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/12/23.
//

import UIKit
import SwiftUI

class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

		let aboutViewController = UIHostingController(rootView: AboutView())
		
		aboutViewController.view.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(aboutViewController.view)
		addChild(aboutViewController)
		NSLayoutConstraint.activate([
			view.leadingAnchor.constraint(equalTo: aboutViewController.view.leadingAnchor),
			view.trailingAnchor.constraint(equalTo: aboutViewController.view.trailingAnchor),
			view.topAnchor.constraint(equalTo: aboutViewController.view.topAnchor),
			view.bottomAnchor.constraint(equalTo: aboutViewController.view.bottomAnchor)
		])
    }

	override func viewDidAppear(_ animated: Bool) {
		#if targetEnvironment(macCatalyst)
		appDelegate.appKitPlugin?.configureShowAbout(view.window?.nsWindow)
		#endif
	}

}
