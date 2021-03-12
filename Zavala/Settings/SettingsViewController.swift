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
		
		let buildLabel = NonIntrinsicLabel(frame: CGRect(x: 32.0, y: 0.0, width: 0.0, height: 0.0))
		buildLabel.font = UIFont.systemFont(ofSize: 11.0)
		buildLabel.textColor = UIColor.gray
		buildLabel.text = "\(Bundle.main.appName) \(Bundle.main.versionNumber) (Build \(Bundle.main.buildNumber))"
		buildLabel.sizeToFit()
		
		let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: buildLabel.frame.width, height: buildLabel.frame.height + 10.0))
		wrapperView.addSubview(buildLabel)
		tableView.tableFooterView = wrapperView
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
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
		guard indexPath.section == 1 else { return }
		
		switch indexPath.row {
		case 0:
			openURL(AppAssets.releaseNotesURL)
		case 1:
			openURL(AppAssets.githubRepositoryURL)
		case 2:
			openURL(AppAssets.bugTrackerURL)
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
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
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
		
		let removeTitle = NSLocalizedString("Remove", comment: "Remove")
		let deleteAction = UIAlertAction(title: removeTitle, style: .default) { [weak self] action in
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
