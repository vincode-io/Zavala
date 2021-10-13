//
//  IntentRowDestination+.swift
//  Zavala
//
//  Created by Maurice Parker on 10/12/21.
//

import Foundation
import Templeton

extension IntentRowDestination {
	
	func toRowDestination() -> RowDestination {
		switch self {
		case .insideAtStart:
			return .insideAtStart
		case .insideAtEnd:
			return .insideAtEnd
		case .outside:
			return .outside
		case .directlyAfter:
			return .directlyAfter
		default:
			fatalError("Unknown row destination")
		}
	}
	
}
