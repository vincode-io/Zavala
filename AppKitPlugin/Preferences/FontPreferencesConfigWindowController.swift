//
//  FontPreferencesConfigWindowController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/24/21.
//

import Cocoa

protocol FontPreferencesConfigWindowControllerDelegate: AnyObject {
	func didUpdateConfig(field: OutlineFontField, config: OutlineFontConfig)
}

class FontPreferencesConfigWindowController: NSWindowController {

	var field: OutlineFontField?
	var config: OutlineFontConfig?
	weak var delegate: FontPreferencesConfigWindowControllerDelegate?
	
	@IBOutlet weak var fieldNameLabel: NSTextField!
	@IBOutlet weak var fontNamePopUpButton: NSPopUpButton!
	@IBOutlet weak var fontSizeLabel: NSTextField!
	@IBOutlet weak var fontSizeStepper: NSStepper!
	@IBOutlet weak var sampleTextLabel: NSTextField!
	
	private weak var hostWindow: NSWindow?

	convenience init() {
		self.init(windowNibName: NSNib.Name("FontPreferencesConfig"))
	}

	override func windowDidLoad() {
		super.windowDidLoad()
		
		fieldNameLabel.stringValue = field?.displayName ?? ""
	}
	
	// MARK: API
	
	func runSheetOnWindow(_ hostWindow: NSWindow) {
		self.hostWindow = hostWindow
		hostWindow.beginSheet(window!)
	}

	// MARK: Actions
	
	@IBAction func cancel(_ sender: Any) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.cancel)
	}
	
	@IBAction func submit(_ sender: Any) {
		
		// TODO: get values from fields for config and call delegate
		
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.OK)
	}
	
}
