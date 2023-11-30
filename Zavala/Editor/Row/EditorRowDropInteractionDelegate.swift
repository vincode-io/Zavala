//
//  EditorRowDropInteractionDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 4/6/21.
//

import UIKit
import MobileCoreServices
import VinOutlineKit
import VinUtility

class EditorRowDropInteractionDelegate: NSObject, UIDropInteractionDelegate {
	
	weak var textView: EditorRowTextView?
	
	init(textView: EditorRowTextView) {
		self.textView = textView
	}
	
	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		guard !session.hasItemsConforming(toTypeIdentifiers: [Row.typeIdentifier]) else {
			return false
		}

		return session.hasItemsConforming(toTypeIdentifiers: [kUTTypeImage as String]) && session.items.count == 1
	}
	
	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		if let textView {
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
		if let itemProvider = session.items.first(where: { $0.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) })?.itemProvider {
			itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeImage as String) { [weak textView] (data, error) in
				guard let textView = textView, let data = data, let cgImage = UIImage.scaleImage(data, maxPixelSize: 1800) else { return }
				let image = UIImage(cgImage: cgImage)
				DispatchQueue.main.async {
					textView.replaceCharacters(textView.selectedRange, withImage: image)
				}
			}
		}
	}
	
}
