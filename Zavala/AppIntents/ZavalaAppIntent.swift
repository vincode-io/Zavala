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
			AccountManager.shared.resume()
		}
	}
	
	@MainActor
	func suspend() async {
		if UIApplication.shared.applicationState == .background {
			await AccountManager.shared.suspend()
		}
	}

	@MainActor
	func findOutline(_ outline: OutlineAppEntity?) -> Outline? {
		return findOutline(outline?.id)
	}
	
	@MainActor
	func findOutline(_ entityID: EntityID?) -> Outline? {
		guard let entityID, let outline = AccountManager.shared.findDocument(entityID)?.outline else {
			return nil
		}
		return outline
	}
}

enum ZavalaAppIntentError: Error, CustomLocalizedStringResourceConvertible {
	case invalidDestinationForOutline
	case outlineNotBeingViewed
	case outlineNotFound
	case noTagsSelected
	case rowContainerNotFound
	case unavailableAccount
	case unexpectedError

	var localizedStringResource: LocalizedStringResource {
		switch self {
		case .invalidDestinationForOutline:
			return "The specified Destination is not a valid for the Outline specified by the Entity ID."
		case .outlineNotBeingViewed:
			return "There isn't an Outline currently being viewed."
		case .outlineNotFound:
			return "The requested Outline was not found."
		case .noTagsSelected:
			return "No Tags are currently selected."
		case .rowContainerNotFound:
			return "Unable to find the Outline or Row specified by the Entity ID."
		case .unavailableAccount:
			return "The specified Account isn't available to be used."
		case .unexpectedError:
			return "An unexpected error occurred. Please try again."
		}
		
	}
}
