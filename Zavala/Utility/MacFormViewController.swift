//
//  MacFormViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/11/20.
//

import UIKit

class MacFormViewController: UIViewController {

	override var keyCommands: [UIKeyCommand]? {
		[
			UIKeyCommand(action: #selector(cancel(_:)), input: UIKeyCommand.inputEscape)
		]
	}

	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
}
