//
//  SparkleWrapper.swift
//  SparklePlugin
//
//  Created by Maurice Parker on 1/5/21.
//

import AppKit
import Sparkle

@objc class SparkleWrapper: NSResponder, SparklePlugin, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
	
	private var softwareUpdater: SPUUpdater!

	func start() {
		let hostBundle = Bundle.main
		let updateDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: self)
		self.softwareUpdater = SPUUpdater(hostBundle: hostBundle, applicationBundle: hostBundle, userDriver: updateDriver, delegate: self)

		do {
			try self.softwareUpdater.start()
		} catch {
			NSLog("Failed to start software updater with error: \(error)")
		}
	}
	
	func checkForUpdates() {
		softwareUpdater.checkForUpdates()
	}
	
}
