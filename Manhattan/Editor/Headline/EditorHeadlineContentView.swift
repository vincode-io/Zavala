//
//  EditorHeadlineContentView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

class EditorHeadlineContentView: UIView, UIContentView {

	let textView = EditorHeadlineTextView()
	var textViewHeight: CGFloat?
	var bulletView: UIImageView?
	var barViews = [UIView]()
	var appliedConfiguration: EditorHeadlineContentConfiguration!
	var isTextChanged = false
	
	init(configuration: EditorHeadlineContentConfiguration) {
		super.init(frame: .zero)

		textView.delegate = self
		textView.editorDelegate = self
		
		textView.isScrollEnabled = false
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero

		if traitCollection.userInterfaceIdiom == .mac {
			let bodyFont = UIFont.preferredFont(forTextStyle: .body)
			textView.font = bodyFont.withSize(bodyFont.pointSize + 1)
		} else {
			textView.font = UIFont.preferredFont(forTextStyle: .body)
		}

		textView.backgroundColor = .clear
		textView.translatesAutoresizingMaskIntoConstraints = false
		
		addSubview(textView)

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
			guard let newConfig = newValue as? EditorHeadlineContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorHeadlineContentConfiguration) {
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		
		textView.headline = configuration.headline
		
		var attrs = [NSAttributedString.Key : Any]()
		if configuration.isComplete || configuration.isAncestorComplete {
			attrs[.foregroundColor] = UIColor.tertiaryLabel
		} else {
			attrs[.foregroundColor] = UIColor.label
		}
		
		if traitCollection.userInterfaceIdiom == .mac {
			let bodyFont = UIFont.preferredFont(forTextStyle: .body)
			attrs[.font] = bodyFont.withSize(bodyFont.pointSize + 1)
		} else {
			attrs[.font] = UIFont.preferredFont(forTextStyle: .body)
		}
		
		if configuration.isComplete {
			attrs[.strikethroughStyle] = 1
			attrs[.strikethroughColor] = UIColor.tertiaryLabel
		} else {
			attrs[.strikethroughStyle] = 0
		}
		
		let mutableAttrText = NSMutableAttributedString(attributedString: configuration.attributedText)
		let range = NSRange(location: 0, length: mutableAttrText.length)
		mutableAttrText.addAttributes(attrs, range: range)
		textView.attributedText = mutableAttrText

		let adjustedLeadingIndention: CGFloat
		let adjustedTrailingIndention: CGFloat
		if traitCollection.horizontalSizeClass != .compact {
			adjustedLeadingIndention = configuration.indentationWidth - 18
			adjustedTrailingIndention = -8
		} else {
			adjustedLeadingIndention = configuration.indentationWidth
			adjustedTrailingIndention = -25
		}
		
		textView.removeConstraintsOwnedBySuperview()
		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
			textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
			textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
		])

		if configuration.indentionLevel < barViews.count {
			for i in (configuration.indentionLevel..<barViews.count).reversed() {
				barViews[i].removeFromSuperview()
				barViews.remove(at: i)
			}
		}

		addBarViews()
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
			for i in 0..<barViews.count {
				barViews[i].removeFromSuperview()
			}
			barViews.removeAll()
			addBarViews()
		}
	}
	
}

// MARK: UITextViewDelegate

extension EditorHeadlineContentView: UITextViewDelegate {
	
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		textViewHeight = fittingSize.height
		return true
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		guard isTextChanged, let headline = appliedConfiguration.headline, let editorTextView = textView as? EditorHeadlineTextView else { return }
		
		if editorTextView.isSavingTextUnnecessary {
			editorTextView.isSavingTextUnnecessary = false
		} else {
			appliedConfiguration.delegate?.editorHeadlineTextChanged(headline: headline, attributedText: textView.attributedText)
		}
		
		isTextChanged = false
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		guard let headline = appliedConfiguration.headline else { return true }
		switch text {
		case "\n":
			appliedConfiguration.delegate?.editorHeadlineCreateHeadline(headline)
			return false
		default:
			isTextChanged = true
			return true
		}
	}
	
	func textViewDidChange(_ textView: UITextView) {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		if textViewHeight != fittingSize.height {
			textViewHeight = fittingSize.height
			invalidateIntrinsicContentSize()
			appliedConfiguration.delegate?.editorHeadlineInvalidateLayout()
		}
	}
	
}

// MARK: EditorTextViewDelegate

extension EditorHeadlineContentView: EditorHeadlineTextViewDelegate {
	
	override var undoManager: UndoManager? {
		appliedConfiguration.delegate?.editorHeadlineUndoManager
	}
	
	func deleteHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.editorHeadlineDeleteHeadline(headline, attributedText: attributedText)
	}
	
	func createHeadline(_ afterHeadline: Headline) {
		appliedConfiguration.delegate?.editorHeadlineCreateHeadline(afterHeadline)
	}
	
	func indentHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.editorHeadlineIndentHeadline(headline, attributedText: attributedText)
	}
	
	func outdentHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.editorHeadlineOutdentHeadline(headline, attributedText: attributedText)
	}
	
	func splitHeadline(_ headline: Headline, attributedText: NSAttributedString, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorHeadlineSplitHeadline(headline, attributedText: attributedText, cursorPosition: cursorPosition)
	}
	
}

// MARK: Helpers

extension EditorHeadlineContentView {
	
	@objc func swipedLeft(_ sender: UISwipeGestureRecognizer) {
		guard let headline = appliedConfiguration.headline else { return }
		appliedConfiguration.delegate?.editorHeadlineOutdentHeadline(headline, attributedText: textView.attributedText)
	}
	
	@objc func swipedRight(_ sender: UISwipeGestureRecognizer) {
		guard let headline = appliedConfiguration.headline else { return }
		appliedConfiguration.delegate?.editorHeadlineIndentHeadline(headline, attributedText: textView.attributedText)
	}
	
	private func addBarViews() {
		let configuration = appliedConfiguration as EditorHeadlineContentConfiguration
		
		if configuration.indentionLevel > 0 {
			let barViewsCount = barViews.count
			for i in (1...configuration.indentionLevel) {
				if i > barViewsCount {
					addBarView(indentLevel: i, hasChevron: configuration.isChevronShowing)
				}
			}
		}
	}
	
	private func addBarView(indentLevel: Int, hasChevron: Bool) {
		let barView = UIView()
		barView.backgroundColor = AppAssets.accessory
		barView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(barView)
		barViews.append(barView)

		var indention: CGFloat
		if traitCollection.horizontalSizeClass != .compact {
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
