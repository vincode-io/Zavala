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

class SettingsViewController: UITableViewController {

	@IBOutlet weak var enableLocalAccountSwitch: UISwitch!
	@IBOutlet weak var enableCloudKitSwitch: UISwitch!
	
	@IBOutlet weak var ownerNameTextField: UITextField!
	@IBOutlet weak var ownerEmailTextField: UITextField!
	@IBOutlet weak var ownerURLTextField: UITextField!
	
	private var mainSplitViewController: MainSplitViewController? {
		return (presentingViewController as? MainSplitViewController)
	}
	
	override func viewDidLoad() {
		// This hack mostly works around a bug in static tables with dynamic type.  See: https://spin.atomicobject.com/2018/10/15/dynamic-type-static-uitableview/
		NotificationCenter.default.removeObserver(tableView!, name: UIContentSizeCategory.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)

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

		let buildLabel = NonIntrinsicLabel(frame: CGRect(x: 32.0, y: 0.0, width: 0.0, height: 0.0))
		buildLabel.font = UIFont.systemFont(ofSize: 11.0)
		buildLabel.textColor = UIColor.gray
		buildLabel.text = "\(Bundle.main.appName) \(Bundle.main.versionNumber) (Build \(Bundle.main.buildNumber))"
		buildLabel.sizeToFit()

		let copyrightLabel = NonIntrinsicLabel()
		copyrightLabel.numberOfLines = 0
		copyrightLabel.lineBreakMode = .byWordWrapping
		copyrightLabel.font = UIFont.systemFont(ofSize: 11.0)
		copyrightLabel.textColor = UIColor.gray
		copyrightLabel.text = Bundle.main.copyright
		let copyrightSize = copyrightLabel.sizeThatFits(CGSize(width: tableView.bounds.width - 32, height: CGFloat.infinity))
		copyrightLabel.frame = CGRect(x: 32, y: buildLabel.frame.maxY + 8, width: copyrightSize.width, height: copyrightSize.height)

		let width = max(copyrightLabel.frame.width, buildLabel.frame.width)
		let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: copyrightLabel.frame.maxY + 10))
		wrapperView.addSubview(copyrightLabel)
		wrapperView.addSubview(buildLabel)
		tableView.tableFooterView = wrapperView
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
		
		if indexPath.section == 0 && indexPath.row == 0 {
			if traitCollection.userInterfaceIdiom == .phone {
				cell.textLabel?.text = L10n.enableOnMyIPhone
			} else {
				cell.textLabel?.text = L10n.enableOnMyIPad
			}
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.section == 3 else { return }
		
		switch indexPath.row {
		case 0:
			openURL(AppAssets.releaseNotesURL)
		case 1:
			openURL(AppAssets.githubRepositoryURL)
		case 2:
			openURL(AppAssets.bugTrackerURL)
		case 3:
			openURL(AppAssets.acknowledgementsURL)
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
		
		let deleteAction = UIAlertAction(title: L10n.remove, style: .default) { [weak self] action in
			guard let self = self else { return }
			AppDefaults.shared.enableCloudKit = self.enableCloudKitSwitch.isOn
		}
		alertController.addAction(deleteAction)
		alertController.preferredAction = deleteAction
		
		present(alertController, animated: true)
	}
	
}


// MARK: Private

private extension SettingsViewController {
	
	func openURL(_ urlString: String) {
		let vc = SFSafariViewController(url: URL(string: urlString)!)
		vc.modalPresentationStyle = .pageSheet
		present(vc, animated: true)
	}
	
}
