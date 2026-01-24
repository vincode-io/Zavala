//
//  Created by Maurice Parker on 11/4/21.
//

import UIKit

@MainActor
protocol EditorTextInput: UITextInput, UIResponder {}

extension EditorTextInput {
	
	var cursorRect: CGRect? {
		guard let caratPosition = selectedTextRange?.start else { return nil }
		return caretRect(for: caratPosition)
	}

}
