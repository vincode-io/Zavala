//
//  OutlineDetailAppEnum.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum OutlineDetailAppEnum: String, AppEnum {
    case title
    case ownerName
    case ownerEmail
    case ownerURL

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("label.text.outline-detail", comment: "Outline Detail"))
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .title: DisplayRepresentation(title: LocalizedStringResource("label.text.title", comment: "Title")),
        .ownerName: DisplayRepresentation(title: LocalizedStringResource("label.text.owner-name", comment: "Owner Name")),
        .ownerEmail: DisplayRepresentation(title: LocalizedStringResource("label.text.owner-email", comment: "Owner Email")),
        .ownerURL: DisplayRepresentation(title: LocalizedStringResource("label.text.owner-url", comment: "Owner URL"))
    ]
}



