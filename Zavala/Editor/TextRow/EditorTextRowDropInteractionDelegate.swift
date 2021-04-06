//
//  EditorTextViewDropInteractionDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 4/6/21.
//

import UIKit

class EditorTextRowDropInteractionDelegate: NSObject, UIDropInteractionDelegate {
	
	weak var textView: EditorTextRowTextView?
	
	init(textView: EditorTextRowTextView) {
		self.textView = textView
	}
	
	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		return session.hasItemsConforming(toTypeIdentifiers: [kUTTypeImage as String, kUTTypeText as String]) && session.items.count == 1
	}
	
	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		if let textView = textView {
			textView.becomeFirstResponder()
			let point = session.location(in: textView)
			if let position = textView.closestPosition(to: point) {
				textView.selectedTextRange = textView.textRange(from: position, to: position)
			}
		}
		
		let dropProposal: UIDropProposal = UIDropProposal(operation: .copy)
		dropProposal.isPrecise = true
		return dropProposal
	}
	
	func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
		session.loadObjects(ofClass: UIImage.self) { [weak textView] (imageItems) in
			guard let textView = textView, let image = imageItems.first as? UIImage else { return }
			textView.replaceCharacters(textView.selectedRange, withImage: image)
		}
		
		session.loadObjects(ofClass: NSString.self) { [weak textView] (stringItems) in
			guard let textView = textView, let text = stringItems.first as? String else { return }
			textView.replaceCharacters(textView.selectedRange, withText: text)
		}
	}
	
}
