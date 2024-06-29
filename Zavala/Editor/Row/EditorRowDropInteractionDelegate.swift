//
//  EditorRowDropInteractionDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 4/6/21.
//

import UIKit
import UniformTypeIdentifiers
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

		if session.hasItemsConforming(toTypeIdentifiers: [UTType.image.identifier]) && session.items.count == 1 {
			return true
		}
		
		return session.hasItemsConforming(toTypeIdentifiers: [UTType.url.identifier])
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
		guard let textView else { return }
		
		if let itemProvider = session.items.first(where: { $0.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) })?.itemProvider {
			itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak textView] (data, error) in
				guard let textView, let data, let cgImage = UIImage.scaleImage(data, maxPixelSize: 1800) else { return }
				let image = UIImage(cgImage: cgImage)
				Task { @MainActor in
					textView.replaceCharacters(textView.selectedRange, withImage: image)
				}
			}
		}
		
		if let itemProvider = session.items.first(where: { $0.itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) })?.itemProvider {
			Task {
				let itemURL: String? = await withCheckedContinuation { continuation in
					itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.url.identifier) { (data, error) in
						if let data, let itemURL = String(data: data, encoding: .utf8) {
							continuation.resume(returning: itemURL)
						} else {
							continuation.resume(returning: nil)
						}
					}
				}
				
				let itemText: String? = await withCheckedContinuation { continuation in
					itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier) { (data, error) in
						if let data, let itemText = String(data: data, encoding: .utf8) {
							continuation.resume(returning: itemText)
						} else {
							continuation.resume(returning: nil)
						}
					}
				}
				
				guard let itemURL, let url = URL(string: itemURL) else { return }
				
				guard let itemText else {
					let attrString = NSMutableAttributedString(string: itemURL)
					attrString.setAttributes([NSAttributedString.Key.link: url], range: .init(location: 0, length: itemURL.count))
					textView.textStorage.insert(attrString, at: textView.selectedRange.location)
					textView.textWasChanged()
					return
				}
				
				let attrString = NSMutableAttributedString(string: itemText)
				attrString.setAttributes([NSAttributedString.Key.link: url], range: .init(location: 0, length: itemText.count))
				textView.textStorage.insert(attrString, at: textView.selectedRange.location)
				textView.textWasChanged()

			}
		}
	}
	
}
