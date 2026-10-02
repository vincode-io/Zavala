//
//  Created by Maurice Parker on 7/2/24.
//

import UIKit
import VinOutlineKit

protocol ZavalaAppIntent {
	
}

extension ZavalaAppIntent {

	@MainActor
	func resume() {
		if UIApplication.shared.applicationState == .background {
			appDelegate.accountManager.resume()
		}
	}
	
	@MainActor
	func suspend() async {
		if UIApplication.shared.applicationState == .background {
			await appDelegate.accountManager.suspend()
		}
	}

	@MainActor
	func findOutline(_ outline: OutlineAppEntity?) -> Outline? {
		return findOutline(outline?.id)
	}
	
	@MainActor
	func findOutline(_ entityID: EntityID?) -> Outline? {
		guard let entityID, let outline = appDelegate.accountManager.findDocument(entityID)?.outline else {
			return nil
		}
		return outline
	}

	/// Shows the document in the main window, or in a new editor window if there isn't a main window.
	@MainActor
	func showDocument(_ entityID: EntityID) async {
		#if targetEnvironment(macCatalyst)
		defer {
			appDelegate.appKitPlugin?.activateIgnoringOtherApps()
		}
		#endif

		guard let mainSplitViewController = appDelegate.mainCoordinator as? MainSplitViewController else {
			let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
			activity.userInfo = [Pin.UserInfoKeys.pin: Pin(accountManager: appDelegate.accountManager, documentID: entityID).userInfo]
			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
			return
		}

		await mainSplitViewController.handleDocument(entityID, isNavigationBranch: false)
	}

	/// Shows the results of searching for the given text in the main window, opening one if necessary.
	@MainActor
	func showSearch(_ searchText: String) async {
		#if targetEnvironment(macCatalyst)
		defer {
			appDelegate.appKitPlugin?.activateIgnoringOtherApps()
		}
		#endif

		guard let mainSplitViewController = appDelegate.mainCoordinator as? MainSplitViewController else {
			let search = Search(accountManager: appDelegate.accountManager, searchText: searchText)
			let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.selectingDocumentContainer)
			activity.userInfo = [Pin.UserInfoKeys.pin: Pin(accountManager: appDelegate.accountManager, containers: [search]).userInfo]
			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
			return
		}

		await mainSplitViewController.handleSearch(searchText)
	}
}

enum ZavalaAppIntentError: Error, CustomLocalizedStringResourceConvertible {
	case entityIDRequired
	case invalidDestinationForOutline
	case outlineNotBeingViewed
	case outlineNotFound
	case outlineIsLocked
	case noTagsSelected
	case rowContainerNotFound
	case unavailableAccount
	case unableToParseMarkdown
	case unableToParseOPML
	case unexpectedError

	var localizedStringResource: LocalizedStringResource {
		switch self {
		case .entityIDRequired:
			return .entityIDRequired
		case .invalidDestinationForOutline:
			return .invalidDestinationForOutline
		case .outlineIsLocked:
			return .outlineIsLocked
		case .outlineNotBeingViewed:
			return .outlineNotBeingViewed
		case .outlineNotFound:
			return .outlineNotFound
		case .noTagsSelected:
			return .noTagsSelected
		case .rowContainerNotFound:
			return .rowContainerNotFound
		case .unavailableAccount:
			return .unavailableAccount
		case .unableToParseMarkdown:
			return .unableToParseMarkdown
		case .unableToParseOPML:
			return .unableToParseOPML
		case .unexpectedError:
			return .unexpectedError
		}
		
	}
}
