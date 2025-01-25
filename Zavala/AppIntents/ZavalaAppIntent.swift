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
			return .invalidDestinationForOutline
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
		case .unexpectedError:
			return .unexpectedError
		}
		
	}
}
