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
	case outlineNotBeingViewed
	
	var localizedStringResource: LocalizedStringResource {
		switch self {
		case .outlineNotBeingViewed:
			return "There isn't an outline currently being viewed."
		}
	}
}
