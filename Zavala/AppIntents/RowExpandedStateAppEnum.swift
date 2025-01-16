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

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("label.text.row-expanded-state", comment: "Row Expanded State"))
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .expanded: DisplayRepresentation(title: LocalizedStringResource("label.text.expanded", comment: "Expanded")),
        .collapsed: DisplayRepresentation(title: LocalizedStringResource("label.text.collapsed", comment: "Collapsed"))
    ]
}

