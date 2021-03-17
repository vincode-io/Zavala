//
//  AppKitWrapper.swift
//  AppKitPlugin
//
//  Created by Maurice Parker on 1/5/21.
//

import AppKit
import os.log

#if MAC_TEST
import Sparkle
#else
protocol SPUStandardUserDriverDelegate {}
protocol SPUUpdaterDelegate {}
#endif

@objc class AppKitWrapper: NSResponder, AppKitPlugin, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {

	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SparkleWrapper")
	
	#if MAC_TEST
	private var softwareUpdater: SPUUpdater!
	#endif

	private var preferencesWindowController: NSWindowController?

	func start() {
		#if MAC_TEST
		let hostBundle = Bundle.main
		let updateDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: self)
		self.softwareUpdater = SPUUpdater(hostBundle: hostBundle, applicationBundle: hostBundle, userDriver: updateDriver, delegate: self)

		do {
			try self.softwareUpdater.start()
		} catch {
			os_log(.error, log: log, "Failed to start software updater with error: %@.", error.localizedDescription)
		}
		#endif
	}
	
	func checkForUpdates() {
		#if MAC_TEST
		softwareUpdater.checkForUpdates()
		#endif
	}
	
	func showPreferences() {
		if preferencesWindowController == nil {
			let bundle = Bundle(for: type(of: self))
			let storyboard = NSStoryboard(name: NSStoryboard.Name("Preferences"), bundle: bundle)
			preferencesWindowController = storyboard.instantiateInitialController()! as NSWindowController
		}
		preferencesWindowController!.showWindow(self)
	}
}
