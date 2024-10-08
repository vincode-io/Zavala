//
//  Created by Maurice Parker on 11/4/21.
//

import UIKit

/***
 Marker protocol to make sure we don't pick up system provided text inputs when going after the current responder.
 */
@MainActor
protocol EditorTextInput: UITextInput {}

extension EditorTextInput {
	
	var cursorRect: CGRect? {
		guard let caratPosition = selectedTextRange?.start else { return nil }
		return caretRect(for: caratPosition)
	}

}
