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

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Export Type")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .opml: "OPML",
        .markdownDoc: "Markdown Doc",
        .markdownList: "Markdown List",
        .pdfDoc: "PDF Doc",
        .pdfList: "PDF List"
    ]
}

