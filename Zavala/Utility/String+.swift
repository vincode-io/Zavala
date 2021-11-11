//
//  String+.swift
//  Zavala
//
//  Created by Maurice Parker on 1/31/21.
//

import UIKit

extension String {

	var containsSymbols: Bool {
		for scalar in unicodeScalars {
			switch scalar.value {
			case 0x1F600...0x1F64F, // Emoticons
				 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
				 0x1F680...0x1F6FF, // Transport and Map
				 0x2300...0x23FF,   // Misc Technical symbols
				 0x2600...0x26FF,   // Misc symbols
				 0x2700...0x27BF,   // Dingbats
				 0xFE00...0xFE0F:   // Variation Selectors
				return true
			default:
				continue
			}
		}
		return false
	}
	
	func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
		let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
		let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
		return ceil(boundingBox.height)
	}
	
	func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
		let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
		let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
		return ceil(boundingBox.width)
	}
	
}
