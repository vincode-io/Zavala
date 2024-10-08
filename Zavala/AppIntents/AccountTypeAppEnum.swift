//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

enum AccountTypeAppEnum: String, AppEnum {
    case onMyDevice
    case iCloud

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Account Type")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .onMyDevice: "On My Device",
        .iCloud: "iCloud"
    ]
}

