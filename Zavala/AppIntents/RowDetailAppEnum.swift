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

	static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("label.text.row-detail", comment: "Row Detail"))
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .topic: DisplayRepresentation(title: LocalizedStringResource("label.text.topic", comment: "Topic")),
        .note: DisplayRepresentation(title: LocalizedStringResource("label.text.note", comment: "Note")),
        .complete: DisplayRepresentation(title: LocalizedStringResource("label.text.complete", comment: "Complete")),
        .expanded: DisplayRepresentation(title: LocalizedStringResource("label.text.expanded", comment: "Expanded"))
    ]
}

