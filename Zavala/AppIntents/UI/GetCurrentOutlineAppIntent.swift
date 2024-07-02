//
//  Created by Maurice Parker on 7/1/24.
//

import UIKit
import AppIntents

struct GetCurrentOutlineAppIntent: AppIntent {

    static let title: LocalizedStringResource = "Get Current Outline"
    static let description = IntentDescription("Get the currently viewed outline from the foremost window for Zavala.")

    static var parameterSummary: some ParameterSummary {
        Summary("Get Current Outline")
    }

	@MainActor
	func perform() async throws -> some IntentResult & ReturnsValue<OutlineAppEntity> {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
			  let outline = appDelegate.mainCoordinator?.selectedDocuments.first?.outline else {
			throw GetCurrentOutlineError.outlineNotFound
		}
		
		let outlineAppEntity = OutlineAppEntity()
		outlineAppEntity.id = EntityIDAppEntity(entityID: outline.id)
		outlineAppEntity.title = outline.title
		outlineAppEntity.ownerName = outline.ownerName
		outlineAppEntity.ownerEmail = outline.ownerEmail
		outlineAppEntity.ownerURL = outline.ownerURL
		outlineAppEntity.url = outline.id.url
		
        return .result(value: outlineAppEntity)
    }
}

private enum GetCurrentOutlineError: Error, CustomLocalizedStringResourceConvertible {
	case outlineNotFound
	
	var localizedStringResource: LocalizedStringResource {
		switch self {
		case .outlineNotFound:
			return "There isn't an outline currently being viewed."
		}
	}
}

