//
//  Bundle-Extensions.swift
//  NetNewsWire-iOS
//
//  Created by Maurice Parker on 4/26/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation

extension Bundle {
	
	var appName: String {
		return infoDictionary?["CFBundleName"] as! String
	}
	
	var copyright: String {
		return infoDictionary?["NSHumanReadableCopyright"] as! String
	}
	
}
