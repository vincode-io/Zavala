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
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
	@IBAction func delete(_ sender: Any) {
	}
	
	@IBAction func add(_ sender: Any) {
	}
}

// MARK: - NSTableViewDataSource

extension FontPreferencesViewController: NSTableViewDataSource {

	func numberOfRows(in tableView: NSTableView) -> Int {
		return 0
	}

	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		return nil
	}
}

// MARK: - NSTableViewDelegate

extension FontPreferencesViewController: NSTableViewDelegate {

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
//		if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Cell"), owner: nil) as? NSTableViewCell {
//
//			let account = sortedAccounts[row]
//			cell.textField?.stringValue = account.nameForDisplay
//			cell.imageView?.image = account.smallIcon?.image
//
//			if account.type == .feedbin {
//				cell.isImageTemplateCapable = false
//			}
//
//			return cell
//		}
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
