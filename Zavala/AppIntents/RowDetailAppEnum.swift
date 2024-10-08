//
//  RowDetailAppEnum.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum RowDetailAppEnum: String, AppEnum {
    case topic
    case note
    case complete
    case expanded

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Row Detail")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .topic: "Topic",
        .note: "Note",
        .complete: "Complete",
        .expanded: "Expanded"
    ]
}

