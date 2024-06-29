//
//  CKError+.swift
//
//
//  Created by Maurice Parker on 11/1/22.
//

import Foundation
import CloudKit

extension CKError: @retroactive LocalizedError {
	
	public var errorDescription: String? {
		switch code {
		case .alreadyShared:
			return String(localized: "Already Shared: a record or share cannot be saved because doing so would cause the same hierarchy of records to exist in multiple shares.", comment: "Known iCloud Error")
		case .assetFileModified:
			return String(localized: "Asset File Modified: the content of the specified asset file was modified while being saved.", comment: "Known iCloud Error")
		case .assetFileNotFound:
			return String(localized: "Asset File Not Found: the specified asset file is not found.", comment: "Known iCloud Error")
		case .badContainer:
			return String(localized: "Bad Container: the specified container is unknown or unauthorized.", comment: "Known iCloud Error")
		case .badDatabase:
			return String(localized: "Bad Database: the operation could not be completed on the given database.", comment: "Known iCloud Error")
		case .batchRequestFailed:
			return String(localized: "Batch Request Failed: the entire batch was rejected.", comment: "Known iCloud Error")
		case .changeTokenExpired:
			return String(localized: "Change Token Expired: the previous server change token is too old.", comment: "Known iCloud Error")
		case .constraintViolation:
			return String(localized: "Constraint Violation: the server rejected the request because of a conflict with a unique field.", comment: "Known iCloud Error")
		case .incompatibleVersion:
			return String(localized: "Incompatible Version: your app version is older than the oldest version allowed.", comment: "Known iCloud Error")
		case .internalError:
			return String(localized: "Internal Error: a nonrecoverable error was encountered by CloudKit.", comment: "Known iCloud Error")
		case .invalidArguments:
			return String(localized: "Invalid Arguments: the specified request contains bad information.", comment: "Known iCloud Error")
		case .limitExceeded:
			return String(localized: "Limit Exceeded: the request to the server is too large.", comment: "Known iCloud Error")
		case .managedAccountRestricted:
			return String(localized: "Managed Account Restricted: the request was rejected due to a managed-account restriction.", comment: "Known iCloud Error")
		case .missingEntitlement:
			return String(localized: "Missing Entitlement: the app is missing a required entitlement.", comment: "Known iCloud Error")
		case .networkUnavailable:
			return String(localized: "Network Unavailable: the internet connection appears to be offline.", comment: "Known iCloud Error")
		case .networkFailure:
			return String(localized: "Network Failure: the internet connection appears to be offline.", comment: "Known iCloud Error")
		case .notAuthenticated:
			return String(localized: "Not Authenticated: to use the iCloud account, you must enable iCloud Drive. Go to device Settings, sign in to iCloud, then in the app settings, be sure the iCloud Drive feature is enabled.", comment: "Known iCloud Error")
		case .operationCancelled:
			return String(localized: "Operation Cancelled: the operation was explicitly canceled.", comment: "Known iCloud Error")
		case .partialFailure:
			return String(localized: "Partial Failure: some items failed, but the operation succeeded overall.", comment: "Known iCloud Error")
		case .participantMayNeedVerification:
			return String(localized: "Participant May Need Verification: you are not a member of the share.", comment: "Known iCloud Error")
		case .permissionFailure:
			return String(localized: "Permission Failure: to use this app, you must enable iCloud Drive. Go to device Settings, sign in to iCloud, then in the app settings, be sure the iCloud Drive feature is enabled.", comment: "Known iCloud Error")
		case .quotaExceeded:
			return String(localized: "Quota Exceeded: saving would exceed your current iCloud storage quota.", comment: "Known iCloud Error")
		case .referenceViolation:
			return String(localized: "Reference Violation: the target of a record's parent or share reference was not found.", comment: "Known iCloud Error")
		case .requestRateLimited:
			return String(localized: "Request Rate Limited: transfers to and from the server are being rate limited at this time.", comment: "Known iCloud Error")
		case .serverRecordChanged:
			return String(localized: "Server Record Changed: the record was rejected because the version on the server is different.", comment: "Known iCloud Error")
		case .serverRejectedRequest:
			return String(localized: "Server Rejected Request", comment: "Known iCloud Error")
		case .serverResponseLost:
			return String(localized: "Server Response Lost", comment: "Known iCloud Error")
		case .serviceUnavailable:
			return String(localized: "Service Unavailable: Please try again.", comment: "Known iCloud Error")
		case .tooManyParticipants:
			return String(localized: "Too Many Participants: a share cannot be saved because too many participants are attached to the share.", comment: "Known iCloud Error")
		case .unknownItem:
			return String(localized: "Unknown Item:  the specified record does not exist.", comment: "Known iCloud Error")
		case .userDeletedZone:
			return String(localized: "User Deleted Zone: the user has deleted this zone from the settings UI.", comment: "Known iCloud Error")
		case .zoneBusy:
			return String(localized: "Zone Busy: the server is too busy to handle the zone operation.", comment: "Known iCloud Error")
		case .zoneNotFound:
			return String(localized: "Zone Not Found: the specified record zone does not exist on the server.", comment: "Known iCloud Error")
		default:
			return String(localized: "Unhandled Error.", comment: "Unknown iCloud Error")
		}
	}
	
}
