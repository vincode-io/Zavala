//
//  OutlineTextDropDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 12/16/20.
//

import UIKit
import VinOutlineKit

class OutlineTextDropDelegate: NSObject, UITextDropDelegate {
	
	// We dont' allow local text drops because regular dragging and dropping of Headlines was dropping Markdown into our text view
	func textDroppableView(_ textDroppableView: UIView & UITextDroppable, proposalForDrop drop: UITextDropRequest) -> UITextDropProposal {
		if drop.dropSession.localDragSession == nil && !drop.dropSession.hasItemsConforming(toTypeIdentifiers: [Row.typeIdentifier]) {
			return UITextDropProposal(operation: .copy)
		} else {
			return UITextDropProposal(operation: .cancel)
		}
	}
	
}
