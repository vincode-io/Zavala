//
//  EditorContentView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

class EditorContentView: UIView, UIContentView {

	let textView = EditorTextView()
	var bulletView: UIImageView?
	var barViews = [UIView]()
	var appliedConfiguration: EditorContentConfiguration!
	var isTextChanged = false
	
	init(configuration: EditorContentConfiguration) {
		super.init(frame: .zero)

		textView.delegate = self
		textView.editorDelegate = self
		
		textView.isScrollEnabled = false
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		
		addSubview(textView)
		textView.translatesAutoresizingMaskIntoConstraints = false

		let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft(_:)))
		swipeLeftGesture.direction = .left
		addGestureRecognizer(swipeLeftGesture)
		
		let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight(_:)))
		swipeRightGesture.direction = .right
		addGestureRecognizer(swipeRightGesture)
		
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
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		
		textView.headline = configuration.headline
		
		var attrs = [NSAttributedString.Key : Any]()
		if configuration.isComplete || configuration.isAncestorComplete {
			attrs[.foregroundColor] = UIColor.secondaryLabel
		} else {
			attrs[.foregroundColor] = UIColor.label
		}
		
		attrs[.font] = UIFont.preferredFont(forTextStyle: .body)
		
		if configuration.isComplete {
			attrs[.strikethroughStyle] = 1
			attrs[.strikethroughColor] = UIColor.secondaryLabel
		} else {
			attrs[.strikethroughStyle] = 0
		}
		
		let mutableAttrText = NSMutableAttributedString(attributedString: configuration.attributedText)
		let range = NSRange(location: 0, length: mutableAttrText.length)
		mutableAttrText.addAttributes(attrs, range: range)
		textView.attributedText = mutableAttrText

		let adjustedLeadingIndention: CGFloat
		let adjustedTrailingIndention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			adjustedLeadingIndention = configuration.indentationWidth - 18
			adjustedTrailingIndention = 0
		} else {
			adjustedLeadingIndention = configuration.indentationWidth
			adjustedTrailingIndention = -25
		}
		
		textView.removeConstraintsOwnedBySuperview()
		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
			textView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
			textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
		])

		if configuration.indentionLevel < barViews.count {
			for i in (configuration.indentionLevel..<barViews.count).reversed() {
				barViews[i].removeFromSuperview()
				barViews.remove(at: i)
			}
		}

		if configuration.indentionLevel > 0 {
			let barViewsCount = barViews.count
			for i in (1...configuration.indentionLevel) {
				if i > barViewsCount {
					addBarView(indentLevel: i, hasChevron: configuration.isChevronShowing)
				}
			}
		}
	}
	
}

// MARK: UITextViewDelegate

extension EditorContentView: UITextViewDelegate {
	
	func textViewDidEndEditing(_ textView: UITextView) {
		guard isTextChanged, let headline = appliedConfiguration.headline else { return }
		appliedConfiguration.delegate?.textChanged(headline: headline, attributedText: textView.attributedText)
		isTextChanged = false
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		guard let headline = appliedConfiguration.headline else { return true }
		switch text {
		case "\n":
			appliedConfiguration.delegate?.createHeadline(headline)
			return false
		default:
			isTextChanged = true
			return true
		}
	}
	
}

// MARK: EditorTextViewDelegate

extension EditorContentView: EditorTextViewDelegate {
	
	override var undoManager: UndoManager? {
		appliedConfiguration.delegate?.undoManager
	}
	
	var currentKeyPresses: Set<UIKeyboardHIDUsage> {
		appliedConfiguration.delegate?.currentKeyPresses ?? Set<UIKeyboardHIDUsage>()
	}
	
	func deleteHeadline(_ headline: Headline) {
		appliedConfiguration.delegate?.deleteHeadline(headline)
	}
	
	func createHeadline(_ afterHeadline: Headline) {
		appliedConfiguration.delegate?.createHeadline(afterHeadline)
	}
	
	func indentHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.indentHeadline(headline, attributedText: attributedText)
	}
	
	func outdentHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.outdentHeadline(headline, attributedText: attributedText)
	}
	
	func toggleCompleteHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.toggleCompleteHeadline(headline, attributedText: attributedText)
	}
	
	func moveCursorUp(headline: Headline) {
		appliedConfiguration.delegate?.moveCursorUp(headline: headline)
	}
	
	func moveCursorDown(headline: Headline) {
		appliedConfiguration.delegate?.moveCursorDown(headline: headline)
	}
	
}

// MARK: Helpers

extension EditorContentView {
	
	@objc func swipedLeft(_ sender: UISwipeGestureRecognizer) {
		guard let headline = appliedConfiguration.headline else { return }
		appliedConfiguration.delegate?.outdentHeadline(headline, attributedText: textView.attributedText)
	}
	
	@objc func swipedRight(_ sender: UISwipeGestureRecognizer) {
		guard let headline = appliedConfiguration.headline else { return }
		appliedConfiguration.delegate?.indentHeadline(headline, attributedText: textView.attributedText)
	}
	
	private func addBarView(indentLevel: Int, hasChevron: Bool) {
		let barView = UIView()
		barView.backgroundColor = .quaternaryLabel
		barView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(barView)
		barViews.append(barView)

		var indention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			indention = CGFloat(0 - ((indentLevel + 1) * 13))
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
