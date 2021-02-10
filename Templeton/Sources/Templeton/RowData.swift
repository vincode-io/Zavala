//
//  RowData.swift
//  
//
//  Created by Maurice Parker on 2/9/21.
//

import Foundation

enum RowData: Codable {
	case text(TextRowData)

	var row: Row {
		switch self {
		case .text(let textRowData):
			return .text(textRowData.textRow)
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case type
		case textRowData
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		
		switch type {
		case "textRowData":
			let textRowData = try container.decode(TextRowData.self, forKey: .textRowData)
			self = .text(textRowData)
		default:
			fatalError()
		}
	}
	
	init(row: Row) {
		switch row {
		case .text(let textRow):
			self = .text(TextRowData(textRow: textRow))
		}
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case .text(let textRowData):
			try container.encode("textRowData", forKey: .type)
			try container.encode(textRowData, forKey: .textRowData)
		}
	}
	
}
