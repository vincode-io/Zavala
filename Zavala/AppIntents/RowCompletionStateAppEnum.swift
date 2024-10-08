//
//  RowCompletionState.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum RowCompletionStateAppEnum: String, AppEnum {
    case complete
    case uncomplete

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Row Completion State")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .complete: "Complete",
        .uncomplete: "Uncomplete"
    ]
}

