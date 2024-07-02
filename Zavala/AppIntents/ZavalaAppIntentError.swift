//
//  Created by Maurice Parker on 7/2/24.
//

enum ZavalaAppIntentError: Error, CustomLocalizedStringResourceConvertible {
	case outlineNotBeingViewed
	
	var localizedStringResource: LocalizedStringResource {
		switch self {
		case .outlineNotBeingViewed:
			return "There isn't an outline currently being viewed."
		}
	}
}
