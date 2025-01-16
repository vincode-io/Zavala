//
//  ImportType.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

enum ImportTypeAppEnum: String, AppEnum {
    case opml

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("intent.parameter.import-type", comment: "Intent Parameter: Import Type"))
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .opml: DisplayRepresentation(title: LocalizedStringResource("intent.parameter.type-opml", comment: "Import type: OPML"))
    ]
}

