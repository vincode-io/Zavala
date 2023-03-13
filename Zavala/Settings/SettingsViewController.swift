//
//  SettingsViewController.swift
//  NetNewsWire-iOS
//
//  Created by Maurice Parker on 4/24/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import UIKit
import CoreServices
import SafariServices
import SwiftUI

class SettingsViewController: UITableViewController {

	@IBOutlet weak var enableLocalAccountSwitch: UISwitch!
	@IBOutlet weak var enableCloudKitSwitch: UISwitch!
	
	@IBOutlet weak var ownerNameTextField: UITextField!
	@IBOutlet weak var ownerEmailTextField: UITextField!
	@IBOutlet weak var ownerURLTextField: UITextField!
	
	private var mainSplitViewController: MainSplitViewController? {
		return (presentingViewController as? MainSplitViewController)
	}
	
	private var currentPalette = AppDefaults.shared.userInterfaceColorPalette
	
	override func viewDidLoad() {
		// This hack mostly works around a bug in static tables with dynamic type.  See: https://spin.atomicobject.com/2018/10/15/dynamic-type-static-uitableview/
		NotificationCenter.default.removeObserver(tableView!, name: UIContentSizeCategory.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)

		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 44
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		enableLocalAccountSwitch.isOn = AppDefaults.shared.enableLocalAccount
		enableCloudKitSwitch.isOn = AppDefaults.shared.enableCloudKit
		enableCloudKitSwitch.isEnabled = !AppDefaults.shared.isDeveloperBuild
		
		ownerNameTextField.text = AppDefaults.shared.ownerName
		ownerEmailTextField.text = AppDefaults.shared.ownerEmail
		ownerURLTextField.text = AppDefaults.shared.ownerURL
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		AppDefaults.shared.ownerName = ownerNameTextField.text
		AppDefaults.shared.ownerEmail = ownerEmailTextField.text
		AppDefaults.shared.ownerURL = ownerURLTextField.text
	}
	
	// MARK: UITableView
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = super.tableView(tableView, cellForRowAt: indexPath)
	
		switch (indexPath.section, indexPath.row) {
		case (0, 0):
			if traitCollection.userInterfaceIdiom == .phone {
				cell.textLabel?.text = L10n.enableOnMyIPhone
			} else {
				cell.textLabel?.text = L10n.enableOnMyIPad
			}
		case (2, 0):
			cell.detailTextLabel?.text = AppDefaults.shared.userInterfaceColorPalette.description
		default:
			break
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.section == 3 else { return }
		
		switch indexPath.row {
		case 0:
			let aboutViewController = UIHostingController(rootView: AboutView())
			aboutViewController.modalPresentationStyle = .formSheet
			let size = UIFontMetrics(forTextStyle: .body).scaledValue(for: 350)
			aboutViewController.preferredContentSize = .init(width: size, height: size)
			present(aboutViewController, animated: true)
		case 1:
			openURL(AppAssets.helpURL)
		case 2:
			UIApplication.shared.open(AppAssets.reportAnIssueURL, options: [:])
		default:
			break
		}
		
		tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return false
	}

	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
	}
	
	// MARK: Notifications
	
	@objc func contentSizeCategoryDidChange() {
		tableView.reloadData()
	}

	@objc func userDefaultsDidChange() {
		if currentPalette != AppDefaults.shared.userInterfaceColorPalette {
			currentPalette = AppDefaults.shared.userInterfaceColorPalette
			tableView.reloadData()
		}
	}

	// MARK: Actions
	
	@IBAction func done(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func switchEnableLocalAccount(_ sender: Any) {
		AppDefaults.shared.enableLocalAccount = enableLocalAccountSwitch.isOn
	}
	
	@IBAction func switchEnableCloudKit(_ sender: Any) {
		guard !enableCloudKitSwitch.isOn else {
			AppDefaults.shared.enableCloudKit = enableCloudKitSwitch.isOn
			return
		}
		
		let alertController = UIAlertController(title: L10n.removeCloudKitTitle, message: L10n.removeCloudKitMessage, preferredStyle: .alert)
		
		let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel) { [weak self] action in
			self?.enableCloudKitSwitch.isOn = true
		}
		alertController.addAction(cancelAction)
		
		let deleteAction = UIAlertAction(title: L10n.remove, style: .destructive) { [weak self] action in
			guard let self = self else { return }
			AppDefaults.shared.enableCloudKit = self.enableCloudKitSwitch.isOn
		}
		alertController.addAction(deleteAction)
		alertController.preferredAction = deleteAction
		
		present(alertController, animated: true)
	}
	
}


// MARK: Helpers

private extension SettingsViewController {
	
	func openURL(_ urlString: String) {
		let vc = SFSafariViewController(url: URL(string: urlString)!)
		vc.modalPresentationStyle = .pageSheet
		present(vc, animated: true)
	}
	
}
