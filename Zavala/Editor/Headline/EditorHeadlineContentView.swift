//
//  EditorHeadlineContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

class EditorHeadlineContentView: UIView, UIContentView {

	let textView = EditorHeadlineTextView()
	var noteTextView: EditorHeadlineNoteTextView?
	var bulletView: UIImageView?
	var barViews = [UIView]()
	
	var appliedConfiguration: EditorHeadlineContentConfiguration!
	
	var textRowStrings: TextRowStrings {
		return TextRowStrings(topic: textView.attributedText, note: noteTextView?.attributedText)
	}
	
	init(configuration: EditorHeadlineContentConfiguration) {
		super.init(frame: .zero)

		textView.editorDelegate = self
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

		configureTextView(configuration: configuration)
		configureNoteTextView(configuration: configuration)

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
		
		if let noteTextView = noteTextView {
			noteTextView.removeConstraintsOwnedBySuperview()
			NSLayoutConstraint.activate([
				textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
				textView.bottomAnchor.constraint(equalTo: noteTextView.topAnchor, constant: -4),
				noteTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				noteTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				noteTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)

			])
		} else {
			NSLayoutConstraint.activate([
				textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
				textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
			])
		}

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

// MARK: EditorTextViewDelegate

extension EditorHeadlineContentView: EditorHeadlineTextViewDelegate {
	
	var editorHeadlineTextViewUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorHeadlineUndoManager
	}
	
	var editorHeadlineTextViewTextRowStrings: TextRowStrings {
		return textRowStrings
	}
	
	func invalidateLayout(_: EditorHeadlineTextView) {
		invalidateIntrinsicContentSize()
		appliedConfiguration.delegate?.editorHeadlineInvalidateLayout()
	}
	
