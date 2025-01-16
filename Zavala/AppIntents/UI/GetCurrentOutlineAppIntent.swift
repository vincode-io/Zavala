//
//  Created by Maurice Parker on 7/1/24.
//

import UIKit
import AppIntents

struct GetCurrentOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent {
	static let intentClassName = "GetCurrentOutlineIntent"

    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.get-current-outline", comment: "Get Current Outline")
    static let description = IntentDescription(LocalizedStringResource("intent.description.get-current-outline", comment: "Get the currently viewed outline from the foremost window for Zavala."))

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.get-current-outline")
    }

	@MainActor
	func perform() async throws -> some IntentResult & ReturnsValue<OutlineAppEntity> {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
			  let outline = appDelegate.mainCoordinator?.selectedDocuments.first?.outline else {
			throw ZavalaAppIntentError.outlineNotBeingViewed
		}
		
		return .result(value: OutlineAppEntity(outline: outline))
    }
}

