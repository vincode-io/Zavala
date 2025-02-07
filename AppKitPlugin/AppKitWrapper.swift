//
//  AppKitWrapper.swift
//  AppKitPlugin
//
//  Created by Maurice Parker on 1/5/21.
//

import AppKit
import OSLog
import UniformTypeIdentifiers

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
	
	func stop() {
		movementMonitor?.invalidate()
	}
	
	func importOPML() {
		let panel = NSOpenPanel()
		panel.canDownloadUbiquitousContents = true
		panel.canResolveUbiquitousConflicts = true
		panel.canChooseFiles = true
		panel.allowsMultipleSelection = false
		panel.canChooseDirectories = false
		panel.resolvesAliases = true
		if let opmlType = UTType(filenameExtension: "opml") {
			panel.allowedContentTypes = [opmlType]
		}
		panel.allowsOtherFileTypes = false
		
		let modalResult = panel.runModal()
		if modalResult == NSApplication.ModalResponse.OK, let url = panel.url {
			delegate?.importFile(url)
		}
	}

	func configureOpenQuickly(_ window: NSObject?) {
		guard let nsWindow = window as? NSWindow else { return }
		nsWindow.title = String(localized: "label.text.open-quickly", comment: "Window Title: Open Quickly")
		nsWindow.titlebarAppearsTransparent = true
		nsWindow.standardWindowButton(.zoomButton)?.isHidden = true
		nsWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
	}

	func configureAbout(_ window: NSObject?) {
		guard let nsWindow = window as? NSWindow else { return }
		nsWindow.styleMask.insert(.fullSizeContentView)
		nsWindow.standardWindowButton(.zoomButton)?.isEnabled = false
		nsWindow.standardWindowButton(.miniaturizeButton)?.isEnabled = false
	}

	func configureSettings(_ window: NSObject?) {
		guard let nsWindow = window as? NSWindow else { return }
		nsWindow.standardWindowButton(.zoomButton)?.isEnabled = false
		nsWindow.standardWindowButton(.miniaturizeButton)?.isEnabled = false
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
	
}
