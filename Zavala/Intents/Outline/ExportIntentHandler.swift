//
//  ExportIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/8/21.
//

import Intents
import Templeton
import UIKit

class ExportIntentHandler: NSObject, ZavalaIntentHandler, ExportIntentHandling {
	
	func resolveExportType(for intent: ExportIntent, with completion: @escaping (ExportExportTypeResolutionResult) -> Void) {
		guard intent.exportType != .unknown else {
			completion(.unsupported(forReason: .required))
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
		
		let response = ExportIntentResponse(code: .success, userActivity: nil)
		
		switch intent.exportType {
		case .opml:
			if let opmlData = outline.opml().data(using: .utf8) {
				response.exportFile = INFile(data: opmlData, filename: outline.fileName(withSuffix: "opml"), typeIdentifier: "org.opml.opml")
			}
		case .markdownDoc:
			if let markdownData = outline.markdownDoc().data(using: .utf8) {
				response.exportFile = INFile(data: markdownData, filename: outline.fileName(withSuffix: "md"), typeIdentifier: "net.daringfireball.markdown")
			}
		case .markdownList:
			if let markdownData = outline.markdownList().data(using: .utf8) {
				response.exportFile = INFile(data: markdownData, filename: outline.fileName(withSuffix: "md"), typeIdentifier: "net.daringfireball.markdown")
			}
		case .pdfDoc:
			let textView = UITextView()
			textView.attributedText = outline.printDoc()
			let pdfData = textView.generatePDF()
			response.exportFile = INFile(data: pdfData, filename: outline.fileName(withSuffix: "pdf"), typeIdentifier: "com.adobe.pdf")
		case .pdfList:
			let textView = UITextView()
			textView.attributedText = outline.printList()
			let pdfData = textView.generatePDF()
			response.exportFile = INFile(data: pdfData, filename: outline.fileName(withSuffix: "pdf"), typeIdentifier: "com.adobe.pdf")
		default:
			break
		}
		
		suspend()
		completion(response)

	}
	
}
