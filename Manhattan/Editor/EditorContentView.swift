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
		textView.text = editorItem.plainText

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

}

// MARK: EditorTextViewDelegate

extension EditorContentView: EditorTextViewDelegate {
	
	func newHeadline(_: EditorTextView) {
		appliedConfiguration.delegate?.newHeadline(item: appliedConfiguration.editorItem!)
	}
	
	func indent(_: EditorTextView) {
		appliedConfiguration.delegate?.indent(item: appliedConfiguration.editorItem!)
	}
	
	func outdent(_: EditorTextView) {
		appliedConfiguration.delegate?.outdent(item: appliedConfiguration.editorItem!)
	}
	
	func moveUp(_: EditorTextView) {
		appliedConfiguration.delegate?.moveUp(item: appliedConfiguration.editorItem!)
	}
	
	func moveDown(_: EditorTextView) {
		appliedConfiguration.delegate?.moveDown(item: appliedConfiguration.editorItem!)
	}
	
}
