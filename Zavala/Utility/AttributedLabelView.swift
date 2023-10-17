//
//  AttributedLabelView.swift
//  Zavala
//
//  Created by Maurice Parker on 3/11/23.
//

import SwiftUI

struct AttributedLabelView: UIViewRepresentable {
	
	let string: NSAttributedString
	
	func makeUIView(context: Context) -> UITextView {
		return UITextView()
	}

	func updateUIView(_ view: UITextView, context: Context) {
		view.attributedText = string
		view.translatesAutoresizingMaskIntoConstraints = false
		view.isEditable = false
		view.isScrollEnabled = false
		view.textContainer.lineBreakMode = .byWordWrapping
		view.isUserInteractionEnabled = true
		view.adjustsFontForContentSizeCategory = true
		view.font = .preferredFont(forTextStyle: .body)
		view.textColor = UIColor.label
		view.tintColor = UIColor.accentColor
		view.backgroundColor = .clear
		view.textContainerInset = .zero
		view.setContentHuggingPriority(.required, for: .horizontal)
		view.setContentHuggingPriority(.required, for: .vertical)
		view.sizeToFit()
	}
	
}
