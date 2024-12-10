//
//  AddOutline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct AddOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "AddOutlineIntent"
    static let title: LocalizedStringResource = "Add Outline"
    static let description = IntentDescription("Adds an Outline.")

	@Parameter(title: "Account Type", requestValueDialog: "Which Account did you want to add this Outline to?")
	var accountType: AccountTypeAppEnum

	@Parameter(title: "Title", requestValueDialog: "What is the title for the new Outline?")
    var title: String

    @Parameter(title: "Tag Names")
    var tagNames: [String]?

    static var parameterSummary: some ParameterSummary {
        Summary("Add Outline titled \(\.$title) to \(\.$accountType)") {
            \.$tagNames
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$title, \.$tagNames, \.$accountType)) { title, tagNames, accountType in
            DisplayRepresentation(
                title: "Add Outline titled \(title) to \(accountType)",
                subtitle: ""
            )
        }
    }

	func perform() async throws -> some IntentResult & ReturnsValue<OutlineAppEntity> {
		await resume()
		
		let acctType = accountType == .onMyDevice ? AccountType.local : AccountType.cloudKit
		guard let account = await AccountManager.shared.findAccount(accountType: acctType) else {
			await suspend()
			throw ZavalaAppIntentError.unavailableAccount
		}
		
		var tags = [Tag]()
		for tagName in tagNames ?? [] {
			if !tagName.isEmpty {
				await tags.append(account.createTag(name: tagName))
			}
		}
		
		guard let outline = await account.createOutline(title: title, tags: tags).outline else {
			await suspend()
			throw ZavalaAppIntentError.unexpectedError
		}

		let defaults = AppDefaults.shared
		await outline.update(checkSpellingWhileTyping: defaults.checkSpellingWhileTyping,
							 correctSpellingAutomatically: defaults.correctSpellingAutomatically,
							 automaticallyCreateLinks: defaults.automaticallyCreateLinks,
							 automaticallyChangeLinkTitles: defaults.automaticallyChangeLinkTitles,
							 ownerName: defaults.ownerName,
							 ownerEmail: defaults.ownerEmail,
							 ownerURL: defaults.ownerURL)
		
		return await .result(value: OutlineAppEntity(outline: outline))
    }
}

