//
//  MoveRowsIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/14/21.
//

import Intents
import Templeton

class MoveRowsIntentHandler: NSObject, ZavalaIntentHandler, MoveRowsIntentHandling {

	func handle(intent: MoveRowsIntent, completion: @escaping (MoveRowsIntentResponse) -> Void) {
		resume()
		
		guard let intentRows = intent.rows,
			  let entityID = intent.entityID?.toEntityID(),
			  let outline = AccountManager.shared.findDocument(entityID)?.outline else {
				  suspend()
				  completion(.init(code: .success, userActivity: nil))
				  return
			  }
		
		var outlines = Set<Outline>()
		outline.load()
		outlines.insert(outline)
		
		guard let rowContainer = outline.findRowContainer(entityID: entityID) else {
			outlines.forEach { $0.unload() }
			suspend()
			completion(.init(code: .success, userActivity: nil))
			return
		}
		
		var intraOutlineMoves = [Row]()
		var interOutlineMoves = [Row]()

		let inputRows: [Row] = intentRows
			.compactMap { $0.entityID?.toEntityID() }
			.compactMap {
				if let rowOutline = AccountManager.shared.findDocument($0)?.outline {
					rowOutline.load()
					outlines.insert(rowOutline)
					return rowOutline.findRow(id: $0.rowUUID)
				}
				return nil
			}
		
		for inputRow in inputRows {
			if inputRow.outline == outline {
				intraOutlineMoves.append(inputRow)
			} else {
				interOutlineMoves.append(inputRow)
			}
		}
		
		var movedRows = intraOutlineMoves
		
		if !intraOutlineMoves.isEmpty {
			switch intent.destination {
			case .insideAtStart:
				outline.moveRowsInsideAtStart(intraOutlineMoves, afterRowContainer: rowContainer)
			case .insideAtEnd:
				outline.moveRowsInsideAtEnd(intraOutlineMoves, afterRowContainer: rowContainer)
			case .outside:
				if let afterRow = rowContainer as? Row {
					outline.moveRowsOutside(intraOutlineMoves, afterRow: afterRow)
				}
			case .directlyAfter:
				if let afterRow = rowContainer as? Row {
					outline.moveRowsDirectlyAfter(intraOutlineMoves, afterRow: afterRow)
				}
			default:
				outlines.forEach { $0.unload() }
				suspend()
				completion(.init(code: .failure, userActivity: nil))
				return
			}
		}
		
		for interOutlineMove in interOutlineMoves {
			guard let sourceOutline = interOutlineMove.outline else {
				continue
			}

			let rowGroup = RowGroup(interOutlineMove)
			let attachedRow = rowGroup.attach(to: outline)
			movedRows.append(attachedRow)
			
			switch intent.destination {
			case .insideAtStart:
				sourceOutline.deleteRows([interOutlineMove])
				outline.createRowsInsideAtStart([attachedRow], afterRowContainer: rowContainer)
			case .insideAtEnd:
				sourceOutline.deleteRows([interOutlineMove])
				outline.createRowsInsideAtEnd([attachedRow], afterRowContainer: rowContainer)
			case .outside:
				if let afterRow = rowContainer as? Row {
					sourceOutline.deleteRows([interOutlineMove])
					outline.createRowsOutside([attachedRow], afterRow: afterRow)
				}
			case .directlyAfter:
				if let afterRow = rowContainer as? Row {
					sourceOutline.deleteRows([interOutlineMove])
					outline.createRowsDirectlyAfter([attachedRow], afterRow: afterRow)
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
		
		let response = MoveRowsIntentResponse(code: .success, userActivity: nil)
		response.rows = movedRows.map { IntentRow($0) }
		completion(response)
	}
	
}
