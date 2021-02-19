//
//  GeneralPrefencesViewController.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 9/3/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//

import AppKit

final class GeneralPreferencesViewController: NSViewController {

	@IBOutlet weak var hideLocalAccount: NSButton!
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

	@IBAction func toggleHideLocalAccount(_ sender: Any) {
		AppDefaults.shared.hideLocalAccount = hideLocalAccount.state == .on
	}
	
	@IBAction func toggleEnableCloudKit(_ sender: Any) {
		AppDefaults.shared.enableCloudKit = enableCloudKit.state == .on
	}
	
}

// MARK: - Private

private extension GeneralPreferencesViewController {

	func commonInit() {
		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillBecomeActive(_:)), name: NSApplication.willBecomeActiveNotification, object: nil)
	}

	func updateUI() {
		hideLocalAccount.state = AppDefaults.shared.hideLocalAccount ? .on : .off
		enableCloudKit.state = AppDefaults.shared.enableCloudKit ? .on : .off
	}

}
