//
//  FontAndColorPreferencesViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/22/21.
//

import Cocoa

class FontAndColorPreferencesViewController: NSViewController {

	@IBOutlet weak var rowIndentingPopUpButton: NSPopUpButton!
	@IBOutlet weak var rowSpacingPopUpButton: NSPopUpButton!
	@IBOutlet weak var colorPalettePopUpButton: NSPopUpButton!
	@IBOutlet weak var tableView: NSTableView!
	@IBOutlet weak var addButton: NSButton!
	@IBOutlet weak var deleteButton: NSButton!
	@IBOutlet weak var restoreDefaultsButton: NSButton!
	
	var fontDefaults: OutlineFontDefaults?
	var sortedFields: [OutlineFontField]?
	
	var selectedField: OutlineFontField? {
		guard tableView.selectedRow != -1 else { return nil }
		return sortedFields?[tableView.selectedRow]
	}

	var windowController: NSWindowController?

	override func viewDidLoad() {
        super.viewDidLoad()

		rowIndentingPopUpButton.selectItem(withTag: AppDefaults.shared.rowIndentSize.rawValue)
		rowSpacingPopUpButton.selectItem(withTag: AppDefaults.shared.rowSpacingSize.rawValue)
		colorPalettePopUpButton.selectItem(withTag: AppDefaults.shared.userInterfaceColorPalette.rawValue)
		fontDefaults = AppDefaults.shared.outlineFonts
		sortedFields = fontDefaults?.sortedFields
		
		tableView.doubleAction = #selector(editFontDefault(_:))
		tableView.reloadData()
		updateUI()
		
		addButton.sendAction(on: .leftMouseDown)
	}
    
	@IBAction func changeRowIndenting(_ sender: Any) {
		if let tag = rowIndentingPopUpButton.selectedItem?.tag, let size = DefaultsSize(rawValue: tag) {
			AppDefaults.shared.rowIndentSize = size
		}
	}
	
	@IBAction func changeRowSpacing(_ sender: Any) {
		if let tag = rowSpacingPopUpButton.selectedItem?.tag, let size = DefaultsSize(rawValue: tag) {
			AppDefaults.shared.rowSpacingSize = size
		}
	}
	
	@IBAction func changeColorPalette(_ sender: Any) {
		if let tag = colorPalettePopUpButton.selectedItem?.tag, let palette = UserInterfaceColorPalette(rawValue: tag) {
			AppDefaults.shared.userInterfaceColorPalette = palette
		}
	}
	
	@IBAction func delete(_ sender: Any) {
		if let field = selectedField {
			fontDefaults?.rowFontConfigs.removeValue(forKey: field)
			AppDefaults.shared.outlineFonts = fontDefaults
		}
		sortedFields = fontDefaults?.sortedFields
		tableView.reloadData()
	}
	
	@IBAction func add(_ sender: Any) {
		let menu = NSMenu()
		
		let newWebFeedItem = NSMenuItem()
		newWebFeedItem.title = AppStringAssets.addTopicLevelControlLabel
		newWebFeedItem.action = #selector(addTopicLevel(_:))
		menu.addItem(newWebFeedItem)
		
		let newRedditFeedItem = NSMenuItem()
		newRedditFeedItem.title = AppStringAssets.addNoteLevelControlLabel
		newRedditFeedItem.action = #selector(addNoteLevel(_:))
		menu.addItem(newRedditFeedItem)

		let menuAt = NSPoint(x: addButton.frame.minX, y: addButton.frame.minY)
		menu.popUp(positioning: newWebFeedItem, at: menuAt, in: view)
	}
	
	@IBAction func restoreDefaults(_ sender: Any) {
		let alert = NSAlert()
		alert.alertStyle = .warning
		alert.messageText = AppStringAssets.restoreDefaultsMessage
		alert.informativeText = AppStringAssets.restoreDefaultsInformative
		alert.addButton(withTitle: AppStringAssets.restoreControlLabel)
		alert.addButton(withTitle: AppStringAssets.cancelControlLabel)
			
		alert.beginSheetModal(for: view.window!) { [weak self] result in
			if result == NSApplication.ModalResponse.alertFirstButtonReturn {
				guard let self else { return }
				self.fontDefaults = OutlineFontDefaults.defaults
				AppDefaults.shared.outlineFonts = self.fontDefaults
				self.sortedFields = self.fontDefaults?.sortedFields
				self.tableView.reloadData()
				self.updateUI()
			}
		}
	}

	@objc func addTopicLevel(_ sender: Any) {
		guard let (field, config) = fontDefaults?.nextTopicDefault else { return }
		showFontConfig(field: field, config: config)
	}
	
	@objc func addNoteLevel(_ sender: Any) {
		guard let (field, config) = fontDefaults?.nextNoteDefault else { return }
		showFontConfig(field: field, config: config)
	}
	
	@objc func editFontDefault(_ sender: Any) {
		guard let field = selectedField,
			  let config = fontDefaults?.rowFontConfigs[field] else { return }
		showFontConfig(field: field, config: config)

	}
	
}

// MARK: - NSTableViewDataSource

extension FontAndColorPreferencesViewController: NSTableViewDataSource {

	func numberOfRows(in tableView: NSTableView) -> Int {
		return sortedFields?.count ?? 0
	}

}

// MARK: - NSTableViewDelegate

extension FontAndColorPreferencesViewController: NSTableViewDelegate {

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Cell"), owner: nil) as? NSTableCellView {
			if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "Field") {
				cell.textField?.stringValue = sortedFields?[row].displayName ?? ""
			} else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "Font") {
				if let field = sortedFields?[row], let fontConfig = fontDefaults?.rowFontConfigs[field] {
					cell.textField?.stringValue = fontConfig.displayName
				}
			}

			return cell
		}
		return nil
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		
		if let field = selectedField {
			switch field {
			case .rowTopic(let level):
				deleteButton.isEnabled = level > 1 && level == fontDefaults?.deepestTopicLevel
			case .rowNote(let level):
				deleteButton.isEnabled = level > 1 && level == fontDefaults?.deepestNoteLevel
			default:
				deleteButton.isEnabled = false
			}
			return
		} else {
			deleteButton.isEnabled = false
		}
		
	}
	
}

// MARK: FontPreferencesConfigViewControllerDelegate

extension FontAndColorPreferencesViewController: FontAndColorPreferencesConfigWindowControllerDelegate {
	
	func didUpdateConfig(field: OutlineFontField, config: OutlineFontConfig) {
		fontDefaults?.rowFontConfigs[field] = config
		AppDefaults.shared.outlineFonts = fontDefaults
		sortedFields = fontDefaults?.sortedFields
		tableView.reloadData()
		updateUI()
	}
	
}

// MARK: Helpers

extension FontAndColorPreferencesViewController {

	private func updateUI() {
		restoreDefaultsButton.isEnabled = fontDefaults != OutlineFontDefaults.defaults
	}
	
	private func showFontConfig(field: OutlineFontField?, config: OutlineFontConfig?) {
		let fontConfigWindowController = FontAndColorPreferencesConfigWindowController()
		fontConfigWindowController.field = field
		fontConfigWindowController.config = config
		fontConfigWindowController.delegate = self
		fontConfigWindowController.runSheetOnWindow(self.view.window!)
		windowController = fontConfigWindowController
	}

}

