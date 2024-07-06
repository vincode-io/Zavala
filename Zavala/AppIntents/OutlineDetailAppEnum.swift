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

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Outline Detail")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .title: "Title",
        .ownerName: "Owner Name",
        .ownerEmail: "Owner Email",
        .ownerURL: "Owner URL"
    ]
}

