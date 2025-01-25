//
//  ExportType.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

enum ExportTypeAppEnum: String, AppEnum {
    case opml
    case markdownDoc
    case markdownList
    case pdfDoc
    case pdfList

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("intent.parameter.export-type", comment: "Intent parameter: Export Type"))
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .opml: DisplayRepresentation(title: LocalizedStringResource("intent.parameter.type-opml", comment: "Export type: OPML")),
        .markdownDoc: DisplayRepresentation(title: LocalizedStringResource("intent.parameter.export-type-markdown-doc", comment: "Export type: Markdown Doc")),
        .markdownList: DisplayRepresentation(title: LocalizedStringResource("intent.parameter.export-type-markdown-list", comment: "Export type: Markdown List")),
        .pdfDoc: DisplayRepresentation(title: LocalizedStringResource("intent.parameter.export-type-pdf-doc", comment: "Export type: PDF Doc")),
        .pdfList: DisplayRepresentation(title: LocalizedStringResource("intent.parameter.export-type-pdf-list", comment: "Export type: PDF List"))
    ]
}






