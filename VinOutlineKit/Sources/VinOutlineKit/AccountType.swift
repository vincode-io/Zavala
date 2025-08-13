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

public enum AccountType: Int, Codable, Sendable {
	case local = 0
	case cloudKit = 1
	
	@MainActor
	public var name: String {
		switch self {
		case .local:
			#if canImport(UIKit)
			switch UIDevice.current.userInterfaceIdiom {
			case .mac:
				return .accountOnMyMac
			case .pad:
				return .accountOnMyIPad
			case .phone:
				return .accountOnMyIPhone
			default:
				fatalError()
			}
			#else
			return .accountOnMyMac
			#endif
		case .cloudKit:
			return .accountICloud
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
