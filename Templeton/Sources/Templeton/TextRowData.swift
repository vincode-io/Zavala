//
//  File.swift
//  
//
//  Created by Maurice Parker on 2/9/21.
//

import Foundation

struct TextRowData: Codable {
	
	private var id: EntityID
	private var topicData: Data?
	private var noteData: Data?
	private var isExpanded: Bool?
	private var isComplete: Bool?
	private var rowDatas: [RowData]?

	var textRow: TextRow {
		let textRow = TextRow(id: id)
		textRow.topicData = topicData
		textRow.noteData = noteData
		textRow.isExpanded = isExpanded
		textRow.isComplete = isComplete
		if let rowDatas = rowDatas {
			textRow.rows = rowDatas.map { $0.row }
		}
		return textRow
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "id"
		case topicData = "topicData"
		case noteData = "noteData"
		case isExpanded = "isExpanded"
		case isComplete = "isComplete"
		case rowDatas = "rowDatas"
	}
	
	init(textRow: TextRow) {
		self.id = textRow.id
		self.topicData = textRow.topicData
		self.noteData = textRow.noteData
		self.isExpanded = textRow.isExpanded
		self.isComplete = textRow.isComplete
		if let rows = textRow.rows {
			self.rowDatas = rows.map { RowData(row: $0) }
		}
	}
	
}
