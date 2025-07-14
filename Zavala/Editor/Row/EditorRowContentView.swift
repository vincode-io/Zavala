//
//  EditorRowContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import VinOutlineKit

class EditorRowContentView: UIView, UIContentView {

	lazy var numberingLabel: EditorRowNumberingLabel = {
		let label = EditorRowNumberingLabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()
	
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
		guard appliedConfiguration != configuration else { return }
		
		defer {
			appliedConfiguration = configuration
		}
		
		if topicTextView.isFirstResponder {
			topicTextView.saveText()
		}

		if noteTextView.isFirstResponder {
			noteTextView.saveText()
		}

		if let numberingStyle = configuration.outlineNumberingStyle, numberingStyle != Outline.NumberingStyle.none {
			numberingLabel.update(configuration: configuration)
		}
		
		topicTextView.update(configuration: configuration)
		noteTextView.update(configuration: configuration)

		switch (configuration.rowIsExpanded, configuration.isSearching) {
		case (true, _):
			disclosureIndicator.setDisclosure(state: .expanded, animated: false)
		case (false, false):
			disclosureIndicator.setDisclosure(state: .collapsed, animated: false)
		case (false, true):
			disclosureIndicator.setDisclosure(state: .partial, animated: false)
		}

		barView.level = configuration.rowCurrentLevel
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
	
	func resize(_: EditorRowTopicTextView) {
		resize()
	}
	
	func scrollIfNecessary(_: EditorRowTopicTextView) {
		appliedConfiguration?.delegate?.editorRowScrollIfNecessary()
	}
	
	func scrollEditorToVisible(_ textView: EditorRowTopicTextView, rect: CGRect) {
		appliedConfiguration?.delegate?.editorRowScrollEditorToVisible(textView: textView, rect: rect)
	}
	
	func moveCursorUp(_: EditorRowTopicTextView, rowID: String) {
		appliedConfiguration?.delegate?.editorRowMoveCursorUp(rowID: rowID)
	}
	
	func moveCursorDown(_: EditorRowTopicTextView, rowID: String) {
		appliedConfiguration?.delegate?.editorRowMoveCursorDown(rowID: rowID)
	}

	func moveRowLeft(_: EditorRowTopicTextView, rowID: String) {
		appliedConfiguration?.delegate?.editorRowMoveRowLeft(rowID: rowID)
	}

	func moveRowRight(_: EditorRowTopicTextView, rowID: String) {
		appliedConfiguration?.delegate?.editorRowMoveRowRight(rowID: rowID)
	}

	func didBecomeActive(_: EditorRowTopicTextView) {
		appliedConfiguration?.delegate?.editorRowTextFieldDidBecomeActive()
	}

	func didBecomeInactive(_: EditorRowTopicTextView) {
		appliedConfiguration?.delegate?.editorRowTextFieldDidBecomeInactive()
	}

	func textChanged(_: EditorRowTopicTextView, rowID: String, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowTextChanged(rowID: rowID, rowStrings: rowStrings, isInNotes: isInNotes, selection: selection)
	}
	
	func deleteRow(_: EditorRowTopicTextView, rowID: String, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowDeleteRow(rowID: rowID, rowStrings: rowStrings)
	}
	
	func createRow(_: EditorRowTopicTextView, beforeRowID: String, rowStrings: RowStrings, moveCursor: Bool) {
		appliedConfiguration?.delegate?.editorRowCreateRow(beforeRowID: beforeRowID, rowStrings: rowStrings, moveCursor: moveCursor)
	}
	
	func createRow(_: EditorRowTopicTextView, afterRowID: String, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowCreateRow(afterRowID: afterRowID, rowStrings: rowStrings)
	}
	
	func splitRow(_: EditorRowTopicTextView, rowID: String, topic: NSAttributedString, cursorPosition: Int) {
		appliedConfiguration?.delegate?.editorRowSplitRow(rowID: rowID, topic: topic, cursorPosition: cursorPosition)
	}
	
	func joinRowWithPreviousSibling(_: EditorRowTopicTextView, rowID: String, attrText: NSAttributedString) {
		appliedConfiguration?.delegate?.editorRowJoinRowWithPreviousSibling(rowID: rowID, attrText: attrText)
	}
	
	func shouldMoveLeftOnReturn(_: EditorRowTopicTextView, rowID: String) -> Bool {
		return appliedConfiguration?.delegate?.editorRowShouldMoveLeftOnReturn(rowID: rowID) ?? false
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
	
	func resize(_: EditorRowNoteTextView) {
		resize()
	}
	
	func scrollIfNecessary(_: EditorRowNoteTextView) {
		appliedConfiguration?.delegate?.editorRowScrollIfNecessary()
	}

	func scrollEditorToVisible(_ textView: EditorRowNoteTextView, rect: CGRect) {
		appliedConfiguration?.delegate?.editorRowScrollEditorToVisible(textView: textView, rect: rect)
	}

	func didBecomeActive(_: EditorRowNoteTextView) {
		appliedConfiguration?.delegate?.editorRowTextFieldDidBecomeActive()
	}
	
	func didBecomeInactive(_: EditorRowNoteTextView) {
		appliedConfiguration?.delegate?.editorRowTextFieldDidBecomeInactive()
	}
	
	func textChanged(_: EditorRowNoteTextView, rowID: String, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings) {
		appliedConfiguration?.delegate?.editorRowTextChanged(rowID: rowID, rowStrings: rowStrings, isInNotes: isInNotes, selection: selection)
	}
	
	func deleteRowNote(_: EditorRowNoteTextView, rowID: String) {
		appliedConfiguration?.delegate?.editorRowDeleteRowNote(rowID: rowID)
	}
	
	func moveCursorTo(_: EditorRowNoteTextView, rowID: String) {
		appliedConfiguration?.delegate?.editorRowMoveCursorTo(rowID: rowID)
	}
	
	func moveCursorDown(_: EditorRowNoteTextView, rowID: String) {
		appliedConfiguration?.delegate?.editorRowMoveCursorDown(rowID: rowID)
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
		guard let rowID = appliedConfiguration?.rowID else { return }
		disclosureIndicator.toggleDisclosure()
		let applyToAll = event.modifierFlags.contains(.alternate)
		appliedConfiguration?.delegate?.editorRowToggleDisclosure(rowID: rowID, applyToAll: applyToAll)
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
		
		if let numberingStyle = config.outlineNumberingStyle, numberingStyle != Outline.NumberingStyle.none {
			addSubview(numberingLabel)
			
			if config.isNotesVisible {
				addSubview(noteTextView)

				NSLayoutConstraint.activate([
					numberingLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
					numberingLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 0 - spacingAdjustment),

					topicTextView.leadingAnchor.constraint(equalTo: numberingLabel.trailingAnchor, constant: 8),
					topicTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
					topicTextView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 0 - spacingAdjustment),
					topicTextView.bottomAnchor.constraint(equalTo: noteTextView.topAnchor, constant: spacingAdjustment / 2),
					
					noteTextView.leadingAnchor.constraint(equalTo: numberingLabel.trailingAnchor, constant: 8),
					noteTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
					noteTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: spacingAdjustment),
					barView.trailingAnchor.constraint(equalTo: numberingLabel.leadingAnchor)
				])
			} else {
				if noteTextView.isFirstResponder {
					topicTextView.becomeFirstResponder()
				}
				noteTextView.removeFromSuperview()
				NSLayoutConstraint.activate([
					numberingLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
					numberingLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 0 - spacingAdjustment),

					topicTextView.leadingAnchor.constraint(equalTo: numberingLabel.trailingAnchor, constant: 8),
					topicTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
					topicTextView.topAnchor.constraint(equalTo: numberingLabel.topAnchor),
					topicTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: spacingAdjustment),
					
					barView.trailingAnchor.constraint(equalTo: numberingLabel.leadingAnchor)
				])
			}

			numberingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
			numberingLabel.setContentHuggingPriority(.required, for: .horizontal)
		} else {
			numberingLabel.removeFromSuperview()
			
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
				if noteTextView.isFirstResponder {
					topicTextView.becomeFirstResponder()
				}
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
	}
	
	func resize() {
		if AppDefaults.shared.disableEditorAnimations {
			UIView.performWithoutAnimation {
				invalidateIntrinsicContentSize()
			}
		} else {
			invalidateIntrinsicContentSize()
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
