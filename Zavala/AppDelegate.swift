//
//  AppDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import OSLog
import Intents
import VinOutlineKit

@MainActor var appDelegate: AppDelegate!

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	let showSettings = UIKeyCommand(title: .settingsEllipsisControlLabel,
									action: .showSettings,
									input: ",",
									modifierFlags: [.command])
	
	
	let syncCommand = UIKeyCommand(title: .syncControlLabel,
								   action: .sync,
								   input: "r",
								   modifierFlags: [.command])
	
	let exportOPMLsCommand = UIKeyCommand(title: .exportOPMLEllipsisControlLabel,
										  action: .exportOPMLs,
										  input: "e",
										  modifierFlags: [.shift, .command])
	
	let exportPDFDocsCommand = UICommand(title: .exportPDFDocEllipsisControlLabel, action: .exportPDFDocs)

	let exportPDFListsCommand = UICommand(title: .exportPDFListEllipsisControlLabel, action: .exportPDFLists)

	let exportMarkdownDocsCommand = UICommand(title: .exportMarkdownDocEllipsisControlLabel, action: .exportMarkdownDocs)
	
	let exportMarkdownListsCommand = UIKeyCommand(title: .exportMarkdownListEllipsisControlLabel,
												  action: .exportMarkdownLists,
												  input: "e",
												  modifierFlags: [.control, .command])
	
	let importOPMLCommand = UIKeyCommand(title: .importOPMLEllipsisControlLabel,
										 action: #selector(importOPMLCommand(_:)),
										 input: "i",
										 modifierFlags: [.shift, .command])
	
	let newWindowCommand = UIKeyCommand(title: .newMainWindowControlLabel,
										action: #selector(newWindow(_:)),
										input: "n",
										modifierFlags: [.alternate, .command])
	
	let newOutlineCommand = UIKeyCommand(title: .newOutlineControlLabel,
										 action: #selector(createOutlineCommand(_:)),
										 input: "n",
										 modifierFlags: [.command])
	
	let deleteCommand = UIKeyCommand(title: .deleteControlLabel,
									 action: #selector(delete),
									 input: "\u{8}",
									 modifierFlags: [])
	
	let goBackwardOneCommand = UIKeyCommand(title: .backControlLabel,
											action: .goBackwardOne,
											input: "[",
											modifierFlags: [.command])
	
	let goForwardOneCommand = UIKeyCommand(title: .forwardControlLabel,
										   action: .goForwardOne,
										   input: "]",
										   modifierFlags: [.command])
	
	let addRowAboveCommand = UIKeyCommand(title: .addRowAboveControlLabel,
										  action: .addRowAbove,
										  input: "\n",
										  modifierFlags: [.shift])
	
	let addRowBelowCommand = UIKeyCommand(title: .addRowBelowControlLabel,
										  action: .addRowBelow,
										  input: "\n",
										  modifierFlags: [.control])
	
	let createRowInsideCommand = UIKeyCommand(title: .addRowInsideControlLabel,
											  action: .createRowInside,
											  input: "}",
											  modifierFlags: [.command])
	
	let createRowOutsideCommand = UIKeyCommand(title: .addRowOutsideControlLabel,
											   action: .createRowOutside,
											   input: "{",
											   modifierFlags: [.command])
	
	let deleteCurrentRowsCommand = UIKeyCommand(title: .deleteRowControlLabel,
												action: .deleteCurrentRows,
												input: UIKeyCommand.inputDelete,
												modifierFlags: [.shift, .command])
	
	let duplicateRowsCommand = UIKeyCommand(title: .duplicateRowControlLabel,
											action: .duplicateCurrentRows,
											input: "r",
											modifierFlags: [.command, .control])
	
	let moveRowsLeftCommand = UIKeyCommand(title: .moveLeftControlLabel,
										   action: .moveCurrentRowsLeft,
										   input: UIKeyCommand.inputLeftArrow,
										   modifierFlags: [.control, .command])
	
	let moveRowsRightCommand = UIKeyCommand(title: .moveRightControlLabel,
											action: .moveCurrentRowsRight,
											input: UIKeyCommand.inputRightArrow,
											modifierFlags: [.control, .command])
	
	let moveRowsUpCommand = UIKeyCommand(title: .moveUpControlLabel,
										 action: .moveCurrentRowsUp,
										 input: UIKeyCommand.inputUpArrow,
										 modifierFlags: [.control, .command])
	
	let moveRowsDownCommand = UIKeyCommand(title: .moveDownControlLabel,
										   action: .moveCurrentRowsDown,
										   input: UIKeyCommand.inputDownArrow,
										   modifierFlags: [.control, .command])
	
	let toggleCompleteRowsCommand = UIKeyCommand(title: .completeControlLabel,
												 action: .toggleCompleteRows,
												 input: "\n",
												 modifierFlags: [.command])
	
	let rowNotesCommand = UIKeyCommand(title: .addNoteControlLabel,
									   action: .toggleRowNotes,
									   input: "-",
									   modifierFlags: [.control])
	
	let deleteRowNotesCommand = UIKeyCommand(title: .deleteNoteControlLabel,
											 action: .deleteRowNotes,
											 input: "-",
											 modifierFlags: [.control, .shift])
	
	let toggleBoldCommand = UIKeyCommand(title: .boldControlLabel,
										 action: .toggleBoldface,
										 input: "b",
										 modifierFlags: [.command])
	
	let toggleItalicsCommand = UIKeyCommand(title: .italicControlLabel,
											action: .toggleItalics,
											input: "i",
											modifierFlags: [.command])
	
	let insertImageCommand = UIKeyCommand(title: .insertImageEllipsisControlLabel,
										  action: .insertImage,
										  input: "i",
										  modifierFlags: [.alternate, .command])
	
	let linkCommand = UIKeyCommand(title: .linkEllipsisControlLabel,
								   action: .editLink,
								   input: "k",
								   modifierFlags: [.command])
	
	let copyRowLinkCommand = UICommand(title: .copyRowLinkControlLabel, action: #selector(copyRowLinkCommand(_:)))

	let copyDocumentLinkCommand = UICommand(title: .copyDocumentLinkControlLabel, action: #selector(copyDocumentLinkCommand(_:)))

	let focusInCommand = UIKeyCommand(title: .focusInControlLabel,
									  action: #selector(focusInCommand(_:)),
									  input: UIKeyCommand.inputRightArrow,
									  modifierFlags: [.alternate, .command])
	
	let focusOutCommand = UIKeyCommand(title: .focusOutControlLabel,
									   action: #selector(focusOutCommand(_:)),
									   input: UIKeyCommand.inputLeftArrow,
									   modifierFlags: [.alternate, .command])

	let toggleFilterOnCommand = UIKeyCommand(title: .turnFilterOnControlLabel,
											 action: #selector(toggleFilterOnCommand(_:)),
											 input: "h",
											 modifierFlags: [.shift, .command])
	
	let toggleCompletedFilterCommand = UICommand(title: .filterCompletedControlLabel, action: #selector(toggleCompletedFilterCommand(_:)))
	
	let toggleNotesFilterCommand = UICommand(title: .filterNotesControlLabel, action: #selector(toggleNotesFilterCommand(_:)))
	
	let expandAllInOutlineCommand = UIKeyCommand(title: .expandAllInOutlineControlLabel,
												 action: #selector(expandAllInOutlineCommand(_:)),
												 input: "9",
												 modifierFlags: [.control, .command])
	
	let collapseAllInOutlineCommand = UIKeyCommand(title: .collapseAllInOutlineControlLabel,
												   action: #selector(collapseAllInOutlineCommand(_:)),
												   input: "0",
												   modifierFlags: [.control, .command])
	
	let expandAllCommand = UIKeyCommand(title: .expandAllInRowControlLabel,
										action: #selector(expandAllCommand(_:)),
										input: "9",
										modifierFlags: [.alternate, .command])
	
	let collapseAllCommand = UIKeyCommand(title: .collapseAllInRowControlLabel,
										  action: #selector(collapseAllCommand(_:)),
										  input: "0",
										  modifierFlags: [.alternate, .command])
	
	let expandCommand = UIKeyCommand(title: .expandControlLabel,
									 action: #selector(expandCommand(_:)),
									 input: "9",
									 modifierFlags: [.command])
	
	let collapseCommand = UIKeyCommand(title: .collapseControlLabel,
									   action: #selector(collapseCommand(_:)),
									   input: "0",
									   modifierFlags: [.command])
	
	let collapseParentRowCommand = UIKeyCommand(title: .collapseParentRowControlLabel,
												action: #selector(collapseParentRowCommand(_:)),
												input: "0",
												modifierFlags: [.control, .alternate, .command])
	
	let zoomInCommand = UIKeyCommand(title: .zoomInControlLabel,
									 action: #selector(zoomInCommand(_:)),
									 input: ">",
									 modifierFlags: [.command])
	
	let zoomOutCommand = UIKeyCommand(title: .zoomOutControlLabel,
									 action: #selector(zoomOutCommand(_:)),
									 input: "<",
									 modifierFlags: [.command])
	
	let actualSizeCommand = UICommand(title: .actualSizeControlLabel, action: #selector(actualSizeCommand(_:)))
	
	let deleteCompletedRowsCommand = UIKeyCommand(title: .deleteCompletedRowsControlLabel,
												  action: .deleteCompletedRows,
												  input: "d",
												  modifierFlags: [.command])
	
	let showHelpCommand = UICommand(title: .appHelpControlLabel, action: #selector(showHelpCommand(_:)))

	let showCommunityCommand = UICommand(title: .communityControlLabel, action: #selector(showCommunityCommand(_:)))

	let feedbackCommand = UICommand(title: .feedbackControlLabel, action: #selector(feedbackCommand(_:)))

	let enterBackgroundCommand = UICommand(title: .enterBackgroundControlLabel, action: #selector(enterBackgroundCommand(_:)))

	let enterForgroundCommand = UICommand(title: .enterForgroundControlLabel, action: #selector(enterForgroundCommand(_:)))

	let showOpenQuicklyCommand = UIKeyCommand(title: .openQuicklyEllipsisControlLabel,
											  action: #selector(showOpenQuicklyCommand(_:)),
											  input: "o",
											  modifierFlags: [.shift, .command])
	
	let printDocsCommand = UIKeyCommand(title: .printDocEllipsisControlLabel,
										action: .printDocs,
										input: "p",
										modifierFlags: [.alternate, .command])
	
	let printListsCommand = UIKeyCommand(title: .printListControlEllipsisLabel,
										 action: .printLists,
										 input: "p",
										 modifierFlags: [.command])

	let shareCommand = UICommand(title: .shareEllipsisControlLabel, action: .share)

	let manageSharingCommand = UICommand(title: .manageSharingEllipsisControlLabel, action: .manageSharing)
	
	let showGetInfoCommand = UIKeyCommand(title: .getInfoControlLabel, action: .showGetInfo, input: "i", modifierFlags: [.control, .command])

	var mainCoordinator: MainCoordinator? {
		return UIApplication.shared.foregroundActiveScene?.keyWindow?.rootViewController as? MainCoordinator
	}
	
	private var history = [Pin]()
	private var documentIndexer: DocumentIndexer?
	private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Zavala")
	
	#if targetEnvironment(macCatalyst)
	var appKitPlugin: AppKitPlugin?
	#endif

	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		appDelegate = self

		let oldDocumentAccountURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let oldDocumentAccountsFolder = oldDocumentAccountURL.appendingPathComponent("Accounts").absoluteString

		let oldDocumentAccountsFolderPath = String(oldDocumentAccountsFolder.suffix(from: oldDocumentAccountsFolder.index(oldDocumentAccountsFolder.startIndex, offsetBy: 7)))
		
		let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as! String
		let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
		let documentAccountsFolderPath = containerURL!.appendingPathComponent("Accounts").path
		
		// Migrate test users to the Mac App Store version
		if FileManager.default.fileExists(atPath: oldDocumentAccountsFolderPath) && !FileManager.default.fileExists(atPath: documentAccountsFolderPath) {
			try? FileManager.default.moveItem(atPath: oldDocumentAccountsFolderPath, toPath: documentAccountsFolderPath)
		}
		
		AccountManager.shared = AccountManager(accountsFolderPath: documentAccountsFolderPath, errorHandler: self)
		let _ = OutlineFontCache.shared
		
		return true
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		AppDefaults.registerDefaults()

		NotificationCenter.default.addObserver(self, selector: #selector(checkForUserDefaultsChanges), name: UserDefaults.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(pinWasVisited), name: .PinWasVisited, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountDocumentsDidChange), name: .AccountDocumentsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountManagerAccountsDidChange), name: .AccountManagerAccountsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountMetadataDidChange), name: .AccountMetadataDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentTitleDidChange), name: .DocumentTitleDidChange, object: nil)

		#if targetEnvironment(macCatalyst)
		guard let pluginPath = (Bundle.main.builtInPlugInsPath as NSString?)?.appendingPathComponent("AppKitPlugin.bundle"),
			  let bundle = Bundle(path: pluginPath),
			  let cls = bundle.principalClass as? NSObject.Type,
			  let appKitPlugin = cls.init() as? AppKitPlugin else { return true }
		
		self.appKitPlugin = appKitPlugin
		appKitPlugin.setDelegate(self)
		appKitPlugin.start()
		#endif
		
		UIApplication.shared.registerForRemoteNotifications()
		NSUbiquitousKeyValueStore.default.synchronize()
		
		documentIndexer = DocumentIndexer()
		
		return true
	}

	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		Task { @MainActor in
			if UIApplication.shared.applicationState == .background {
				AccountManager.shared.resume()
			}
			await AccountManager.shared.receiveRemoteNotification(userInfo: userInfo)
			if UIApplication.shared.applicationState == .background {
				await AccountManager.shared.suspend()
			}
			completionHandler(.newData)
		}
	}
	
	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		switch options.userActivities.first?.activityType {
		case NSUserActivity.ActivityType.openEditor, NSUserActivity.ActivityType.newOutline:
			return UISceneConfiguration(name: "Outline Editor Configuration", sessionRole: connectingSceneSession.role)
		case NSUserActivity.ActivityType.openQuickly:
			return UISceneConfiguration(name: "Open Quickly Configuration", sessionRole: connectingSceneSession.role)
		case NSUserActivity.ActivityType.viewImage:
			return UISceneConfiguration(name: "Image Configuration", sessionRole: connectingSceneSession.role)
		case NSUserActivity.ActivityType.showAbout:
			return UISceneConfiguration(name: "About Configuration", sessionRole: connectingSceneSession.role)
		case NSUserActivity.ActivityType.showSettings:
			return UISceneConfiguration(name: "Settings Configuration", sessionRole: connectingSceneSession.role)
		default:
			guard options.userActivities.first?.userInfo == nil else {
				return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
			}
			guard AppDefaults.shared.lastMainWindowWasClosed else {
				return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
			}
			if AppDefaults.shared.enableMainWindowAsDefault {
				return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
			} else {
				return UISceneConfiguration(name: "Open Quickly Configuration", sessionRole: connectingSceneSession.role)
			}
		}
	}

	// MARK: Actions

	@objc func importOPMLCommand(_ sender: Any?) {
		if UIResponder.valid(action: .importOPML) {
			UIApplication.shared.sendAction(.importOPML, to: nil, from: nil, for: nil)
		} else {
			#if targetEnvironment(macCatalyst)
			appKitPlugin?.importOPML()
			#endif
		}
	}

	@objc func newWindow(_ sender: Any?) {
		let userActivity = NSUserActivity(activityType: NSUserActivity.ActivityType.newWindow)
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
	}
	
	@objc func createOutlineCommand(_ sender: Any?) {
		if UIResponder.valid(action: .createOutline) {
			UIApplication.shared.sendAction(.createOutline, to: nil, from: nil, for: nil)
		} else {
			let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.newOutline)
			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
		}
	}
	
	@objc func copyRowLinkCommand(_ sender: Any?) {
		mainCoordinator?.copyRowLink()
	}

	@objc func copyDocumentLinkCommand(_ sender: Any?) {
		mainCoordinator?.copyDocumentLink()
	}

	@objc func focusInCommand(_ sender: Any?) {
		mainCoordinator?.focusIn()
	}

	@objc func focusOutCommand(_ sender: Any?) {
		mainCoordinator?.focusOut()
	}

	@objc func toggleFilterOnCommand(_ sender: Any?) {
		mainCoordinator?.toggleFilterOn()
	}

	@objc func toggleCompletedFilterCommand(_ sender: Any?) {
		mainCoordinator?.toggleCompletedFilter()
	}

	@objc func toggleNotesFilterCommand(_ sender: Any?) {
		mainCoordinator?.toggleNotesFilter()
	}

	@objc func expandAllInOutlineCommand(_ sender: Any?) {
		mainCoordinator?.expandAllInOutline()
	}

	@objc func collapseAllInOutlineCommand(_ sender: Any?) {
		mainCoordinator?.collapseAllInOutline()
	}

	@objc func expandAllCommand(_ sender: Any?) {
		mainCoordinator?.expandAll()
	}

	@objc func collapseAllCommand(_ sender: Any?) {
		mainCoordinator?.collapseAll()
	}

	@objc func expandCommand(_ sender: Any?) {
		mainCoordinator?.expand()
	}

	@objc func collapseCommand(_ sender: Any?) {
		mainCoordinator?.collapse()
	}
	
	@objc func collapseParentRowCommand(_ sender: Any?) {
		mainCoordinator?.collapseParentRow()
	}
	
	@objc func zoomInCommand(_ sender: Any?) {
		AppDefaults.shared.textZoom = AppDefaults.shared.textZoom + 1
	}
	
	@objc func zoomOutCommand(_ sender: Any?) {
		AppDefaults.shared.textZoom = AppDefaults.shared.textZoom - 1
	}
	
	@objc func actualSizeCommand(_ sender: Any?) {
		AppDefaults.shared.textZoom = 0
	}
	
	@objc func showHelpCommand(_ sender: Any?) {
		UIApplication.shared.open(URL(string: .helpURL)!)
	}

	@objc func showCommunityCommand(_ sender: Any?) {
		UIApplication.shared.open(URL(string: .communityURL)!)
	}

	@objc func feedbackCommand(_ sender: Any?) {
		UIApplication.shared.open(URL(string: .feedbackURL)!)
	}

	@objc func enterForgroundCommand(_ sender: Any?) {
		willEnterForeground()
	}

	@objc func enterBackgroundCommand(_ sender: Any?) {
		didEnterBackground()
	}

	@objc func showOpenQuicklyCommand(_ sender: Any?) {
		if UIResponder.valid(action: .showOpenQuickly) {
			UIApplication.shared.sendAction(.showOpenQuickly, to: nil, from: nil, for: nil)
		} else {
			let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openQuickly)
			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
		}
	}

	@objc func showAbout(_ sender: Any?) {
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.showAbout)
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
	}

	// MARK: Validations
	
	override func validate(_ command: UICommand) {
		switch command.action {
		case #selector(focusInCommand(_:)):
			if mainCoordinator?.isFocusInUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(focusOutCommand(_:)):
			if mainCoordinator?.isFocusOutUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(toggleFilterOnCommand(_:)):
			if mainCoordinator?.isFilterOn ?? false {
				command.title = .turnFilterOffControlLabel
			} else {
				command.title = .turnFilterOnControlLabel
			}
		case #selector(toggleCompletedFilterCommand(_:)):
			if mainCoordinator?.isCompletedFiltered ?? false {
				command.state = .on
			} else {
				command.state = .off
			}
			if !(mainCoordinator?.isFilterOn ?? false) {
				command.attributes = .disabled
			}
		case #selector(toggleNotesFilterCommand(_:)):
			if mainCoordinator?.isNotesFiltered ?? false {
				command.state = .on
			} else {
				command.state = .off
			}
			if !(mainCoordinator?.isFilterOn ?? false) {
				command.attributes = .disabled
			}
		case #selector(expandAllInOutlineCommand(_:)):
			if mainCoordinator?.isExpandAllInOutlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(collapseAllInOutlineCommand(_:)):
			if mainCoordinator?.isCollapseAllInOutlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(expandAllCommand(_:)):
			if mainCoordinator?.isExpandAllUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(collapseAllCommand(_:)):
			if mainCoordinator?.isCollapseAllUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(expandCommand(_:)):
			if mainCoordinator?.isExpandUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(collapseCommand(_:)):
			if mainCoordinator?.isCollapseUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(collapseParentRowCommand(_:)):
			if mainCoordinator?.isCollapseParentRowUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(copyRowLinkCommand(_:)):
			if mainCoordinator?.isCopyRowLinkUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(copyDocumentLinkCommand(_:)):
			if mainCoordinator?.isOutlineFunctionsUnavailable ?? true {
				command.attributes = .disabled
			}
		default:
			break
		}
	}
		
	// MARK: Menu

	override func buildMenu(with builder: UIMenuBuilder) {
		super.buildMenu(with: builder)

		guard builder.system == UIMenuSystem.main else { return }

		// Application Menu
		let appMenu = UIMenu(title: "", options: .displayInline, children: [showSettings])
		builder.insertSibling(appMenu, afterMenu: .about)

		let aboutMenuTitle = builder.menu(for: .about)?.children.first?.title ?? "About Zavala"
		let showAboutCommand = UICommand(title: aboutMenuTitle, action: #selector(showAbout(_:)))
		builder.replace(menu: .about, with: UIMenu(options: .displayInline, children: [showAboutCommand]))
		
		// File Menu
		builder.remove(menu: .newScene)
		builder.remove(menu: .openRecent)
		builder.remove(menu: .document)

		let newMenu = UIMenu(title: "", options: .displayInline, children: [newOutlineCommand, newWindowCommand, showOpenQuicklyCommand])
		builder.insertChild(newMenu, atStartOfMenu: .file)

		let syncMenu = UIMenu(title: "", options: .displayInline, children: [syncCommand])
		builder.insertChild(syncMenu, atEndOfMenu: .file)

		let getInfoMenu = UIMenu(title: "", options: .displayInline, children: [showGetInfoCommand])
		builder.insertChild(getInfoMenu, atEndOfMenu: .file)

		let exportMenu = UIMenu(title: .exportControlLabel, children: [exportPDFDocsCommand, exportPDFListsCommand, exportMarkdownDocsCommand, exportMarkdownListsCommand, exportOPMLsCommand])
		let importExportMenu = UIMenu(title: "", options: .displayInline, children: [importOPMLCommand, shareCommand, manageSharingCommand, exportMenu])
		builder.insertChild(importExportMenu, atEndOfMenu: .file)

		let printMenu = UIMenu(title: "", options: .displayInline, children: [printDocsCommand, printListsCommand])
		builder.insertChild(printMenu, atEndOfMenu: .file)

		// Edit
		builder.replaceChildren(ofMenu: .standardEdit) { oldElements in
			var newElements = [UIMenuElement]()
			for oldElement in oldElements {
				if let oldCommand = oldElement as? UICommand {
					switch oldCommand.action {
					case #selector(UIResponderStandardEditActions.delete):
						newElements.append(deleteCommand)
					case #selector(UIResponderStandardEditActions.copy):
						newElements.append(oldElement)
						newElements.append(copyRowLinkCommand)
						newElements.append(copyDocumentLinkCommand)
					default:
						newElements.append(oldElement)
					}
				}
			}
			return newElements
		}
		
		let linkMenu = UIMenu(title: "", options: .displayInline, children: [insertImageCommand, linkCommand])
		builder.insertSibling(linkMenu, afterMenu: .standardEdit)

		builder.remove(menu: .spelling)
		builder.remove(menu: .substitutions)

		// Format
		builder.remove(menu: .format)
		let formatMenu = UIMenu(title: .formatControlLabel, children: [toggleBoldCommand, toggleItalicsCommand])
		builder.insertSibling(formatMenu, afterMenu: .edit)

		// View Menu
		let zoomMenu = UIMenu(title: "", options: .displayInline, children: [zoomInCommand, zoomOutCommand, actualSizeCommand])
		builder.insertChild(zoomMenu, atStartOfMenu: .view)
		
		let expandCollapseMenu = UIMenu(title: "",
										options: .displayInline,
										children: [expandAllInOutlineCommand, expandAllCommand, expandCommand, collapseAllInOutlineCommand, collapseAllCommand, collapseCommand, collapseParentRowCommand])
		builder.insertChild(expandCollapseMenu, atStartOfMenu: .view)
		
		let toggleFilterOutlineMenu = UIMenu(title: "", options: .displayInline, children: [toggleFilterOnCommand, toggleCompletedFilterCommand, toggleNotesFilterCommand])
		builder.insertChild(toggleFilterOutlineMenu, atStartOfMenu: .view)

		let focusMenu = UIMenu(title: "", options: .displayInline, children: [focusInCommand, focusOutCommand])
		builder.insertChild(focusMenu, atStartOfMenu: .view)

		// Outline Menu
		let mainOutlineMenu = UIMenu(title: "",
									 options: .displayInline,
									 children: [addRowAboveCommand,
												addRowBelowCommand,
												createRowInsideCommand,
												createRowOutsideCommand,
												duplicateRowsCommand,
												deleteCurrentRowsCommand])
		let moveRowMenu = UIMenu(title: "", options: .displayInline, children: [moveRowsLeftCommand, moveRowsRightCommand, moveRowsUpCommand, moveRowsDownCommand])
		let completeMenu = UIMenu(title: "", options: .displayInline, children: [toggleCompleteRowsCommand, deleteCompletedRowsCommand])
		let noteMenu = UIMenu(title: "", options: .displayInline, children: [rowNotesCommand, deleteRowNotesCommand])

		let outlineMenu = UIMenu(title: .outlineControlLabel, children: [mainOutlineMenu, moveRowMenu, completeMenu, noteMenu])
		builder.insertSibling(outlineMenu, afterMenu: .view)

		// History Menu
		let navigateMenu = UIMenu(title: "", options: .displayInline, children: [goBackwardOneCommand, goForwardOneCommand])
		
		var historyItems = [UIAction]()
		for (index, pin) in history.enumerated() {
			historyItems.append(UIAction(title: pin.document?.title ?? .noTitleLabel) { [weak self] _ in
				Task { @MainActor in
					self?.openHistoryItem(index: index)
				}
			})
		}
		let historyItemsMenu = UIMenu(title: "", options: .displayInline, children: historyItems)

		let historyMenu = UIMenu(title: .historyControlLabel, children: [navigateMenu, historyItemsMenu])
		builder.insertSibling(historyMenu, afterMenu: .view)

		// Debug Menu
		#if DEBUG
		let debugMenu = UIMenu(title: .debugControlLabel, children: [enterBackgroundCommand, enterForgroundCommand])
		builder.insertSibling(debugMenu, beforeMenu: .window)
		#endif

		// Help Menu
		builder.replaceChildren(ofMenu: .help, from: { _ in return [showHelpCommand, showCommunityCommand, feedbackCommand] })
	}

}

// MARK: AppKitPluginDelegate

extension AppDelegate: AppKitPluginDelegate {
	
	func importOPML(_ url: URL) {
		let accountID = AppDefaults.shared.lastSelectedAccountID
		guard let account = AccountManager.shared.findAccount(accountID: accountID) ?? AccountManager.shared.activeAccounts.first else { return }
		
		Task {
			guard let document = try? await account.importOPML(url, tags: nil) else { return }

			let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
			activity.userInfo = [Pin.UserInfoKeys.pin: Pin(document: document).userInfo]
			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
		}
	}
	
}

// MARK: ErrorHandler

extension AppDelegate: ErrorHandler {
	
	func presentError(_ error: Error, title: String) {
		if mainCoordinator?.presentedViewController == nil {
			mainCoordinator?.presentError(title: title, message: error.localizedDescription)
		}
	}
	
}

// MARK: Helpers

private extension AppDelegate {
	
	@objc func willEnterForeground() {
		checkForUserDefaultsChanges()
		AccountManager.shared.resume()
		
		Task {
			await AccountManager.shared.sync()
		}
		
		if let userInfos = AppDefaults.shared.documentHistory {
			history = userInfos.compactMap { Pin(userInfo: $0) }
		}
		cleanUpHistory()
		UIMenuSystem.main.setNeedsRebuild()
	}
	
	@objc private func didEnterBackground() {
		let backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
			self?.logger.info("CloudKit sync processing terminated for running too long.")
		}

		Task {
			await AccountManager.shared.sync()
			await AccountManager.shared.suspend()
			UIApplication.shared.endBackgroundTask(backgroundTaskID)
		}
		
		AppDefaults.shared.documentHistory = history.map { $0.userInfo }
	}
	
	@objc nonisolated private func checkForUserDefaultsChanges() {
		Task { @MainActor in
			guard let localAccount = AccountManager.shared.localAccount else { return }
			
			if AppDefaults.shared.enableLocalAccount != localAccount.isActive {
				if AppDefaults.shared.enableLocalAccount {
					localAccount.activate()
				} else {
					localAccount.deactivate()
				}
			}
			
			let cloudKitAccount = AccountManager.shared.cloudKitAccount
			
			if AppDefaults.shared.enableCloudKit && cloudKitAccount == nil {
				AccountManager.shared.createCloudKitAccount()
			} else if !AppDefaults.shared.enableCloudKit && cloudKitAccount != nil {
				AccountManager.shared.deleteCloudKitAccount()
			}
		}
	}

	@objc func pinWasVisited(_ note: Notification) {
		guard let pin = note.object as? Pin else { return }
		
		history.removeAll(where: { $0.documentID == pin.documentID })
		history.insert(pin, at: 0)
		history = Array(history.prefix(15))
		
		UIMenuSystem.main.setNeedsRebuild()
	}

	@objc func accountDocumentsDidChange() {
		cleanUpHistory()
	}

	@objc func accountManagerAccountsDidChange() {
		cleanUpHistory()
	}

	@objc func accountMetadataDidChange() {
		cleanUpHistory()
	}
	
	@objc func documentTitleDidChange() {
		UIMenuSystem.main.setNeedsRebuild()
	}

	func openHistoryItem(index: Int) {
		let pin = history[index]
		
		if let mainSplitViewController = mainCoordinator as? MainSplitViewController {
			Task {
				await mainSplitViewController.handlePin(pin)
			}
		} else {
			let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
			activity.userInfo = [Pin.UserInfoKeys.pin: pin.userInfo]
			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
		}
		
	}

	private func cleanUpHistory() {
		let allDocumentIDs = AccountManager.shared.activeDocuments.map { $0.id }
		
		for pin in history {
			if let documentID = pin.documentID {
				if !allDocumentIDs.contains(documentID) {
					history.removeFirst(object: pin)
					UIMenuSystem.main.setNeedsRebuild()
				}
			}
		}
	}
	
}
