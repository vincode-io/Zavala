//
//  EditorContentView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

class EditorContentView: UIView, UIContentView {

	let textView = EditorTextView()
	var appliedConfiguration: EditorContentConfiguration!

	init(configuration: EditorContentConfiguration) {
		super.init(frame: .zero)

		textView.delegate = self
		textView.editorDelegate = self
		
		textView.isScrollEnabled = false
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		textView.font = UIFont.preferredFont(forTextStyle: .body)
		
		addSubview(textView)
		textView.translatesAutoresizingMaskIntoConstraints = false

		apply(configuration: configuration)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorContentConfiguration) {
		guard appliedConfiguration != configuration, let editorItem = configuration.editorItem else { return }
		appliedConfiguration = configuration
		textView.attributedText = editorItem.attributedText

		textView.removeConstraintsIncludingOwnedBySuperview()
		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: configuration.indentationWidth ?? 0.0),
			textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
		])
	}
	
}

// MARK: UITextViewDelegate

extension EditorContentView: UITextViewDelegate {
	
	func textViewDidEndEditing(_ textView: UITextView) {
		appliedConfiguration.delegate?.textChanged(item: appliedConfiguration.editorItem!, attributedText: textView.attributedText)
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		switch text {
		case "\n":
			appliedConfiguration.delegate?.createHeadline(item: appliedConfiguration.editorItem!)
			return false
		default:
			return true
		}
	}
	
}

// MARK: EditorTextViewDelegate

extension EditorContentView: EditorTextViewDelegate {
	
	var item: EditorItem? {
		return appliedConfiguration.editorItem
	}
	
	func deleteHeadline(_: EditorTextView) {
		appliedConfiguration.delegate?.deleteHeadline(item: appliedConfiguration.editorItem!)
	}
	
	func createHeadline(_: EditorTextView) {
		appliedConfiguration.delegate?.createHeadline(item: appliedConfiguration.editorItem!)
	}
	
	func indent(_: EditorTextView, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.indent(item: appliedConfiguration.editorItem!, attributedText: attributedText)
	}
	
	func outdent(_: EditorTextView, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.outdent(item: appliedConfiguration.editorItem!, attributedText: attributedText)
	}
	
	func moveUp(_: EditorTextView) {
		appliedConfiguration.delegate?.moveUp(item: appliedConfiguration.editorItem!)
	}
	
	func moveDown(_: EditorTextView) {
		appliedConfiguration.delegate?.moveDown(item: appliedConfiguration.editorItem!)
	}
	
}
