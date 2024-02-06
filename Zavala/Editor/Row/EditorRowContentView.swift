//
//  EditorRowContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import VinOutlineKit

class EditorRowContentView: UIView, UIContentView {

	lazy var topicTextView: EditorRowTopicTextView = {
		let textView = EditorRowTopicTextView()
		textView.editorDelegate = self
		textView.translatesAutoresizingMaskIntoConstraints = false
		return textView
	}()
	
	lazy var noteTextView: EditorRowNoteTextView = {
		let textView = EditorRowNoteTextView()
		textView.editorDelegate = self
		textView.translatesAutoresizingMaskIntoConstraints = false
		return textView
	}()

	var configuration: UIContentConfiguration {
		get { appliedConfiguration! }
		set {
			guard let newConfig = newValue as? EditorRowContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}

	private lazy var disclosureIndicator: EditorDisclosureButton = {
		let indicator = EditorDisclosureButton()
		indicator.configure()
		indicator.addTarget(self, action: #selector(toggleDisclosure(_:forEvent:)), for: UIControl.Event.touchUpInside)
		return indicator
	}()
	
	private lazy var bullet: UIView = {
		let bulletView = UIImageView(image: .bullet)
		
		NSLayoutConstraint.activate([
			bulletView.widthAnchor.constraint(equalToConstant: 4),
			bulletView.heightAnchor.constraint(equalToConstant: 4)
		])

		bulletView.tintColor = .accessoryColor
		bulletView.translatesAutoresizingMaskIntoConstraints = false
		
		return bulletView
	}()
	
	private lazy var barView: BarView = {
		let barView = BarView()
		barView.backgroundColor = .clear
		barView.translatesAutoresizingMaskIntoConstraints = false
		return barView
	}()

	private var barViews = [UIView]()
	private var appliedConfiguration: EditorRowContentConfiguration?
	
	init(configuration: EditorRowContentConfiguration) {
		super.init(frame: .zero)
		
		addSubview(topicTextView)
		addSubview(barView)
		
		let barViewWidthConstraint = barView.widthAnchor.constraint(equalToConstant: 1)
		barView.barViewWidthConstraint = barViewWidthConstraint
		
		NSLayoutConstraint.activate([
			barViewWidthConstraint,
			barView.topAnchor.constraint(equalTo: topAnchor),
			barView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
		
		apply(configuration: configuration)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// This prevents the navigation controller backswipe from trigging a row swipe event
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
		defer {
			appliedConfiguration = configuration
		}
		
		if topicTextView.isFirstResponder {
			topicTextView.saveText()
		}

		if noteTextView.isFirstResponder {
			noteTextView.saveText()
		}

		guard let row = configuration.row else { return }

		topicTextView.update(row: row)
		noteTextView.update(row: row)

		switch (configuration.row?.isExpanded ?? true, configuration.isSearching) {
		case (true, _):
			disclosureIndicator.setDisclosure(state: .expanded, animated: false)
		case (false, false):
			disclosureIndicator.setDisclosure(state: .collapsed, animated: false)
		case (false, true):
			disclosureIndicator.setDisclosure(state: .partial, animated: false)
		}

		barView.level = row.currentLevel
		barView.indentationWidth = configuration.indentationWidth
		
		guard appliedConfiguration == nil || !appliedConfiguration!.isLayoutEqual(configuration) else {
			return
		}
		
		configureTextViews(config: configuration)
		configureBulletOrDisclosure(config: configuration)
	}
	
}

// MARK: EditorTextViewDelegate

extension EditorRowContentView: EditorRowTopicTextViewDelegate {
	
	var editorRowTopicTextViewUndoManager: UndoManager? {
		return appliedConfiguration?.delegate?.editorRowUndoManager
	}
	
	var editorRowTopicTextViewInputAccessoryView: UIView? {
		appliedConfiguration?.delegate?.editorRowInputAccessoryView
	}
	
	func layoutEditor(_: EditorRowTopicTextView, row: Row) {
		appliedConfiguration?.delegate?.editorRowLayoutEditor(row: row)
	}
	
	func scrollEditorToVisible(_ textView: EditorRowTopicTextView, rect: CGRect) {
		appliedConfiguration?.delegate?.editorRowScrollEditorToVisible(textView: textView, rect: rect)
	}
	
	func moveCursorUp(_: EditorRowTopicTextView, row: Row) {
		appliedConfiguration?.delegate?.editorRowMoveCursorUp(row: row)
	}
	
	func moveCursorDown(_: EditorRowTopicTextView, row: Row) {
		appliedConfiguration?.delegate?.editorRowMoveCursorDown(row: row)
	}

	func didBecomeActive(_: EditorRowTopicTextView, row: Row) {
		appliedConfiguration?.delegate?.editorRowTextFieldDidBecomeActive(row: row)
	}

	func textChanged(_: EditorRowTopicTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowTextChanged(row: row, rowStrings: rowStrings, isInNotes: isInNotes, selection: selection)
	}
	
	func deleteRow(_: EditorRowTopicTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowDeleteRow(row, rowStrings: rowStrings)
	}
	
	func createRow(_: EditorRowTopicTextView, beforeRow: Row) {
		appliedConfiguration?.delegate?.editorRowCreateRow(beforeRow: beforeRow)
	}
	
	func createRow(_: EditorRowTopicTextView, afterRow: Row, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowCreateRow(afterRow: afterRow, rowStrings: rowStrings)
	}
	
	func moveRowLeft(_: EditorRowTopicTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowMoveRowLeft(row, rowStrings: rowStrings)
	}

	func moveRowRight(_: EditorRowTopicTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowMoveRowRight(row, rowStrings: rowStrings)
	}
	
	func splitRow(_: EditorRowTopicTextView, row: Row, topic: NSAttributedString, cursorPosition: Int) {
		appliedConfiguration?.delegate?.editorRowSplitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func editLink(_: EditorRowTopicTextView, _ link: String?, text: String?, range: NSRange) {
		appliedConfiguration?.delegate?.editorRowEditLink(link, text: text, range: range)
	}
	
	func zoomImage(_ topicRow: EditorRowTopicTextView, _ image: UIImage, rect: CGRect) {
		appliedConfiguration?.delegate?.editorRowZoomImage(image, rect: rect)
	}

}

extension EditorRowContentView: EditorRowNoteTextViewDelegate {

	var editorRowNoteTextViewUndoManager: UndoManager? {
		return appliedConfiguration?.delegate?.editorRowUndoManager
	}
	
	var editorRowNoteTextViewInputAccessoryView: UIView? {
		return appliedConfiguration?.delegate?.editorRowInputAccessoryView
	}
	
	func layoutEditor(_: EditorRowNoteTextView, row: Row) {
		appliedConfiguration?.delegate?.editorRowLayoutEditor(row: row)
	}
	
	func scrollEditorToVisible(_ textView: EditorRowNoteTextView, rect: CGRect) {
		appliedConfiguration?.delegate?.editorRowScrollEditorToVisible(textView: textView, rect: rect)
	}

	func didBecomeActive(_: EditorRowNoteTextView, row: Row) {
		appliedConfiguration?.delegate?.editorRowTextFieldDidBecomeActive(row: row)
	}
	
	func textChanged(_: EditorRowNoteTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowTextChanged(row: row, rowStrings: rowStrings, isInNotes: isInNotes, selection: selection)
	}
	
	func deleteRowNote(_: EditorRowNoteTextView, row: Row, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowDeleteRowNote(row, rowStrings: rowStrings)
	}
	
	func moveCursorTo(_: EditorRowNoteTextView, row: Row) {
		appliedConfiguration?.delegate?.editorRowMoveCursorTo(row: row)
	}
	
	func moveCursorDown(_: EditorRowNoteTextView, row: Row) {
		appliedConfiguration?.delegate?.editorRowMoveCursorDown(row: row)
	}
	
	func editLink(_: EditorRowNoteTextView, _ link: String?, text: String?, range: NSRange) {
		appliedConfiguration?.delegate?.editorRowEditLink(link, text: text, range: range)
	}
	
	func zoomImage(_ noteRow: EditorRowNoteTextView, _ image: UIImage, rect: CGRect) {
		appliedConfiguration?.delegate?.editorRowZoomImage(image, rect: rect)
	}

}

// MARK: Helpers

private extension EditorRowContentView {

	@objc func toggleDisclosure(_ sender: Any?, forEvent event: UIEvent) {
		guard let row = appliedConfiguration?.row else { return }
		disclosureIndicator.toggleDisclosure()
		let applyToAll = event.modifierFlags.contains(.alternate)
		appliedConfiguration?.delegate?.editorRowToggleDisclosure(row: row, applyToAll: applyToAll)
	}
	
	func configureTextViews(config: EditorRowContentConfiguration) {
		let adjustedLeadingIndention: CGFloat
		let adjustedTrailingIndention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			adjustedLeadingIndention = config.indentationWidth + 4
			adjustedTrailingIndention = -8
		} else {
			adjustedLeadingIndention = config.indentationWidth + 6
			adjustedTrailingIndention = -8
		}
		
		let spacingAdjustment: CGFloat
		switch config.rowSpacingSize {
		case .small:
			spacingAdjustment = 6
		case .medium:
			spacingAdjustment = 4
		default:
			spacingAdjustment = 2
		}
		
		topicTextView.removeConstraintsOwnedBySuperview()
		
		if config.isNotesVisible {
			addSubview(noteTextView)
			NSLayoutConstraint.activate([
				topicTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				topicTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				topicTextView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 0 - spacingAdjustment),
				topicTextView.bottomAnchor.constraint(equalTo: noteTextView.topAnchor, constant: spacingAdjustment / 2),
				noteTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				noteTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				noteTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: spacingAdjustment),
				barView.trailingAnchor.constraint(equalTo: topicTextView.leadingAnchor)
			])
		} else {
			noteTextView.removeFromSuperview()
			NSLayoutConstraint.activate([
				topicTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				topicTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				topicTextView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 0 - spacingAdjustment),
				topicTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: spacingAdjustment),
				barView.trailingAnchor.constraint(equalTo: topicTextView.leadingAnchor)
			])
		}
	}
	
