//
//  ExportIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/8/21.
//

import Intents
import VinOutlineKit
import UIKit

class ExportIntentHandler: NSObject, ZavalaIntentHandler, ExportIntentHandling {

	func resolveExportLinkType(for intent: ExportIntent, with completion: @escaping (ExportLinkTypeResolutionResult) -> Void) {
		guard intent.exportLinkType != .unknown else {
			completion(.needsValue())
			return
		}
		completion(.success(with: intent.exportLinkType))
	}
	
	func resolveExportType(for intent: ExportIntent, with completion: @escaping (IntentExportTypeResolutionResult) -> Void) {
		guard intent.exportType != .unknown else {
			completion(.needsValue())
			return
		}
		completion(.success(with: intent.exportType))
	}
	
	func handle(intent: ExportIntent, completion: @escaping (ExportIntentResponse) -> Void) {
		resume()
		
		guard let outline = findOutline(intent.outline) else {
			suspend()
			completion(.init(code: .success, userActivity: nil))
			return
		}
		
		let useAltLinks = intent.exportLinkType == .altLinks
		
		let response = ExportIntentResponse(code: .success, userActivity: nil)
		
		switch intent.exportType {
		case .opml:
			if let opmlData = outline.opml(useAltLinks: useAltLinks).data(using: .utf8) {
				response.exportFile = INFile(data: opmlData, filename: outline.filename(representation: DataRepresentation.opml), typeIdentifier: DataRepresentation.opml.typeIdentifier)
			}
		case .markdownDoc:
			if let markdownData = outline.markdownDoc(useAltLinks: useAltLinks).data(using: .utf8) {
				response.exportFile = INFile(data: markdownData, filename: outline.filename(representation: DataRepresentation.markdown), typeIdentifier: DataRepresentation.markdown.typeIdentifier)
			}
		case .markdownList:
			if let markdownData = outline.markdownList(useAltLinks: useAltLinks).data(using: .utf8) {
				response.exportFile = INFile(data: markdownData, filename: outline.filename(representation: DataRepresentation.markdown), typeIdentifier: DataRepresentation.markdown.typeIdentifier)
			}
		case .pdfDoc:
			let textView = UITextView()
			textView.attributedText = outline.printDoc()
			let pdfData = textView.generatePDF()
			response.exportFile = INFile(data: pdfData, filename: outline.filename(representation: DataRepresentation.pdf), typeIdentifier: DataRepresentation.pdf.typeIdentifier)
		case .pdfList:
			let textView = UITextView()
			textView.attributedText = outline.printList()
			let pdfData = textView.generatePDF()
			response.exportFile = INFile(data: pdfData, filename: outline.filename(representation: DataRepresentation.pdf), typeIdentifier: DataRepresentation.pdf.typeIdentifier)
		default:
			break
		}
		
		suspend()
		completion(response)

	}
	
}
