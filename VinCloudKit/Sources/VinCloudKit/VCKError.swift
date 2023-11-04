//
//  VCKError.swift
//
//
//  Created by Maurice Parker on 10/31/23.
//

import Foundation

public enum VCKError: LocalizedError {
	case userDeletedZone
	case corruptAccount
	case unknown
	
	public var errorDescription: String? {
		switch self {
		case .userDeletedZone:
			return NSLocalizedString("The iCloud data was deleted.  Please remove the application iCloud account and add it again to continue using the application's iCloud support.", 
									 comment: "User deleted zone.")
		case .corruptAccount:
			return NSLocalizedString("There is an unrecoverable problem with your application iCloud account. Please make sure you have iCloud and iCloud Drive enabled in System Preferences. Then remove the application iCloud account and add it again.", 
									 comment: "Corrupt account.")
		default:
			return NSLocalizedString("An unexpected CloudKit error occurred.", 
									 comment: "An unexpected CloudKit error occurred.")
		}
	}
}
