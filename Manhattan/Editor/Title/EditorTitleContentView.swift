//
//  EditorTitleContentView.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton

class EditorTitleContentView: UIView, UIContentView {

	let textView = UITextView()
	var textViewHeight: CGFloat?
	var outline: Outline
	var appliedConfiguration: EditorTitleContentConfiguration!
	
	init(configuration: EditorTitleContentConfiguration) {
		self.outline = configuration.outline
		super.init(frame: .zero)

		textView.delegate = self
		
		textView.isScrollEnabled = false
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		textView.font = UIFont.preferredFont(forTextStyle: .headline)
		textView.textAlignment = .center
		textView.backgroundColor = .clear
		textView.translatesAutoresizingMaskIntoConstraints = false
		
		addSubview(textView)

		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
		])

		apply(configuration: configuration)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorTitleContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorTitleContentConfiguration) {
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		outline = configuration.outline
		textView.text = outline.title
	}
	
}

// MARK: UITextViewDelegate

extension EditorTitleContentView: UITextViewDelegate {
	
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		textViewHeight = fittingSize.height
		return true
	}

	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		switch text {
		case "\n":
			appliedConfiguration.delegate?.createHeadline()
			return false
		default:
			return true
		}
	}
	
	func textViewDidChange(_ textView: UITextView) {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		if textViewHeight != fittingSize.height {
			textViewHeight = fittingSize.height
			invalidateIntrinsicContentSize()
			appliedConfiguration.delegate?.invalidateLayout()
		}
	}
	
}