	func textChanged(_: EditorHeadlineTextView, headline: TextRow, isInNotes: Bool, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorHeadlineTextChanged(headline: headline, textRowStrings: textRowStrings, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func deleteHeadline(_: EditorHeadlineTextView, headline: TextRow) {
		appliedConfiguration.delegate?.editorHeadlineDeleteHeadline(headline, textRowStrings: textRowStrings)
	}
	
	func createHeadline(_: EditorHeadlineTextView, beforeHeadline: TextRow) {
		appliedConfiguration.delegate?.editorHeadlineCreateHeadline(beforeHeadline: beforeHeadline)
	}
	
	func createHeadline(_: EditorHeadlineTextView, afterHeadline: TextRow) {
		appliedConfiguration.delegate?.editorHeadlineCreateHeadline(afterHeadline: afterHeadline, textRowStrings: textRowStrings)
	}
	
	func indentHeadline(_: EditorHeadlineTextView, headline: TextRow) {
		appliedConfiguration.delegate?.editorHeadlineIndentHeadline(headline, textRowStrings: textRowStrings)
	}
	
	func outdentHeadline(_: EditorHeadlineTextView, headline: TextRow) {
		appliedConfiguration.delegate?.editorHeadlineOutdentHeadline(headline, textRowStrings: textRowStrings)
	}
	
	func splitHeadline(_: EditorHeadlineTextView, headline: TextRow, topic: NSAttributedString, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorHeadlineSplitHeadline(headline, topic: topic, cursorPosition: cursorPosition)
	}
	
	func createHeadlineNote(_: EditorHeadlineTextView, headline: TextRow) {
		appliedConfiguration.delegate?.editorHeadlineCreateHeadlineNote(headline, textRowStrings: textRowStrings)
	}
	
	func editLink(_: EditorHeadlineTextView, _ link: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorHeadlineEditLink(link, range: range)
	}
	
}

extension EditorHeadlineContentView: EditorHeadlineNoteTextViewDelegate {

	var editorHeadlineNoteTextViewUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorHeadlineUndoManager
	}
	
	var editorHeadlineNoteTextViewAttibutedTexts: TextRowStrings {
		return textRowStrings
	}
	
	func invalidateLayout(_: EditorHeadlineNoteTextView) {
		invalidateIntrinsicContentSize()
		appliedConfiguration.delegate?.editorHeadlineInvalidateLayout()
	}
	
	func textChanged(_: EditorHeadlineNoteTextView, headline: TextRow, isInNotes: Bool, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorHeadlineTextChanged(headline: headline, textRowStrings: textRowStrings, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func deleteHeadlineNote(_: EditorHeadlineNoteTextView, headline: TextRow) {
		appliedConfiguration.delegate?.editorHeadlineDeleteHeadlineNote(headline, textRowStrings: textRowStrings)
	}
	
	func moveCursorTo(_: EditorHeadlineNoteTextView, headline: TextRow) {
		appliedConfiguration.delegate?.editorHeadlineMoveCursorTo(headline: headline)
	}
	
	func moveCursorDown(_: EditorHeadlineNoteTextView, headline: TextRow) {
		appliedConfiguration.delegate?.editorHeadlineMoveCursorDown(headline: headline)
	}
	
	func editLink(_: EditorHeadlineNoteTextView, _ link: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorHeadlineEditLink(link, range: range)
	}
	
}

// MARK: Helpers

extension EditorHeadlineContentView {
	
	@objc func swipedLeft(_ sender: UISwipeGestureRecognizer) {
		guard let headline = appliedConfiguration.headline else { return }
		appliedConfiguration.delegate?.editorHeadlineOutdentHeadline(headline, textRowStrings: textRowStrings)
	}
	
	@objc func swipedRight(_ sender: UISwipeGestureRecognizer) {
		guard let headline = appliedConfiguration.headline else { return }
		appliedConfiguration.delegate?.editorHeadlineIndentHeadline(headline, textRowStrings: textRowStrings)
	}
	
	private func configureTextView(configuration: EditorHeadlineContentConfiguration) {
		textView.headline = configuration.headline
		
		var attrs = [NSAttributedString.Key : Any]()
		if configuration.isComplete || configuration.isAncestorComplete {
			attrs[.foregroundColor] = UIColor.tertiaryLabel
		} else {
			attrs[.foregroundColor] = UIColor.label
		}
		
		if configuration.isComplete {
			attrs[.strikethroughStyle] = 1
			attrs[.strikethroughColor] = UIColor.tertiaryLabel
		} else {
			attrs[.strikethroughStyle] = 0
		}

		// This is a bit of a hack to make sure that the reused UITextView gets cleared out for the empty attributed string
		if configuration.attributedText.length < 1 {
			let mutableAttrText = NSMutableAttributedString(string: " ")
			let range = NSRange(location: 0, length: mutableAttrText.length)
			attrs[.font] = HeadlineFont.text
			mutableAttrText.addAttributes(attrs, range: range)
			textView.attributedText = mutableAttrText
			textView.attributedText = configuration.attributedText
		} else {
			let mutableAttrText = NSMutableAttributedString(attributedString: configuration.attributedText)
			let range = NSRange(location: 0, length: mutableAttrText.length)
			mutableAttrText.addAttributes(attrs, range: range)
			mutableAttrText.replaceFont(with: HeadlineFont.text)
			textView.attributedText = mutableAttrText
		}

	}
	
	private func configureNoteTextView(configuration: EditorHeadlineContentConfiguration) {
		guard let noteAttributedText = configuration.headline?.noteAttributedText else {
			noteTextView?.removeFromSuperview()
			noteTextView = nil
			return
		}
		
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.foregroundColor] = UIColor.secondaryLabel
		
		let mutableAttrText = NSMutableAttributedString(attributedString: noteAttributedText)
		let range = NSRange(location: 0, length: mutableAttrText.length)
		mutableAttrText.replaceFont(with: HeadlineFont.note)
		mutableAttrText.addAttributes(attrs, range: range)
		
		if noteTextView == nil {
			noteTextView = EditorHeadlineNoteTextView()
			noteTextView!.editorDelegate = self
			noteTextView!.translatesAutoresizingMaskIntoConstraints = false
			addSubview(noteTextView!)
		}
		
		noteTextView!.headline = configuration.headline
		noteTextView!.attributedText = mutableAttrText
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
