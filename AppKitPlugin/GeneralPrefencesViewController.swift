//
//  GeneralPrefencesViewController.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 9/3/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//

import AppKit

final class GeneralPreferencesViewController: NSViewController {

	@IBOutlet weak var enableLocalAccount: NSButton!
	@IBOutlet weak var enableCloudKit: NSButton!
	
	public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		commonInit()
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}

	override func viewWillAppear() {
		super.viewWillAppear()
		updateUI()
	}

	// MARK: - Notifications

	@objc func applicationWillBecomeActive(_ note: Notification) {
		updateUI()
	}

	// MARK: - Actions

	@IBAction func toggleEnableLocalAccount(_ sender: Any) {
		AppDefaults.shared.enableLocalAccount = enableLocalAccount.state == .on
	}
	
	@IBAction func toggleEnableCloudKit(_ sender: Any) {
		guard enableCloudKit.state == .off else {
			AppDefaults.shared.enableCloudKit = true
			return
		}
		
		let alert = NSAlert()
		alert.alertStyle = .warning
		alert.messageText = L10n.removeCloudKitTitle
		alert.informativeText = L10n.removeCloudKitMessage
		
		alert.addButton(withTitle: L10n.remove)
		alert.addButton(withTitle: L10n.cancel)
			
		alert.beginSheetModal(for: view.window!) { [weak self] result in
			if result == NSApplication.ModalResponse.alertFirstButtonReturn {
				AppDefaults.shared.enableCloudKit = false
			} else {
				self?.enableCloudKit.state = .on
			}
		}
	}
	
}

// MARK: - Private

private extension GeneralPreferencesViewController {

	func commonInit() {
		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillBecomeActive(_:)), name: NSApplication.willBecomeActiveNotification, object: nil)
	}

	func updateUI() {
		enableLocalAccount.state = AppDefaults.shared.enableLocalAccount ? .on : .off
		enableCloudKit.state = AppDefaults.shared.enableCloudKit ? .on : .off
		enableCloudKit.isEnabled = !AppDefaults.shared.isDeveloperBuild
	}

}
