//
//  RowSpacingTableViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 12/10/23.
//

import UIKit

class RowSpacingTableViewController: UITableViewController {

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return DefaultsSize.allCases.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		let size = DefaultsSize.allCases[indexPath.row]
		cell.textLabel?.text = String(describing: size)
		if size == AppDefaults.shared.rowSpacingSize {
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let colorPalette = DefaultsSize(rawValue: indexPath.row) {
			AppDefaults.shared.rowSpacingSize = colorPalette
		}
		navigationController?.popViewController(animated: true)
	}

}
