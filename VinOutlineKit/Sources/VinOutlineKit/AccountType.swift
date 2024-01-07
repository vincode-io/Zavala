//
//  AccountType.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

public enum AccountType: Int, Codable {
	case local = 0
	case cloudKit = 1
	
	public var name: String {
		switch self {
		case .local:
			#if canImport(UIKit)
			switch UIDevice.current.userInterfaceIdiom {
			case .mac:
				return VinOutlineKitStringAssets.accountOnMyMac
			case .pad:
				return VinOutlineKitStringAssets.accountOnMyIPad
			case .phone:
				return VinOutlineKitStringAssets.accountOnMyIPhone
			default:
				fatalError()
			}
			#else
			return VinOutlineKitStringAssets.accountOnMyMac
			#endif
		case .cloudKit:
			return VinOutlineKitStringAssets.accountICloud
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
