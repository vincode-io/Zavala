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
		
		if topicTextView.isFirstResponder {
			topicTextView.saveText()
		}

		if noteTextView?.isFirstResponder ?? false {
			noteTextView?.saveText()
		}

		let coordinates = CursorCoordinates.currentCoordinates
		
		configureTopicTextView(configuration: configuration)
		configureNoteTextView(configuration: configuration)
		
		if let coordinates = coordinates, coordinates.row == configuration.row {
			if !coordinates.isInNotes {
				topicTextView.selectedRange = coordinates.selection
			} else {
				noteTextView?.selectedRange = coordinates.selection
			}
		}

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
		
		let topAnchorConstant = topicTextView.font!.capHeight *  0.9

		if configuration.row?.rowCount == 0 {
			addSubview(bullet)
			
			if traitCollection.horizontalSizeClass != .compact {
				let indentAdjustment: CGFloat = traitCollection.userInterfaceIdiom == .mac ? 1 : 3
				NSLayoutConstraint.activate([
					bullet.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: configuration.indentationWidth + indentAdjustment),
					bullet.centerYAnchor.constraint(equalTo: topicTextView.topAnchor, constant: topAnchorConstant)
				])
			} else {
				NSLayoutConstraint.activate([
					bullet.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
					bullet.centerYAnchor.constraint(equalTo: topicTextView.topAnchor, constant: topAnchorConstant)
				])
			}
		} else {
			addSubview(disclosureIndicator)

			if traitCollection.horizontalSizeClass != .compact {
				let indentAdjustment: CGFloat = traitCollection.userInterfaceIdiom == .mac ? -6 : -16
				NSLayoutConstraint.activate([
					disclosureIndicator.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: configuration.indentationWidth + indentAdjustment),
					disclosureIndicator.centerYAnchor.constraint(equalTo: topicTextView.topAnchor, constant: topAnchorConstant)
				])
			} else {
				NSLayoutConstraint.activate([
					disclosureIndicator.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0),
					disclosureIndicator.centerYAnchor.constraint(equalTo: topicTextView.topAnchor, constant: topAnchorConstant)
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
	
	var editorRowTopicTextViewInputAccessoryView: UIView? {
		appliedConfiguration.delegate?.editorTextRowInputAccessoryView
	}
	
	func invalidateLayout(_: EditorTextRowTopicTextView) {
		invalidateIntrinsicContentSize()
		appliedConfiguration.delegate?.editorTextRowReloadCurrentCell()
	}
	
	func makeCursorVisibleIfNecessary(_: EditorTextRowTopicTextView) {
		appliedConfiguration.delegate?.editorTextRowMakeCursorVisibleIfNecessary()
	}
	
	func didBecomeActive(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowTextFieldDidBecomeActive(row: row)
	}

	func textChanged(_: EditorTextRowTopicTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorTextRowTextChanged(row: row, rowStrings: rowStrings, isInNotes: isInNotes, selection: selection)
	}
	
	func deleteRow(_: EditorTextRowTopicTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorTextRowDeleteRow(row, rowStrings: rowStrings)
	}
	
	func createRow(_: EditorTextRowTopicTextView, beforeRow: Row) {
		appliedConfiguration.delegate?.editorTextRowCreateRow(beforeRow: beforeRow)
	}
	
	func createRow(_: EditorTextRowTopicTextView, afterRow: Row, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorTextRowCreateRow(afterRow: afterRow, rowStrings: rowStrings)
	}
	
	func moveRowLeft(_: EditorTextRowTopicTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorTextRowMoveRowLeft(row, rowStrings: rowStrings)
	}

	func moveRowRight(_: EditorTextRowTopicTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorTextRowMoveRowRight(row, rowStrings: rowStrings)
	}
	
	func splitRow(_: EditorTextRowTopicTextView, row: Row, topic: NSAttributedString, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorTextRowSplitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func editLink(_: EditorTextRowTopicTextView, _ link: String?, text: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorTextRowEditLink(link, text: text, range: range)
	}
	
}

extension EditorTextRowContentView: EditorTextRowNoteTextViewDelegate {

	var editorRowNoteTextViewUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorTextRowUndoManager
	}
	
	var editorRowNoteTextViewInputAccessoryView: UIView? {
		return appliedConfiguration.delegate?.editorTextRowInputAccessoryView
	}
	
	func invalidateLayout(_: EditorTextRowNoteTextView) {
		invalidateIntrinsicContentSize()
		appliedConfiguration.delegate?.editorTextRowReloadCurrentCell()
	}
	
	func makeCursorVisibleIfNecessary(_: EditorTextRowNoteTextView) {
		appliedConfiguration.delegate?.editorTextRowMakeCursorVisibleIfNecessary()
	}

	func didBecomeActive(_: EditorTextRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowTextFieldDidBecomeActive(row: row)
	}
	
	func textChanged(_: EditorTextRowNoteTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorTextRowTextChanged(row: row, rowStrings: rowStrings, isInNotes: isInNotes, selection: selection)
	}
	
	func deleteRowNote(_: EditorTextRowNoteTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorTextRowDeleteRowNote(row, rowStrings: rowStrings)
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
	
	private func configureTopicTextView(configuration: EditorTextRowContentConfiguration) {
		guard let row = configuration.row else { return }
		topicTextView.update(row: row, indentionLevel: configuration.indentionLevel)

	}
	
	private func configureNoteTextView(configuration: EditorTextRowContentConfiguration) {
		guard !configuration.isNotesHidden, let row = configuration.row, row.note != nil else {
			noteTextView?.removeFromSuperview()
			noteTextView = nil
			return
		}
		
		if noteTextView == nil {
			noteTextView = EditorTextRowNoteTextView()
			noteTextView!.editorDelegate = self
			noteTextView!.translatesAutoresizingMaskIntoConstraints = false
			addSubview(noteTextView!)
		}
		
		noteTextView!.update(row: row, indentionLevel: configuration.indentionLevel)
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
