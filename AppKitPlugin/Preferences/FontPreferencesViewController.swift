//
//  FontPreferencesViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/22/21.
//

import Cocoa

class FontPreferencesViewController: NSViewController {

	@IBOutlet weak var tableView: NSTableView!
	@IBOutlet weak var deleteButton: NSButton!
	
	var fontDefaults: OutlineFontDefaults?
	var sortedFields: [OutlineFontField]?
	
	override func viewDidLoad() {
        super.viewDidLoad()

		fontDefaults = AppDefaults.shared.outlineFonts
		sortedFields = fontDefaults?.sortedFields
		tableView.reloadData()
	}
    
	@IBAction func delete(_ sender: Any) {
	}
	
	@IBAction func add(_ sender: Any) {
	}
	
	@IBAction func restoreDefaults(_ sender: Any) {
	}
}

// MARK: - NSTableViewDataSource

extension FontPreferencesViewController: NSTableViewDataSource {

	func numberOfRows(in tableView: NSTableView) -> Int {
		return sortedFields?.count ?? 0
	}

}

// MARK: - NSTableViewDelegate

extension FontPreferencesViewController: NSTableViewDelegate {

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Cell"), owner: nil) as? NSTableCellView {
			if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "Field") {
				switch sortedFields?[row] {
				case .title:
					cell.textField?.stringValue = L10n.title
				case .tags:
					cell.textField?.stringValue =  L10n.tags
				case .rowTopic(let level):
					cell.textField?.stringValue = L10n.topicLevel(level)
				case .rowNote(let level):
					cell.textField?.stringValue = L10n.noteLevel(level)
				case .backlinks:
					cell.textField?.stringValue =  L10n.backlinks
				default:
					break
				}
			} else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "Font") {
				if let field = sortedFields?[row], let fontConfig = fontDefaults?.rowFontConfigs[field] {
					cell.textField?.stringValue = "\(fontConfig.name) - \(fontConfig.size)"
				}
			}

			return cell
		}
		return nil
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		
		if tableView.selectedRow == -1 {
			deleteButton.isEnabled = false
			return
		} else {
			deleteButton.isEnabled = true
		}
		
	}
	
}
