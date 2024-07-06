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

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Import Type")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .opml: "OPML"
    ]
}

