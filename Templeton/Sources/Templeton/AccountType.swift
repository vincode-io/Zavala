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
	
	public var name: String {
		switch self {
		case .local:
			switch UIDevice.current.userInterfaceIdiom {
			case .mac:
				return L10n.accountOnMyMac
			case .pad:
				return L10n.accountOnMyIPad
			case .phone:
				return L10n.accountOnMyIPhone
			default:
				fatalError()
			}
		case .cloudKit:
			return L10n.accountICloud
		}
	}

	var folderName: String {
		switch self {
		case .local:
			return "local"
		case .cloudKit:
			return "cloudKit"
		}
	}
	
}
