//
//  MetadataViewManager.swift
//  
//
//  Created by Maurice Parker on 10/28/21.
//

#if canImport(UIKit)

import UIKit

public protocol MetadataViewProviding {
	func provide(key: String, value: String, level: Int)  -> UIView
}

public class MetadataViewManager {
	public static var provider: MetadataViewProviding!
}

#endif
