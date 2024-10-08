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
    static let title: LocalizedStringResource = "Get Current Tags"
    static let description = IntentDescription("Gets the name of the currently selected Tags if there are any.")

    static var parameterSummary: some ParameterSummary {
        Summary("Get Current Tags")
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


