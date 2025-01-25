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
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.get-images-for-outline", comment: "Intent title: Get Images for Outline")
    static let description = IntentDescription(LocalizedStringResource("intent.descrption.get-images-for-outline", comment: "Gets all the Images associated with the given Outline. Useful for integrating with Outlines exported as Markdown."))

    @Parameter(title: LocalizedStringResource("intent.parameter.outline", comment: "Intent parameter: Outline"))
	var outline: OutlineAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.get-images-for-\(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline)) { outline in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.get-images-for-\(outline)", comment: "Intent Prediction: Get Images for <Outline>"),
				subtitle: nil
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


