//
//  MoveRowsIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/14/21.
//

import Intents
import Templeton

class MoveRowsIntentHandler: NSObject, ZavalaIntentHandler, MoveRowsIntentHandling {

	func resolveDestination(for intent: MoveRowsIntent, with completion: @escaping (MoveRowsDestinationResolutionResult) -> Void) {
		guard intent.destination != .unknown else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: intent.destination))
	}
	
	func handle(intent: MoveRowsIntent, completion: @escaping (MoveRowsIntentResponse) -> Void) {
		resume()
		
		guard let intentRowEntityIDs = intent.rows,
			  let entityID = intent.outlineOrRow?.toEntityID(),
			  let outline = AccountManager.shared.findDocument(entityID)?.outline else {
				  suspend()
				  completion(.init(code: .failure, userActivity: nil))
				  return
			  }
		
		var outlines = Set<Outline>()
		outline.load()
		outlines.insert(outline)
		
		guard let rowContainer = outline.findRowContainer(entityID: entityID) else {
			outlines.forEach { $0.unload() }
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		var intraOutlineMoves = [Row]()
		var interOutlineMoves = [(Row, Row)]()

		let inputRows: [Row] = intentRowEntityIDs
			.compactMap { $0.toEntityID() }
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
				interOutlineMoves.append((inputRow, inputRow.duplicate(newOutline: outline)))
			}
		}
		
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
			guard let sourceOutline = interOutlineMove.0.outline else {
				continue
			}
			
			switch intent.destination {
			case .insideAtStart:
				sourceOutline.deleteRows([interOutlineMove.0])
				outline.createRowInsideAtStart(interOutlineMove.1, afterRowContainer: rowContainer)
			case .insideAtEnd:
				sourceOutline.deleteRows([interOutlineMove.0])
				outline.createRowInsideAtEnd(interOutlineMove.1, afterRowContainer: rowContainer)
			case .outside:
				if let afterRow = rowContainer as? Row {
					sourceOutline.deleteRows([interOutlineMove.0])
					outline.createRowOutside(interOutlineMove.1, afterRow: afterRow)
				}
			case .directlyAfter:
				if let afterRow = rowContainer as? Row {
					sourceOutline.deleteRows([interOutlineMove.0])
					outline.createRowDirectlyAfter(interOutlineMove.1, afterRow: afterRow)
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
		completion(.init(code: .success, userActivity: nil))
	}
	
}
