//
//  OutlineGetInfoViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/10/21.
//

import UIKit
import SwiftUI
import VinOutlineKit

class OutlineGetInfoViewController: UIViewController {

	override var keyCommands: [UIKeyCommand]? {
		[
			UIKeyCommand(action: #selector(cancel(_:)), input: UIKeyCommand.inputEscape)
		]
	}


	weak var outline: Outline?
	var getInfoViewModel: GetInfoViewModel!

	@IBOutlet weak var formView: UIView!
	
	@IBOutlet weak var macCancelButton: UIButton!
	@IBOutlet weak var macSubmitButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		#if targetEnvironment(macCatalyst)
			macSubmitButton.role = .primary
			formView.heightAnchor.constraint(equalToConstant: 360).isActive = true
		#else
			navigationItem.title = outline?.title
			formView.heightAnchor.constraint(equalToConstant: 475).isActive = true
			macCancelButton.isHidden = true
			macSubmitButton.isHidden = true
		#endif

		getInfoViewModel = GetInfoViewModel(outline: outline)
		let getInfoView = GetInfoView(getInfoViewModel: getInfoViewModel)
		
		let hostingController = UIHostingController(rootView: getInfoView)
		formView.addChildAndPin(hostingController.view)
		addChild(hostingController)
	}
	
	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func submit(_ sender: Any) {
		submitAndDismiss()
	}
	
}

// MARK: Helpers

private extension OutlineGetInfoViewController {
	
	func submitAndDismiss() {
		outline?.update(autoLinkingEnabled: getInfoViewModel.autoLinkingEnabled,
						ownerName: getInfoViewModel.ownerName,
						ownerEmail: getInfoViewModel.ownerEmail,
						ownerURL: getInfoViewModel.ownerURL)
		dismiss(animated: true)
	}
	
}
