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
			  let rowContainer = AccountManager.shared.findRowContainer(entityID),
			  let outline = rowContainer.outline else {
				  suspend()
				  completion(.init(code: .failure, userActivity: nil))
				  return
			  }
		
		var intraOutlineMoves = [Row]()
		var interOutlineMoves = [(Row, Row)]()

		let inputRows = intentRowEntityIDs.compactMap({ $0.toEntityID() }).compactMap({ AccountManager.shared.findRow($0) })
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
				suspend()
				completion(.init(code: .failure, userActivity: nil))
				return
			}
		}
		
		for interOutlineMove in interOutlineMoves {
			switch intent.destination {
			case .insideAtStart:
				interOutlineMove.0.outline?.deleteRows([interOutlineMove.0])
				interOutlineMove.1.outline?.createRowInsideAtStart(interOutlineMove.1, afterRowContainer: rowContainer)
			case .insideAtEnd:
				interOutlineMove.0.outline?.deleteRows([interOutlineMove.0])
				interOutlineMove.1.outline?.createRowInsideAtEnd(interOutlineMove.1, afterRowContainer: rowContainer)
			case .outside:
				if let afterRow = rowContainer as? Row {
					interOutlineMove.0.outline?.deleteRows([interOutlineMove.0])
					interOutlineMove.1.outline?.createRowOutside(interOutlineMove.1, afterRow: afterRow)
				}
			case .directlyAfter:
				if let afterRow = rowContainer as? Row {
					interOutlineMove.0.outline?.deleteRows([interOutlineMove.0])
					interOutlineMove.1.outline?.createRowDirectlyAfter(interOutlineMove.1, afterRow: afterRow)
				}
			default:
				suspend()
				completion(.init(code: .failure, userActivity: nil))
				return
			}
		}
		
		suspend()
		completion(.init(code: .success, userActivity: nil))
	}
	
}
