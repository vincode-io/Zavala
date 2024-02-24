//
//  GetImagesForOutlineIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/7/21.
//

import Intents
import VinOutlineKit

class GetImagesForOutlineIntentHandler: NSObject, ZavalaIntentHandler, GetImagesForOutlineIntentHandling {

	func handle(intent: GetImagesForOutlineIntent, completion: @escaping (GetImagesForOutlineIntentResponse) -> Void) {
		resume()

		guard let outline = findOutline(intent.outline) else {
			suspend()
			completion(.init(code: .success, userActivity: nil))
			return
		}
		
		var files = [INFile]()
		
		outline.load()
		
		guard let imageGroups = outline.images?.values, !imageGroups.isEmpty else {
			outline.unload()
			suspend()
			completion(.init(code: .success, userActivity: nil))
			return
		}

		let allImages = imageGroups.flatMap({ $0 })
		
		for image in allImages {
			let file = INFile(data: image.data!, filename: "\(image.id.imageUUID).png", typeIdentifier: "public.png")
			files.append(file)
		}
		
		outline.unload()
		suspend()
		
		let response = GetImagesForOutlineIntentResponse(code: .success, userActivity: nil)
		response.images = files
		completion(response)
	}
	
}
