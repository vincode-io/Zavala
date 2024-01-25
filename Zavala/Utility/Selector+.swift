//
//  Selector+.swift
//  Zavala
//
//  Created by Maurice Parker on 12/31/20.
//

import UIKit

extension Selector {
	static let cut = #selector(UIResponder.cut(_:))
	static let copy = #selector(UIResponder.copy(_:))
	static let paste = #selector(UIResponder.paste(_:))

	static let selectAll = #selector(UIResponder.selectAll(_:))
	static let delete = #selector(UIResponder.delete(_:))
	
	static let find = #selector(UIResponder.find(_:))
	static let findAndReplace = #selector(UIResponder.findAndReplace(_:))
	static let findNext = #selector(UIResponder.findNext(_:))
	static let findPrevious = #selector(UIResponder.findPrevious(_:))
	static let useSelectionForFind = #selector(UIResponder.useSelectionForFind(_:))

	static let toggleBoldface = #selector(UIResponder.toggleBoldface(_:))
	static let toggleItalics = #selector(UIResponder.toggleItalics(_:))
	static let toggleUnderline = #selector(UIResponder.toggleUnderline(_:))
}
