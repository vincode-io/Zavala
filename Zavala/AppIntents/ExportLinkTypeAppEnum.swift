//
//  ExportLinkTypeAppEnum.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

enum ExportLinkTypeAppEnum: String, AppEnum {
    case zavalaLinks
    case altLinks

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("intent.parameter.export-link-type", comment: "Intent parameter: Export Link Type"))
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
		.zavalaLinks: DisplayRepresentation(title: LocalizedStringResource("intent.parameter.zavala-deep-links", comment: "Export Link Type: Zavala Deep Links")) ,
        .altLinks: DisplayRepresentation(title: LocalizedStringResource("intent.parameter.relative-file-links", comment: "Export Link Type: Relative File Links"))
    ]
}

