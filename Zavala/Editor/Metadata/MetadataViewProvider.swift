//
//  MetadataViewProvider.swift
//  Zavala
//
//  Created by Maurice Parker on 10/28/21.
//

import UIKit
import VinOutlineKit

class MetadataViewProvider: MetadataViewProviding {
	
	func provide(key: String, value: String, level: Int) -> UIView {
		return MetadataView(key: key, value: value, level: level)
	}
	
}
