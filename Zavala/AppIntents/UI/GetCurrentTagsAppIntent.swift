//
//  GetCurrentTags.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct GetCurrentTagsAppIntent: AppIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "GetCurrentTagsIntent"
    static let title: LocalizedStringResource = "Get Current Tags"
    static let description = IntentDescription("Gets the name of the currently selected Tags if there are any.")

    static var parameterSummary: some ParameterSummary {
        Summary("Get Current Tags")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // TODO: Place your refactored intent handler code here.
        return .result(value: String(/* fill in result initializer here */))
    }
}


