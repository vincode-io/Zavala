//
//  FontAndColorPreferencesConfigWindowController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/24/21.
//

import Cocoa

protocol FontAndColorPreferencesConfigWindowControllerDelegate: AnyObject {
	func didUpdateConfig(field: OutlineFontField, config: OutlineFontConfig)
}

class FontAndColorPreferencesConfigWindowController: NSWindowController {

	var field: OutlineFontField?
	var config: OutlineFontConfig?
	weak var delegate: FontAndColorPreferencesConfigWindowControllerDelegate?
	
	@IBOutlet weak var fieldNameLabel: NSTextField!
	@IBOutlet weak var fontNamePopUpButton: NSPopUpButton!
	@IBOutlet weak var fontSizeLabel: NSTextField!
	@IBOutlet weak var fontSizeStepper: NSStepper!
	@IBOutlet weak var sampleTextLabel: NSTextField!
	
	private weak var hostWindow: NSWindow?

	convenience init() {
		self.init(windowNibName: NSNib.Name("FontAndColorPreferencesConfig"))
	}

	override func windowDidLoad() {
		super.windowDidLoad()
		
		fieldNameLabel.stringValue = field?.displayName ?? ""

		guard let config = config else { return }

		fontNamePopUpButton.menu?.removeAllItems()
		for fontName in NSFontManager.shared.availableFontFamilies {
			let item = NSMenuItem(title: fontName, action: nil, keyEquivalent: "")
			fontNamePopUpButton.menu?.addItem(item)
		}
		fontNamePopUpButton.selectItem(withTitle: config.name)
		fontNamePopUpButton.target = self
		fontNamePopUpButton.action = #selector(changeFontName(_:))
		
		fontSizeLabel.stringValue = String(config.size)
		fontSizeStepper.integerValue = config.size
		fontSizeStepper.target = self
		fontSizeStepper.action = #selector(changeFontSize(_:))

		updateUI()
	}
	
	// MARK: API
	
	func runSheetOnWindow(_ hostWindow: NSWindow) {
		self.hostWindow = hostWindow
		hostWindow.beginSheet(window!)
	}

	// MARK: Actions
	
	@objc func changeFontName(_ sender: Any) {
		config?.name = fontNamePopUpButton.selectedItem?.title ?? ""
		updateUI()
	}

	@objc func changeFontSize(_ sender: Any) {
		config?.size = fontSizeStepper.integerValue
		fontSizeLabel.stringValue = String(fontSizeStepper.integerValue)
		updateUI()
	}

	@IBAction func cancel(_ sender: Any) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.cancel)
	}
	
	@IBAction func submit(_ sender: Any) {
		guard let field = field, let config = config else { return }
		delegate?.didUpdateConfig(field: field, config: config)
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.OK)
	}
	
}

// MARK: Helpers

extension FontAndColorPreferencesConfigWindowController {

	private func updateUI() {
		guard let config = config, let font = NSFont(name: config.name, size: CGFloat(config.size)) else { return }
		sampleTextLabel.font = font
	}
	
}
