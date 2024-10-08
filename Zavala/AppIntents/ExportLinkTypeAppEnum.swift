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

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Export Link Type")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .zavalaLinks: "Zavala Deep Links",
        .altLinks: "Relative File Links"
    ]
}

