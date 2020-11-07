//
//  AccountType.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import UIKit

public enum AccountType: Int, Codable {
	case local = 0
	case cloudKit = 1
	
	var name: String {
		switch self {
		case .local:
			switch UIDevice.current.userInterfaceIdiom {
			case .mac:
				return NSLocalizedString("On My Mac", comment: "Mac account name")
			case .pad:
				return NSLocalizedString("On My iPad", comment: "iPad account name")
			case .phone:
				return NSLocalizedString("On My iPhone", comment: "iPhone account name")
			default:
				fatalError()
			}
		case .cloudKit:
			return NSLocalizedString("iCloud", comment: "iCloud")
		}
	}
	
}
