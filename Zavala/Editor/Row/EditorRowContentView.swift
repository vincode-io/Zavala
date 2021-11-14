//
//  EditorRowContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

class EditorRowContentView: UIView, UIContentView {

    var topicTextView: EditorRowTopicTextView?
	var noteTextView: EditorRowNoteTextView?
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
	
	var appliedConfiguration: EditorRowContentConfiguration!
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorRowContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	init(configuration: EditorRowContentConfiguration) {
		super.init(frame: .zero)
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
	
	private func apply(configuration: EditorRowContentConfiguration) {
		appliedConfiguration = configuration
		
		if topicTextView?.isFirstResponder ?? false {
			topicTextView?.saveText()
		}

		if noteTextView?.isFirstResponder ?? false {
			noteTextView?.saveText()
		}

        // Save the coordinates so that we can restore them immediately after rebuilding the text views.
		let coordinates = CursorCoordinates.currentCoordinates
		
		configureTopicTextView(configuration: configuration)
		configureNoteTextView(configuration: configuration)
		
        guard let topicTextView = topicTextView else { return }
        
		if let coordinates = coordinates, coordinates.row == configuration.row {
			if !coordinates.isInNotes {
				topicTextView.becomeFirstResponder()
				topicTextView.selectedRange = coordinates.selection
			} else {
				noteTextView?.becomeFirstResponder()
				noteTextView?.selectedRange = coordinates.selection
			}
		}

		let adjustedLeadingIndention: CGFloat
		let adjustedTrailingIndention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			adjustedLeadingIndention = configuration.indentationWidth + 4
			adjustedTrailingIndention = -8
		} else {
			if traitCollection.horizontalSizeClass != .compact {
				adjustedLeadingIndention = configuration.indentationWidth + 6
				adjustedTrailingIndention = -8
			} else {
				adjustedLeadingIndention = 0
				adjustedTrailingIndention = -25
			}
		}

		if let noteTextView = noteTextView {
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
		
		let xHeight = "X".height(withConstrainedWidth: Double.infinity, font: topicTextView.font!)
		let topAnchorConstant = (xHeight / 2) + topicTextView.textContainerInset.top

		if configuration.row?.rowCount == 0 {
			addSubview(bullet)
			
			if traitCollection.horizontalSizeClass != .compact {
				let indentAdjustment: CGFloat = traitCollection.userInterfaceIdiom == .mac ? -4 : -2
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
				let indentAdjustment: CGFloat = traitCollection.userInterfaceIdiom == .mac ? -12 : -22
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

		addBarViews()
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
			addBarViews()
		}
	}
	
}

// MARK: EditorTextViewDelegate

extension EditorRowContentView: EditorRowTopicTextViewDelegate {
	
	var editorRowTopicTextViewUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorRowUndoManager
	}
	
	var editorRowTopicTextViewInputAccessoryView: UIView? {
		appliedConfiguration.delegate?.editorRowInputAccessoryView
	}
	
	func reload(_: EditorRowTopicTextView, row: Row) {
		invalidateIntrinsicContentSize()
		appliedConfiguration.delegate?.editorRowReload(row: row)
	}
	
	func makeCursorVisibleIfNecessary(_: EditorRowTopicTextView) {
		appliedConfiguration.delegate?.editorRowMakeCursorVisibleIfNecessary()
	}
	
	func moveCursorUp(_: EditorRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorRowMoveCursorUp(row: row)
	}
	
	func moveCursorDown(_: EditorRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorRowMoveCursorDown(row: row)
	}

	func didBecomeActive(_: EditorRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorRowTextFieldDidBecomeActive(row: row)
	}

	func textChanged(_: EditorRowTopicTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorRowTextChanged(row: row, rowStrings: rowStrings, isInNotes: isInNotes, selection: selection)
	}
	
	func deleteRow(_: EditorRowTopicTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorRowDeleteRow(row, rowStrings: rowStrings)
	}
	
	func createRow(_: EditorRowTopicTextView, beforeRow: Row) {
		appliedConfiguration.delegate?.editorRowCreateRow(beforeRow: beforeRow)
	}
	
	func createRow(_: EditorRowTopicTextView, afterRow: Row, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorRowCreateRow(afterRow: afterRow, rowStrings: rowStrings)
	}
	
	func moveRowLeft(_: EditorRowTopicTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorRowMoveRowLeft(row, rowStrings: rowStrings)
	}

	func moveRowRight(_: EditorRowTopicTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorRowMoveRowRight(row, rowStrings: rowStrings)
	}
	
	func splitRow(_: EditorRowTopicTextView, row: Row, topic: NSAttributedString, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorRowSplitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func editLink(_: EditorRowTopicTextView, _ link: String?, text: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorRowEditLink(link, text: text, range: range)
	}
	
	func zoomImage(_ topicRow: EditorRowTopicTextView, _ image: UIImage, rect: CGRect) {
		appliedConfiguration.delegate?.editorRowZoomImage(image, rect: rect)
	}

}

extension EditorRowContentView: EditorRowNoteTextViewDelegate {

	var editorRowNoteTextViewUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorRowUndoManager
	}
	
	var editorRowNoteTextViewInputAccessoryView: UIView? {
		return appliedConfiguration.delegate?.editorRowInputAccessoryView
	}
	
    func reload(_: EditorRowNoteTextView, row: Row) {
		invalidateIntrinsicContentSize()
        appliedConfiguration.delegate?.editorRowReload(row: row)
	}
	
	func makeCursorVisibleIfNecessary(_: EditorRowNoteTextView) {
		appliedConfiguration.delegate?.editorRowMakeCursorVisibleIfNecessary()
	}

	func didBecomeActive(_: EditorRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorRowTextFieldDidBecomeActive(row: row)
	}
	
	func textChanged(_: EditorRowNoteTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorRowTextChanged(row: row, rowStrings: rowStrings, isInNotes: isInNotes, selection: selection)
	}
	
	func deleteRowNote(_: EditorRowNoteTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration.delegate?.editorRowDeleteRowNote(row, rowStrings: rowStrings)
	}
	
	func moveCursorTo(_: EditorRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorRowMoveCursorTo(row: row)
	}
	
	func moveCursorDown(_: EditorRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorRowMoveCursorDown(row: row)
	}
	
	func editLink(_: EditorRowNoteTextView, _ link: String?, text: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorRowEditLink(link, text: text, range: range)
	}
	
	func zoomImage(_ noteRow: EditorRowNoteTextView, _ image: UIImage, rect: CGRect) {
		appliedConfiguration.delegate?.editorRowZoomImage(image, rect: rect)
	}

}

// MARK: Helpers

extension EditorRowContentView {

