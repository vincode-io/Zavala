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

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("label.text.row-destination", comment: "Row Destination"))
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .insideAtStart: DisplayRepresentation(title: LocalizedStringResource("label.text.inside-at-start", comment: "Inside at Start")),
        .insideAtEnd: DisplayRepresentation(title: LocalizedStringResource("label.text.inside-at-end", comment: "Inside at End")),
        .outside: DisplayRepresentation(title: LocalizedStringResource("label.text.outside", comment: "Outside")),
        .directlyAfter: DisplayRepresentation(title: LocalizedStringResource("label.text.directly-after", comment: "Directly After"))
    ]
}

