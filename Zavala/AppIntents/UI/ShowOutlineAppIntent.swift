//
//  ShowOutline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import UIKit
import AppIntents
import VinOutlineKit

struct ShowOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "ShowOutlineIntent"
    static let title: LocalizedStringResource = "Show Outline"
    static let description = IntentDescription("Shows the given outline in the foremost window of Zavala.")
	static let openAppWhenRun = true
	
    @Parameter(title: "Outline")
	var outline: OutlineAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline)) { outline in
            DisplayRepresentation(
                title: "Show \(outline)",
                subtitle: ""
            )
        }
    }

	@MainActor
	func perform() async throws -> some IntentResult {
		guard let entityID = outline.id.entityID else {
			throw ZavalaAppIntentError.unexpectedError
		}

		#if targetEnvironment(macCatalyst)
		defer {
			appDelegate.appKitPlugin?.activateIgnoringOtherApps()
		}
		#endif

		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
			  let mainSplitViewController = appDelegate.mainCoordinator as? MainSplitViewController else {
			
			let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
			activity.userInfo = [Pin.UserInfoKeys.pin: Pin(documentID: entityID).userInfo]
			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)

			return .result()
		}
		
		await mainSplitViewController.handleDocument(entityID, isNavigationBranch: false)
	
        return .result()
    }
}


