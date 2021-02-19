//
//  AppKitWrapper.swift
//  AppKitPlugin
//
//  Created by Maurice Parker on 1/5/21.
//

import AppKit
import os.log
import Sparkle

@objc class AppKitWrapper: NSResponder, AppKitPlugin, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {

	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SparkleWrapper")
	
	private var softwareUpdater: SPUUpdater!

	private var preferencesWindowController: NSWindowController?

	func start() {
		let hostBundle = Bundle.main
		let updateDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: self)
		self.softwareUpdater = SPUUpdater(hostBundle: hostBundle, applicationBundle: hostBundle, userDriver: updateDriver, delegate: self)

		do {
			try self.softwareUpdater.start()
		} catch {
			os_log(.error, log: log, "Failed to start software updater with error: %@.", error.localizedDescription)
		}
	}
	
	func checkForUpdates() {
		softwareUpdater.checkForUpdates()
	}
	
	func showPreferences() {
		if preferencesWindowController == nil {
			let bundle = Bundle(identifier: "io.vincode.AppKitPlugin")!
			let storyboard = NSStoryboard(name: NSStoryboard.Name("Preferences"), bundle: bundle)
			preferencesWindowController = storyboard.instantiateInitialController()! as NSWindowController
		}
		preferencesWindowController!.showWindow(self)
	}
}
