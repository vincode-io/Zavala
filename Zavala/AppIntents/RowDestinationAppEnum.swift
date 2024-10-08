//
//  RowDestination.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

enum RowDestinationAppEnum: String, AppEnum {
    case insideAtStart
    case insideAtEnd
    case outside
    case directlyAfter

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Row Destination")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .insideAtStart: "Inside at Start",
        .insideAtEnd: "Inside at End",
        .outside: "Outside",
        .directlyAfter: "Directly After"
    ]
}

