//
//  AppKitWrapper.swift
//  AppKitPlugin
//
//  Created by Maurice Parker on 1/5/21.
//

import AppKit
import os.log

@objc class AppKitWrapper: NSResponder, AppKitPlugin {
	
	private weak var delegate: AppKitPluginDelegate?
	
	private var movementMonitor: RSAppMovementMonitor? = nil
	private var preferencesWindowController: NSWindowController?

	func setDelegate(_ delegate: AppKitPluginDelegate?) {
		self.delegate = delegate
	}
	
	func start() {
		movementMonitor = RSAppMovementMonitor()
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

	func configureWindowSize(_ window: NSObject?, x: Double, y: Double, width: Double, height: Double) {
		guard let nsWindow = window as? NSWindow else { return }
		nsWindow.setFrame(CGRect(x: x, y: y, width: width, height: height), display: true)
	}

	func configureWindowAspectRatio(_ window: NSObject?, width: Double, height: Double) {
		guard let nsWindow = window as? NSWindow else { return }
		nsWindow.aspectRatio = CGSize(width: 1.0, height: height / width)
	}

	func updateAppearance(_ window: NSObject?) {
		guard let nsWindow = window as? NSWindow else { return }

		switch AppDefaults.shared.userInterfaceColorPalette {
		case .light:
			nsWindow.appearance = NSAppearance(named: .aqua)
		case .dark:
			nsWindow.appearance = NSAppearance(named: .darkAqua)
		default:
			nsWindow.appearance = nil
		}
	}
	
	func clearRecentDocuments() {
		NSDocumentController.shared.clearRecentDocuments(nil)
	}

	func activateIgnoringOtherApps() {
		NSApplication.shared.activate(ignoringOtherApps: true)
	}
	
	func refuseLaunchIfOtherIsRunning() {
		let runningApp = NSWorkspace.shared.runningApplications
			.filter { item in item.bundleIdentifier == "io.vincode.Zavala" }
			.first { item in item.processIdentifier != getpid() }

		if runningApp != nil {
			let alert = NSAlert()
			alert.messageText = L10n.alreadyRunningMessage
			alert.informativeText = L10n.alreadyRunningInfo
			alert.alertStyle = NSAlert.Style.informational
			alert.addButton(withTitle: "OK")
			alert.runModal()
			exit(0)
		}
	}
	
}
