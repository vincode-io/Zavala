//
//  GetCurrentTags.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import UIKit
import AppIntents
import VinOutlineKit

struct GetCurrentTagsAppIntent: AppIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "GetCurrentTagsIntent"
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.get-current-tags", comment: "Get Current Tags")
    static let description = IntentDescription(LocalizedStringResource("intent.description.get-current-tags", comment: "Gets the name of the currently selected Tags if there are any."))

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.get-current-tags")
    }

	@MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
			  let tags = (appDelegate.mainCoordinator as? MainSplitViewController)?.selectedTags else {
			throw ZavalaAppIntentError.noTagsSelected
		}
			
		let tagNames = tags.map { $0.name }
		return .result(value: tagNames)
    }
}


