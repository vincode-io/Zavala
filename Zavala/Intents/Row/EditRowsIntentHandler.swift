//
//  EditRowsIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/22/21.
//

import UIKit
import Intents
import Templeton

class EditRowsIntentHandler: NSObject, ZavalaIntentHandler, EditRowsIntentHandling {

	func resolveTopic(for intent: EditRowsIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let topic = intent.topic else {
			completion(.notRequired())
			return
		}
		completion(.success(with: topic))
	}
	
	func resolveNote(for intent: EditRowsIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let note = intent.note else {
			completion(.notRequired())
			return
		}
		completion(.success(with: note))
	}
	
	func resolveComplete(for intent: EditRowsIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
		guard let complete = intent.complete else {
			completion(.notRequired())
			return
		}
		completion(.success(with: complete == 0 ? false : true))
	}
	
	func resolveExpanded(for intent: EditRowsIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
		guard let expanded = intent.expanded else {
			completion(.notRequired())
			return
		}
		completion(.success(with: expanded == 0 ? false : true))
	}
	
	func handle(intent: EditRowsIntent, completion: @escaping (EditRowsIntentResponse) -> Void) {
		guard let intentRows = intent.rows else {
				  completion(.init(code: .success, userActivity: nil))
				  return
			  }

		resume()

		var outlines = Set<Outline>()
		
		let rows: [Row] = intentRows
			.compactMap { $0.entityID?.toEntityID() }
			.compactMap {
				if let rowOutline = AccountManager.shared.findDocument($0)?.outline {
					rowOutline.load()
					outlines.insert(rowOutline)
					return rowOutline.findRow(id: $0.rowUUID)
				}
				return nil
			}
		
		for row in rows {
			switch intent.detail {
			case .topic:
				if let markdown = intent.topic {
					row.outline?.updateRow(row, rowStrings: .topicMarkdown(markdown), applyChanges: true)
				}
			case .note:
				if let markdown = intent.note, !markdown.isEmpty {
					row.outline?.updateRow(row, rowStrings: .noteMarkdown(markdown), applyChanges: true)
				} else {
					row.outline?.deleteNotes(rows: [row])
				}
			case .complete:
				if let complete = intent.complete {
					if complete == 1 {
						row.outline?.complete(rows: [row])
					} else {
						row.outline?.uncomplete(rows: [row])
					}
				}
			case .expanded:
				if let expanded = intent.expanded {
					if expanded == 1 {
						row.outline?.expand(rows: [row])
					} else {
						row.outline?.collapse(rows: [row])
					}
				}
			default:
				outlines.forEach { $0.unload() }
				suspend()
				completion(.init(code: .failure, userActivity: nil))
				return
			}
		}
		
		outlines.forEach { $0.unload() }
		suspend()
		
		let response = EditRowsIntentResponse(code: .success, userActivity: nil)
		response.rows = rows.map { IntentRow($0) }
		completion(response)
	}
	
}
