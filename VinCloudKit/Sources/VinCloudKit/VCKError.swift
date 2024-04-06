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
	case maxChildCountExceeded
	case unknown
	
	public var errorDescription: String? {
		switch self {
		case .userDeletedZone:
			return String(localized: "The iCloud data was deleted.  Please remove the application iCloud account and add it again to continue using the application's iCloud support.", 
									 comment: "Error Message: User deleted zone.")
		case .corruptAccount:
			return String(localized: "There is an unrecoverable problem with your application iCloud account. Please make sure you have iCloud and iCloud Drive enabled in System Preferences. Then remove the application iCloud account and add it again.", 
									 comment: "Error Message: Corrupt account.")
		case .maxChildCountExceeded:
			return String(localized: "The maximum number of child rows that iCloud can sync is 750. This limit has been exceeded. Please reduce the number of child rows to continue syncing.",
									 comment: "Error Message: Max child count exceeeded.")
		default:
			return String(localized: "An unexpected CloudKit error occurred.", 
									 comment: "Error Message: An unexpected CloudKit error occurred.")
		}
	}
}
