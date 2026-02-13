//
//  Import.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct ImportAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "ImportIntent"
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.import", comment: "Intent title: Import")
    static let description = IntentDescription(LocalizedStringResource("intent.descrption.import-outline", comment: "Intent description: Import an Outline."))

    @Parameter(title: LocalizedStringResource("intent.parameter.input-file", comment: "Intent Parameter: Input File"))
    var inputFile: IntentFile

    @Parameter(title: LocalizedStringResource("intent.parameter.input-images", comment: "Intent Parameter: Input Images"))
    var inputImages: [IntentFile]?

    @Parameter(title: LocalizedStringResource("intent.parameter.import-type", comment: "Intent Parameter: Import Type"))
	var importType: ImportTypeAppEnum

    @Parameter(title: LocalizedStringResource("intent.parameter.account-type", comment: "Intent Parameter: Account Type"))
	var accountType: AccountTypeAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.import-the-\(\.$importType)-\(\.$inputFile)-into-\(\.$accountType)") {
            \.$inputImages
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$inputFile, \.$importType, \.$accountType, \.$inputImages)) { inputFile, importType, accountType, inputImages in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.predicition.import-the-\(importType)-\(inputFile)-into-\(accountType)", comment: "Import the <ImportType> <InputFile> into <AccountType>"),
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
		
		var images = [String:  Data]()
		if let inputImages {
			for intentImage in inputImages {
				let imageUUID = String(intentImage.filename.prefix(while: { $0 != "." }))
				images[imageUUID] = intentImage.data
			}
		}
		
		guard let outline = try? await account.importOPML(inputFile.data, tags: nil, images: images).outline else {
			await suspend()
			throw ZavalaAppIntentError.unableToParseOPML
		}

		await suspend()
		return await .result(value: OutlineAppEntity(outline: outline))
    }
}

