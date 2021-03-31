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
	var barViews = [UIView]()

	private lazy var disclosureIndicator: EditorDisclosureButton = {
		let indicator = EditorDisclosureButton()
		indicator.addTarget(self, action: #selector(toggleDisclosure(_:)), for: UIControl.Event.touchUpInside)
		return indicator
	}()
	
	private lazy var bullet: UIView = {
		let bulletView = UIImageView(image: AppAssets.bullet)
		
		NSLayoutConstraint.activate([
			bulletView.widthAnchor.constraint(equalToConstant: 4),
			bulletView.heightAnchor.constraint(equalToConstant: 4)
		])

		bulletView.tintColor = AppAssets.accessory
		bulletView.translatesAutoresizingMaskIntoConstraints = false
		
		return bulletView
	}()
	
	var appliedConfiguration: EditorTextRowContentConfiguration!
	
	var textRowStrings: TextRowStrings {
		return TextRowStrings(topic: topicTextView.cleansedAttributedText, note: noteTextView?.cleansedAttributedText)
	}
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorTextRowContentConfiguration else { return }
			apply(configuration: newConfig)
		}
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
	
	// This prevents the navigation controller backswipe from trigging a row indent
	override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer is UISwipeGestureRecognizer {
			let location = gestureRecognizer.location(in: self)
			if location.x < self.frame.maxX * 0.05 || location.x > self.frame.maxX * 0.95 {
				return false
			}
		}
		return super.gestureRecognizerShouldBegin(gestureRecognizer)
	}
	
	private func apply(configuration: EditorTextRowContentConfiguration) {
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration

		configureTopicTextView(configuration: configuration)
		configureNoteTextView(configuration: configuration)

		let adjustedLeadingIndention: CGFloat
		let adjustedTrailingIndention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			adjustedLeadingIndention = configuration.indentationWidth + 8
			adjustedTrailingIndention = -8
		} else {
			if traitCollection.horizontalSizeClass != .compact {
				adjustedLeadingIndention = configuration.indentationWidth + 12
				adjustedTrailingIndention = -8
			} else {
				adjustedLeadingIndention = configuration.indentationWidth
				adjustedTrailingIndention = -25
			}
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

		bullet.removeFromSuperview()
		disclosureIndicator.removeFromSuperview()
		
		let topicCapHeight = configuration.topicFont.capHeight
		
		if configuration.row?.rowCount == 0 {
			addSubview(bullet)
			
			let baseLineConstant = 0 - (topicCapHeight - 4) / 2
			if traitCollection.horizontalSizeClass != .compact {
				let indentAdjustment: CGFloat = traitCollection.userInterfaceIdiom == .mac ? 1 : 3
				NSLayoutConstraint.activate([
					bullet.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: configuration.indentationWidth + indentAdjustment),
					bullet.firstBaselineAnchor.constraint(equalTo: topicTextView.firstBaselineAnchor, constant: baseLineConstant)
				])
			} else {
				NSLayoutConstraint.activate([
					bullet.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
					bullet.firstBaselineAnchor.constraint(equalTo: topicTextView.firstBaselineAnchor, constant: baseLineConstant)
				])
			}
		} else {
			addSubview(disclosureIndicator)

			let baseLineConstant: CGFloat
			if traitCollection.userInterfaceIdiom == .mac {
				baseLineConstant = 0 - (topicCapHeight - 8) / 2
			} else {
				baseLineConstant = 0 - (topicCapHeight - 12) / 2
			}

			if traitCollection.horizontalSizeClass != .compact {
				let indentAdjustment: CGFloat = traitCollection.userInterfaceIdiom == .mac ? -6 : -16
				NSLayoutConstraint.activate([
					disclosureIndicator.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: configuration.indentationWidth + indentAdjustment),
					disclosureIndicator.firstBaselineAnchor.constraint(equalTo: topicTextView.firstBaselineAnchor, constant: baseLineConstant)
				])
			} else {
				NSLayoutConstraint.activate([
					disclosureIndicator.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0),
					disclosureIndicator.firstBaselineAnchor.constraint(equalTo: topicTextView.firstBaselineAnchor, constant: baseLineConstant)
				])
			}
			
			switch (configuration.row?.isExpanded ?? true, configuration.isSearching) {
			case (true, _):
				disclosureIndicator.setDisclosure(state: .expanded, animated: false)
			case (false, false):
				disclosureIndicator.setDisclosure(state: .collapsed, animated: false)
			case (false, true):
				disclosureIndicator.setDisclosure(state: .partial, animated: false)
			}
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
	
	func didBecomeActive(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowTextFieldDidBecomeActive(row: row)
	}

	func didBecomeInactive(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowTextFieldDidBecomeInactive(row: row)
	}

	func textChanged(_: EditorTextRowTopicTextView, row: Row, isInNotes: Bool, selection: NSRange) {
		appliedConfiguration.delegate?.editorTextRowTextChanged(row: row, textRowStrings: textRowStrings, isInNotes: isInNotes, selection: selection)
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
	
	func editLink(_: EditorTextRowTopicTextView, _ link: String?, text: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorTextRowEditLink(link, text: text, range: range)
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
	
	func didBecomeActive(_: EditorTextRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowTextFieldDidBecomeActive(row: row)
	}
	
	func didBecomeInactive(_: EditorTextRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowTextFieldDidBecomeInactive(row: row)
	}
	
	func textChanged(_: EditorTextRowNoteTextView, row: Row, isInNotes: Bool, selection: NSRange) {
		appliedConfiguration.delegate?.editorTextRowTextChanged(row: row, textRowStrings: textRowStrings, isInNotes: isInNotes, selection: selection)
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
	
	func editLink(_: EditorTextRowNoteTextView, _ link: String?, text: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorTextRowEditLink(link, text: text, range: range)
	}
	
}

// MARK: Helpers

extension EditorTextRowContentView {

	@objc func toggleDisclosure(_ sender: Any?) {
		guard let row = appliedConfiguration.row else { return }
		disclosureIndicator.toggleDisclosure()
		appliedConfiguration.delegate?.editorTextRowToggleDisclosure(row: row)
	}
	
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
		topicTextView.indentionLevel = configuration.indentionLevel
		
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

		if let topic = configuration.topic {
			let mutableAttrText = NSMutableAttributedString(attributedString: topic)
			let range = NSRange(location: 0, length: mutableAttrText.length)
			mutableAttrText.addAttributes(attrs, range: range)
			mutableAttrText.replaceFont(with: configuration.topicFont)
			addHighlighting(mutableAttrText, searchResultCoordinates: configuration.row?.textRow?.searchResultCoordinates, isInNotes: false)
			topicTextView.attributedText = mutableAttrText
		} else {
			// This is a bit of a hack to make sure that the reused UITextView gets cleared out for the
			// empty attributed string and the bullet correctly aligns on the first baseline
			let mutableAttrText = NSMutableAttributedString(string: " ")
			let range = NSRange(location: 0, length: mutableAttrText.length)
			attrs[.font] = configuration.topicFont
			mutableAttrText.addAttributes(attrs, range: range)
			topicTextView.attributedText = mutableAttrText
		}

	}
	
	private func configureNoteTextView(configuration: EditorTextRowContentConfiguration) {
		guard !configuration.isNotesHidden, let noteAttributedText = configuration.row?.textRow?.note else {
			noteTextView?.removeFromSuperview()
			noteTextView = nil
			return
		}
		
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.foregroundColor] = UIColor.secondaryLabel
		
		let mutableAttrText = NSMutableAttributedString(attributedString: noteAttributedText)
		let range = NSRange(location: 0, length: mutableAttrText.length)
		mutableAttrText.replaceFont(with: configuration.noteFont)
		mutableAttrText.addAttributes(attrs, range: range)
		addHighlighting(mutableAttrText, searchResultCoordinates: configuration.row?.textRow?.searchResultCoordinates, isInNotes: true)

		if noteTextView == nil {
			noteTextView = EditorTextRowNoteTextView()
			noteTextView!.editorDelegate = self
			noteTextView!.translatesAutoresizingMaskIntoConstraints = false
			addSubview(noteTextView!)
		}
		
		noteTextView!.row = configuration.row
		noteTextView!.indentionLevel = configuration.indentionLevel
		noteTextView!.attributedText = mutableAttrText
	}
	
	private func addHighlighting(_ mutableAttrText: NSMutableAttributedString, searchResultCoordinates: NSHashTable<SearchResultCoordinates>?, isInNotes: Bool) {
		guard let coordinates = searchResultCoordinates else { return }
		for element in coordinates.objectEnumerator() {
			guard let coordinate = element as? SearchResultCoordinates, coordinate.isInNotes == isInNotes else { continue }
			if coordinate.isCurrentResult {
				mutableAttrText.addAttribute(.backgroundColor, value: UIColor.systemYellow, range: coordinate.range)
				if traitCollection.userInterfaceStyle == .dark {
					mutableAttrText.addAttribute(.foregroundColor, value: UIColor.black, range: coordinate.range)
				}
			} else {
				mutableAttrText.addAttribute(.backgroundColor, value: UIColor.systemGray, range: coordinate.range)
			}
		}
	}
	
	private func addBarViews() {
		let configuration = appliedConfiguration as EditorTextRowContentConfiguration
		
		if configuration.indentionLevel > 0 {
			let barViewsCount = barViews.count
			for i in (1...configuration.indentionLevel) {
				if i > barViewsCount {
					addBarView(indentLevel: i, indentWidth: configuration.indentationWidth, hasChevron: configuration.isChevronShowing)
				}
			}
		}
	}
	
	private func addBarView(indentLevel: Int, indentWidth: CGFloat, hasChevron: Bool) {
		let barView = UIView()
		barView.backgroundColor = AppAssets.verticalBar
		barView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(barView)
		barViews.append(barView)

		var indention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			indention = CGFloat(28 - ((indentLevel + 1) * 13))
		} else {
			if traitCollection.horizontalSizeClass != .compact {
				indention = CGFloat(30 - ((indentLevel + 1) * 13))
			} else {
				indention = CGFloat(19 - (indentLevel * 10))
			}
		}

		NSLayoutConstraint.activate([
			barView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: indention),
			barView.widthAnchor.constraint(equalToConstant: 2),
			barView.topAnchor.constraint(equalTo: topAnchor),
			barView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
	}
	
}
