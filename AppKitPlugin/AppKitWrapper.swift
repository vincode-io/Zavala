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
	
	private weak var delegate: AppKitPluginDelegate?
	
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SparkleWrapper")
	
	#if MAC_TEST
	private var softwareUpdater: SPUUpdater!
	#endif

	private var movementMonitor: RSAppMovementMonitor? = nil
	private var preferencesWindowController: NSWindowController?

	func setDelegate(_ delegate: AppKitPluginDelegate?) {
		self.delegate = delegate
	}
	
	func start() {
		movementMonitor = RSAppMovementMonitor()
		
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
	
	func importOPML() {
		let panel = NSOpenPanel()
		panel.canDownloadUbiquitousContents = true
		panel.canResolveUbiquitousConflicts = true
		panel.canChooseFiles = true
		panel.allowsMultipleSelection = false
		panel.canChooseDirectories = false
		panel.resolvesAliases = true
		panel.allowedFileTypes = ["opml"]
		panel.allowsOtherFileTypes = false
		
		let modalResult = panel.runModal()
		if modalResult == NSApplication.ModalResponse.OK, let url = panel.url {
			delegate?.importOPML(url)
		}
	}

	func configureOpenQuickly(_ window: NSObject?) {
		guard let nsWindow = window as? NSWindow else { return }
		nsWindow.title = L10n.openQuickly
		nsWindow.titlebarAppearsTransparent = true
		nsWindow.standardWindowButton(.zoomButton)?.isHidden = true
		nsWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
	}

}
