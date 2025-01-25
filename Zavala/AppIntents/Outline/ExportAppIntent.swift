//
//  Export.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import UIKit
import AppIntents
import VinOutlineKit
import VinUtility

struct ExportAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "ExportIntent"
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.export", comment: "Intent title: Export")
    static let description = IntentDescription(LocalizedStringResource("intent.title.export-description", comment: "Intent description: Export the outline in various formats."))

    @Parameter(title: LocalizedStringResource("intent.parameter.outline", comment: "Intent parameter: Outline"))
	var outline: OutlineAppEntity

    @Parameter(title: LocalizedStringResource("intent.parameter.export-type", comment: "Intent parameter: Export Type"))
    var exportType: ExportTypeAppEnum

    @Parameter(title: LocalizedStringResource("intent.parameter.export-link-type", comment: "Intent parameter: Export Link Type"), default: .zavalaLinks)
    var exportLinkType: ExportLinkTypeAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.export-the-\(\.$outline)-as-\(\.$exportType)-using-\(\.$exportLinkType)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline, \.$exportType, \.$exportLinkType)) { outline, exportType, exportLinkType in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.export-the-\(outline)-as-\(exportType)-using-\(exportLinkType)", comment: "Import prediction: Export the <Outline> as <ExportType> using <ExportLinkType>"),
                subtitle: nil
            )
        }
    }

	@MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
		resume()
		
		guard let outline = findOutline(outline) else {
			await suspend()
			throw ZavalaAppIntentError.outlineNotFound
		}

		let useAltLinks = exportLinkType == .altLinks
		
		var exportFile: IntentFile?
		
		switch exportType {
		case .opml:
			if let opmlData = outline.opml(useAltLinks: useAltLinks).data(using: .utf8) {
				exportFile = IntentFile(data: opmlData, filename: outline.filename(type: .opml), type: .opml)
			}
		case .markdownDoc:
			if let markdownData = outline.markdownDoc(useAltLinks: useAltLinks).data(using: .utf8) {
				exportFile = IntentFile(data: markdownData, filename: outline.filename(type: .markdown), type: .markdown)
			}
		case .markdownList:
			if let markdownData = outline.markdownList(useAltLinks: useAltLinks).data(using: .utf8) {
				exportFile = IntentFile(data: markdownData, filename: outline.filename(type: .markdown), type: .markdown)
			}
		case .pdfDoc:
			let textView = UITextView()
			textView.attributedText = outline.printDoc()
			let pdfData = textView.generatePDF()
			exportFile = IntentFile(data: pdfData, filename: outline.filename(type: .pdf), type: .pdf)
		case .pdfList:
			let textView = UITextView()
			textView.attributedText = outline.printList()
			let pdfData = textView.generatePDF()
			exportFile = IntentFile(data: pdfData, filename: outline.filename(type: .pdf), type: .pdf)
		}

		await suspend()
		
		guard let exportFile else { throw ZavalaAppIntentError.unexpectedError }
		
		return .result(value: exportFile)
    }
}
