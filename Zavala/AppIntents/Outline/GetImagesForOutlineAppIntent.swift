//
//  GetImagesForOutline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct GetImagesForOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "GetImagesForOutlineIntent"
    static let title: LocalizedStringResource = "Get Images For Outline"
    static let description = IntentDescription("Gets all the Images associated with the given Outline. Useful for integrating with Outlines exported as Markdown.")

    @Parameter(title: "Outline")
	var outline: OutlineAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Get Images for \(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline)) { outline in
            DisplayRepresentation(
                title: "Get Images for \(outline)",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[IntentFile]> {
		await resume()

		guard let outline = await findOutline(outline) else {
			await suspend()
			throw ZavalaAppIntentError.outlineNotFound
		}

		var files = [IntentFile]()
		
		await outline.load()
		
		guard let imageGroups = await outline.images?.values, !imageGroups.isEmpty else {
			await outline.unload()
			await suspend()
			return .result(value: files)
		}

		let allImages = imageGroups.flatMap({ $0 })
		
		for image in allImages {
			let file = await IntentFile(data: image.data!, filename: "\(image.id.imageUUID).png", type: .png)
			files.append(file)
		}
		
		await outline.unload()

		await suspend()
		return .result(value: files)
    }
	
}


