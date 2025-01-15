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
    static let title: LocalizedStringResource = "Import"
    static let description = IntentDescription("Import an outline.")

    @Parameter(title: "Input File")
    var inputFile: IntentFile

    @Parameter(title: "Input Images")
    var inputImages: [IntentFile]?

    @Parameter(title: "Import Type")
	var importType: ImportTypeAppEnum

    @Parameter(title: "Account Type")
	var accountType: AccountTypeAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Import the \(\.$importType) \(\.$inputFile) into \(\.$accountType)") {
            \.$inputImages
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$inputFile, \.$importType, \.$accountType, \.$inputImages)) { inputFile, importType, accountType, inputImages in
            DisplayRepresentation(
                title: "Import the \(importType) \(inputFile) into \(accountType)",
                subtitle: ""
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
			throw ZavalaAppIntentError.unexpectedError
		}

		
		await suspend()
		return await .result(value: OutlineAppEntity(outline: outline))
    }
}

