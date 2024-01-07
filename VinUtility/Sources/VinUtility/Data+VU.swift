///
//  Created by Maurice Parker on 12/4/23.
//

import Foundation

public extension Data {
	
	func toAttributedString() -> NSAttributedString? {
		#if canImport(UIKit)
		return try? NSAttributedString(data: self,
									   options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
									   documentAttributes: nil)
		#else
		return nil
		#endif
	}
	
}
