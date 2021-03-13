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
			UIKeyCommand(action: #selector(cancel(_:)), input: UIKeyCommand.inputEscape),
			UIKeyCommand(action: #selector(submit(_:)), input: "\r"),
		]
	}

	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func submit(_ sender: Any) {
	}
	
}