	func configureBulletOrDisclosure(config: EditorRowContentConfiguration) {
		let xHeight = "X".height(withConstrainedWidth: Double.infinity, font: topicTextView.font!)
		let topAnchorConstant = (xHeight / 2) + topicTextView.textContainerInset.top

		bullet.removeFromSuperview()
		disclosureIndicator.removeFromSuperview()

		if config.isDisclosureVisible {
			addSubview(disclosureIndicator)

			let indentAdjustment: CGFloat
			if traitCollection.userInterfaceIdiom == .mac {
				switch config.rowIndentSize {
				case .small:
					indentAdjustment = -4
				case .medium:
					indentAdjustment = -7
				default:
					indentAdjustment = -10
				}
			} else {
				switch config.rowIndentSize {
				case .small:
					indentAdjustment = -16
				case .medium:
					indentAdjustment = -19
				default:
					indentAdjustment = -22
				}
			}
			
			NSLayoutConstraint.activate([
				disclosureIndicator.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: config.indentationWidth + indentAdjustment),
				disclosureIndicator.centerYAnchor.constraint(equalTo: topicTextView.topAnchor, constant: topAnchorConstant)
			])
		} else {
			addSubview(bullet)
			
			let indentAdjustment: CGFloat
			if traitCollection.userInterfaceIdiom == .mac {
				switch config.rowIndentSize {
				case .small:
					indentAdjustment = 1
				case .medium:
					indentAdjustment = -2
				default:
					indentAdjustment = -5
				}
			} else {
				switch config.rowIndentSize {
				case .small:
					indentAdjustment = 3
				case .medium:
					indentAdjustment = 0
				default:
					indentAdjustment = -3
				}
			}

			NSLayoutConstraint.activate([
				bullet.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: config.indentationWidth + indentAdjustment),
				bullet.centerYAnchor.constraint(equalTo: topicTextView.topAnchor, constant: topAnchorConstant)
			])
		}
	}
	
	class BarView: UIView {
		
		var barViewWidthConstraint: NSLayoutConstraint?
		
		var level: Int = 0 {
			didSet {
				if level != oldValue {
					setNeedsUpdateConstraints()
					setNeedsDisplay()
				}
			}
		}
		
		var indentationWidth: CGFloat = 0.0 {
			didSet {
				if indentationWidth != oldValue {
					setNeedsUpdateConstraints()
					setNeedsDisplay()
				}
			}
		}
		
		override func updateConstraints() {
			let width = (CGFloat(level + 1) * indentationWidth)
			barViewWidthConstraint?.constant = width
			super.updateConstraints()
		}
		
		override func draw(_ rect: CGRect) {
			for i in 0..<level {
				drawBarView(indentLevel: i)
			}
		}
		
		private func drawBarView(indentLevel: Int) {
			let x = (CGFloat(indentLevel) * indentationWidth)
			let bar = CGRect(x: x, y: 0, width: 2, height: bounds.size.height)
			
			UIColor.verticalBarColor.setFill()
			let context = UIGraphicsGetCurrentContext();
			context?.addRect(bar)
			context?.fill(bar)
		}
		
	}
	
}
