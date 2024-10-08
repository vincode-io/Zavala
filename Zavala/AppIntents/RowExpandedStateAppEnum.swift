//
//  RowExpandedState.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

enum RowExpandedStateAppEnum: String, AppEnum {
    case expanded
    case collapsed

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Row Expanded State")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .expanded: "Expanded",
        .collapsed: "Collapsed"
    ]
}

