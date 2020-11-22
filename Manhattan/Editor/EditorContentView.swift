//
//  EditorContentView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

class EditorContentView: UIView, UIContentView {

	let textView = EditorTextView()
	var barViews = [UIView]()
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

		let adjustedIndentionWidth: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			if configuration.isChevronShowing {
				adjustedIndentionWidth = configuration.indentationWidth - 12
			} else {
				adjustedIndentionWidth = configuration.indentationWidth + 16
			}
		} else {
			adjustedIndentionWidth = configuration.indentationWidth
		}
		
		textView.removeConstraintsIncludingOwnedBySuperview()
		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedIndentionWidth),
			textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
		])

		// TODO: Figure out how to only remove the necessary barViews
		for barView in barViews {
			barView.removeFromSuperview()
		}
		barViews = [UIView]()

		// TODO: Rework to be more readable.  Right now, I can't even remember why the following where clause works.
		// I originally added it so that only the necessary barViews would get added and be more efficient.  Removing
		// it shouldn't break the code, but it does.  Try to only add the necessary barViews and remove the ones we don't need.
		for i in (0...configuration.indentionLevel) where barViews.count < i {
			addBarView(indentLevel: i, hasChevron: !(configuration.editorItem?.children.isEmpty ?? true))
		}

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

// MARK: Helpers

extension EditorContentView {
	
	private func addBarView(indentLevel: Int, hasChevron: Bool) {
		let barView = UIView()
		barView.backgroundColor = .quaternaryLabel
		barView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(barView)
		barViews.append(barView)

		var indention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			indention = CGFloat(22 - (indentLevel * 13))
			if hasChevron {
				indention = indention - 29
			}
		} else {
			indention = CGFloat(19 - (indentLevel * 10))
		}

		NSLayoutConstraint.activate([
			barView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: indention),
			barView.widthAnchor.constraint(equalToConstant: 2),
			barView.topAnchor.constraint(equalTo: topAnchor),
			barView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
	}
	
}
