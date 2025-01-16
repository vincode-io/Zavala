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
	static let title: LocalizedStringResource = LocalizedStringResource("intent.title.add-outline", comment: "Intent Title: Add Outline")
	static let description = IntentDescription(LocalizedStringResource("intent.description.add-outline", comment: "Intent Description: Adds an Outline"))

	@Parameter(title: LocalizedStringResource("intent.parameter.account-type", comment: "Intent Parameter: Account Type"),
			   requestValueDialog: IntentDialog(LocalizedStringResource("intent.parameter.account-type-request", comment: "Intent request dialog: Which Account do you want to add this Outline to?")))
	var accountType: AccountTypeAppEnum

	@Parameter(title: LocalizedStringResource("intent.parameter.title", comment: "Intent Parameter: Title"),
			   requestValueDialog: IntentDialog(LocalizedStringResource("intent.parameter.outline-title-request", comment: "Intent request dialog: What is the title of the new Outline?")))
    var title: String

    @Parameter(title: LocalizedStringResource("intent.parameter.tag-names", comment: "Intent Parameter: Tag Names"))
    var tagNames: [String]?

    static var parameterSummary: some ParameterSummary {
		Summary("intent.summary.add-outline-\(\.$title)-to-\(\.$accountType)") {
            \.$tagNames
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$title, \.$tagNames, \.$accountType)) { title, tagNames, accountType in
            DisplayRepresentation(
                title: LocalizedStringResource("intent.prediction.add-outline-\(title)-to-\(accountType)", comment: "Intent Prediction: Add Outline titled <title> to <accountType>"),
                subtitle: nil
            )
        }
    }

	func perform() async throws -> some IntentResult & ReturnsValue<OutlineAppEntity> {
		await resume()
		
		let acctType = accountType == .onMyDevice ? AccountType.local : AccountType.cloudKit
		guard let account = await appDelegate.accountManager.findAccount(accountType: acctType) else {
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
		await outline.update(numberingStyle: defaults.numberingStyle,
							 checkSpellingWhileTyping: defaults.checkSpellingWhileTyping,
							 correctSpellingAutomatically: defaults.correctSpellingAutomatically,
							 automaticallyCreateLinks: defaults.automaticallyCreateLinks,
							 automaticallyChangeLinkTitles: defaults.automaticallyChangeLinkTitles,
							 ownerName: defaults.ownerName,
							 ownerEmail: defaults.ownerEmail,
							 ownerURL: defaults.ownerURL)
		
		return await .result(value: OutlineAppEntity(outline: outline))
    }
}

