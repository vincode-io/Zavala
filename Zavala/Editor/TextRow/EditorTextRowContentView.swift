//
//  EditorTextRowContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

class EditorTextRowContentView: UIView, UIContentView {

	let topicTextView = EditorTextRowTopicTextView()
	var noteTextView: EditorTextRowNoteTextView?
	var bulletView: UIImageView?
	var barViews = [UIView]()
	
	var appliedConfiguration: EditorTextRowContentConfiguration!
	
	var textRowStrings: TextRowStrings {
		return TextRowStrings(topic: topicTextView.attributedText, note: noteTextView?.attributedText)
	}
	
	init(configuration: EditorTextRowContentConfiguration) {
		super.init(frame: .zero)

		topicTextView.editorDelegate = self
		topicTextView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(topicTextView)

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
			guard let newConfig = newValue as? EditorTextRowContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorTextRowContentConfiguration) {
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration

		configureTopicTextView(configuration: configuration)
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

		topicTextView.removeConstraintsOwnedBySuperview()
		
		if let noteTextView = noteTextView {
			noteTextView.removeConstraintsOwnedBySuperview()
			NSLayoutConstraint.activate([
				topicTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				topicTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				topicTextView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
				topicTextView.bottomAnchor.constraint(equalTo: noteTextView.topAnchor, constant: -4),
				noteTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				noteTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				noteTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)

			])
		} else {
			NSLayoutConstraint.activate([
				topicTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				topicTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				topicTextView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
				topicTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
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

extension EditorTextRowContentView: EditorTextRowTopicTextViewDelegate {
	
	var editorRowTopicTextViewUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorTextRowUndoManager
	}
	
	var editorRowTopicTextViewTextRowStrings: TextRowStrings {
		return textRowStrings
	}
	
	func invalidateLayout(_: EditorTextRowTopicTextView) {
		invalidateIntrinsicContentSize()
		appliedConfiguration.delegate?.editorTextRowLayoutEditor()
	}
	
	func textChanged(_: EditorTextRowTopicTextView, row: Row, isInNotes: Bool, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorTextRowTextChanged(row: row, textRowStrings: textRowStrings, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func deleteRow(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowDeleteRow(row, textRowStrings: textRowStrings)
	}
	
	func createRow(_: EditorTextRowTopicTextView, beforeRow: Row) {
		appliedConfiguration.delegate?.editorTextRowCreateRow(beforeRow: beforeRow)
	}
	
	func createRow(_: EditorTextRowTopicTextView, afterRow: Row) {
		appliedConfiguration.delegate?.editorTextRowCreateRow(afterRow: afterRow, textRowStrings: textRowStrings)
	}
	
	func indentRow(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowIndentRow(row, textRowStrings: textRowStrings)
	}
	
	func outdentRow(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowOutdentRow(row, textRowStrings: textRowStrings)
	}
	
	func splitRow(_: EditorTextRowTopicTextView, row: Row, topic: NSAttributedString, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorTextRowSplitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func createRowNote(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowCreateRowNote(row, textRowStrings: textRowStrings)
	}
	
	func editLink(_: EditorTextRowTopicTextView, _ link: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorTextRowEditLink(link, range: range)
	}
	
}

extension EditorTextRowContentView: EditorTextRowNoteTextViewDelegate {

	var editorRowNoteTextViewUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorTextRowUndoManager
	}
	
	var editorRowNoteTextViewTextRowStrings: TextRowStrings {
		return textRowStrings
	}
	
	func invalidateLayout(_: EditorTextRowNoteTextView) {
		invalidateIntrinsicContentSize()
		appliedConfiguration.delegate?.editorTextRowLayoutEditor()
	}
	
	func textChanged(_: EditorTextRowNoteTextView, row: Row, isInNotes: Bool, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorTextRowTextChanged(row: row, textRowStrings: textRowStrings, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func deleteRowNote(_: EditorTextRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowDeleteRowNote(row, textRowStrings: textRowStrings)
	}
	
	func moveCursorTo(_: EditorTextRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowMoveCursorTo(row: row)
	}
	
	func moveCursorDown(_: EditorTextRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowMoveCursorDown(row: row)
	}
	
	func editLink(_: EditorTextRowNoteTextView, _ link: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorTextRowEditLink(link, range: range)
	}
	
}

// MARK: Helpers

extension EditorTextRowContentView {
	
	@objc func swipedLeft(_ sender: UISwipeGestureRecognizer) {
		guard let row = appliedConfiguration.row else { return }
		appliedConfiguration.delegate?.editorTextRowOutdentRow(row, textRowStrings: textRowStrings)
	}
	
	@objc func swipedRight(_ sender: UISwipeGestureRecognizer) {
		guard let row = appliedConfiguration.row else { return }
		appliedConfiguration.delegate?.editorTextRowIndentRow(row, textRowStrings: textRowStrings)
	}
	
	private func configureTopicTextView(configuration: EditorTextRowContentConfiguration) {
		topicTextView.row = configuration.row
		
		let topic = configuration.topic ?? NSAttributedString(string: "")
		
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
		if topic.length < 1 {
			let mutableAttrText = NSMutableAttributedString(string: " ")
			let range = NSRange(location: 0, length: mutableAttrText.length)
			attrs[.font] = OutlineFont.topic
			mutableAttrText.addAttributes(attrs, range: range)
			topicTextView.attributedText = mutableAttrText
			topicTextView.attributedText = configuration.topic
		} else {
			let mutableAttrText = NSMutableAttributedString(attributedString: topic)
			let range = NSRange(location: 0, length: mutableAttrText.length)
			mutableAttrText.addAttributes(attrs, range: range)
			mutableAttrText.replaceFont(with: OutlineFont.topic)
			topicTextView.attributedText = mutableAttrText
		}

	}
	
	private func configureNoteTextView(configuration: EditorTextRowContentConfiguration) {
		guard let noteAttributedText = configuration.row?.textRow?.note else {
			noteTextView?.removeFromSuperview()
			noteTextView = nil
			return
		}
		
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.foregroundColor] = UIColor.secondaryLabel
		
		let mutableAttrText = NSMutableAttributedString(attributedString: noteAttributedText)
		let range = NSRange(location: 0, length: mutableAttrText.length)
		mutableAttrText.replaceFont(with: OutlineFont.note)
		mutableAttrText.addAttributes(attrs, range: range)
		
		if noteTextView == nil {
			noteTextView = EditorTextRowNoteTextView()
			noteTextView!.editorDelegate = self
			noteTextView!.translatesAutoresizingMaskIntoConstraints = false
			addSubview(noteTextView!)
		}
		
		noteTextView!.row = configuration.row
		noteTextView!.attributedText = mutableAttrText
	}
	
	private func addBarViews() {
		let configuration = appliedConfiguration as EditorTextRowContentConfiguration
		
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
