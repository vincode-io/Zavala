//
//  Created by Maurice Parker on 10/9/21.
//

import Foundation

extension NSRegularExpression {
	
	public func anyMatch(in text: String) -> Bool {
		return firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil
	}
	
	public func allMatches(in text: String) -> [NSTextCheckingResult] {
		return matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
	}
	
}
