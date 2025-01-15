//
//  RequestReview.swift
//  Zavala
//
//  Created by Maurice Parker on 1/10/24.
//

import UIKit
import StoreKit
import VinOutlineKit
import VinUtility

@MainActor
struct RequestReview {
	
	// Only prompt every 30 days if they have 10 active documents and the app version is different
	static func request() {
		if BuildInfo.shared.versionNumber != AppDefaults.shared.lastReviewPromptAppVersion &&
			Date().addingTimeInterval(-2592000) > AppDefaults.shared.lastReviewPromptDate ?? .distantPast &&
			appDelegate.accountManager.activeDocuments.count >= 10 {
			
			AppDefaults.shared.lastReviewPromptAppVersion = BuildInfo.shared.versionNumber
			AppDefaults.shared.lastReviewPromptDate = Date()
			
			guard let scene = UIApplication.shared.foregroundActiveScene else { return }
			AppStore.requestReview(in: scene)
		}
	}
	
}
