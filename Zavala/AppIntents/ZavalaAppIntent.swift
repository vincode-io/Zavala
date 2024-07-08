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
	func findOutline(_ entityID: EntityIDAppEntity?) -> Outline? {
		guard let id = entityID?.entityID,
			  let outline = AccountManager.shared.findDocument(id)?.outline else {
				  return nil
			  }
		return outline
	}
}

enum ZavalaAppIntentError: Error, CustomLocalizedStringResourceConvertible {
	case unexpectedError
	case outlineNotBeingViewed
	case noTagsSelected
	case unavailableAccount
	
	var localizedStringResource: LocalizedStringResource {
		switch self {
		case .unexpectedError:
			return "An unexpected error occurred. Please try again."
		case .outlineNotBeingViewed:
			return "There isn't an Outline currently being viewed."
		case .noTagsSelected:
			return "No Tags are currently selected."
		case .unavailableAccount:
			return "The specified Account isn't available to be used."
		}
		
	}
}
