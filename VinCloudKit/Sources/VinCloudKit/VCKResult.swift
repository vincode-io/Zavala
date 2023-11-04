//
//  VCKResult.swift
//
//  Created by Maurice Parker on 3/26/20.
//  Copyright © 2020 Ranchero Software, LLC. All rights reserved.
//

import Foundation
import CloudKit

public enum VCKResult {
	case success
	case retry(afterSeconds: Double)
	case limitExceeded
	case changeTokenExpired
	case partialFailure(error: CKError)
	case serverRecordChanged(error: CKError)
	case zoneNotFound
	case userDeletedZone
	case failure(error: Error)
	
	public static func refine(_ error: Error?) -> VCKResult {
        guard error != nil else { return .success }
        
        guard let ckError = error as? CKError else {
            return .failure(error: error!)
        }
		
		switch ckError.code {
		case .serviceUnavailable, .requestRateLimited, .zoneBusy:
			if let retry = ckError.retryAfterSeconds {
				return .retry(afterSeconds: retry)
			} else {
				return .failure(error: ckError)
			}
		case .zoneNotFound:
			return .zoneNotFound
		case .userDeletedZone:
			return .userDeletedZone
		case .changeTokenExpired:
			return .changeTokenExpired
		case .serverRecordChanged:
			return .serverRecordChanged(error: ckError)
		case .partialFailure:
			if let partialErrors = ckError.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: CKError] {
				if let zoneResult = anyRequestErrors(partialErrors) {
					return zoneResult
				} else {
					return .partialFailure(error: ckError)
				}
			} else {
				return .failure(error: ckError)
			}
		case .limitExceeded:
			return .limitExceeded
		default:
			return .failure(error: ckError)
		}
	}
	
}

private extension VCKResult {
	
	static func anyRequestErrors(_ errors: [AnyHashable: CKError]) -> VCKResult? {
		if errors.values.contains(where: { $0.code == .changeTokenExpired } ) {
			return .changeTokenExpired
		}
		if errors.values.contains(where: { $0.code == .zoneNotFound } ) {
			return .zoneNotFound
		}
		if errors.values.contains(where: { $0.code == .userDeletedZone } ) {
			return .userDeletedZone
		}
		return nil
	}
	
}