	@objc func toggleDisclosure(_ sender: Any?) {
		guard let row = appliedConfiguration.row else { return }
		disclosureIndicator.toggleDisclosure()
		appliedConfiguration.delegate?.editorRowToggleDisclosure(row: row)
	}
	
	private func configureTopicTextView(configuration: EditorRowContentConfiguration) {
        topicTextView?.removeFromSuperview()
        
		guard let row = configuration.row else { return }
        
        topicTextView = EditorRowTopicTextView()
        topicTextView!.editorDelegate = self
        topicTextView!.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topicTextView!)

		topicTextView!.update(row: row)
	}
	
	private func configureNoteTextView(configuration: EditorRowContentConfiguration) {
        noteTextView?.removeFromSuperview()
        noteTextView = nil

        guard !configuration.isNotesHidden, let row = configuration.row, row.note != nil else {
			return
		}
		
        noteTextView = EditorRowNoteTextView()
        noteTextView!.editorDelegate = self
        noteTextView!.translatesAutoresizingMaskIntoConstraints = false
        addSubview(noteTextView!)
		
		noteTextView!.update(row: row)
	}
	
	private func addBarViews() {
		guard let row = appliedConfiguration.row else { return }
		
		for i in 0..<barViews.count {
			barViews[i].removeFromSuperview()
		}
		barViews.removeAll()

		if row.level > 0 {
			let barViewsCount = barViews.count
			for i in (1...row.level) {
				if i > barViewsCount {
					addBarView(indentLevel: i)
				}
			}
		}
	}
	
	private func addBarView(indentLevel: Int) {
		let config = appliedConfiguration as EditorRowContentConfiguration
		
		let barView = UIView()
		barView.backgroundColor = AppAssets.verticalBar
		barView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(barView)
		barViews.append(barView)

		var indention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			indention = CGFloat(28 - (CGFloat(indentLevel + 1) * config.indentationWidth))
		} else {
			if traitCollection.horizontalSizeClass != .compact {
				indention = CGFloat(30 - (CGFloat(indentLevel + 1) * config.indentationWidth))
			} else {
				indention = CGFloat(9 - (CGFloat(indentLevel) * config.indentationWidth))
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
