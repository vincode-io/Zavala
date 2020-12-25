//
//  EditorTextRowViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit
import Templeton

protocol EditorTextRowViewCellDelegate: class {
	var editorTextRowUndoManager: UndoManager? { get }
	func editorTextRowInvalidateLayout()
	func editorTextRowToggleDisclosure(row: TextRow)
	func editorTextRowMoveCursorTo(row: TextRow)
	func editorTextRowMoveCursorDown(row: TextRow)
	func editorTextRowTextChanged(row: TextRow, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int)
	func editorTextRowDeleteRow(_ row: TextRow, textRowStrings: TextRowStrings)
	func editorTextRowCreateRow(beforeRow: TextRow)
	func editorTextRowCreateRow(afterRow: TextRow?, textRowStrings: TextRowStrings?)
	func editorTextRowIndentRow(_ row: TextRow, textRowStrings: TextRowStrings)
	func editorTextRowOutdentRow(_ row: TextRow, textRowStrings: TextRowStrings)
	func editorTextRowSplitRow(_: TextRow, topic: NSAttributedString, cursorPosition: Int)
	func editorTextRowCreateRowNote(_ row: TextRow, textRowStrings: TextRowStrings)
	func editorTextRowDeleteRowNote(_ row: TextRow, textRowStrings: TextRowStrings)
	func editorTextRowEditLink(_ link: String?, range: NSRange)
}

class EditorTextRowViewCell: UICollectionViewListCell {

	var textRow: TextRow? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	weak var delegate: EditorTextRowViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	var textRowStrings: TextRowStrings? {
		return (contentView as? EditorTextRowContentView)?.textRowStrings
	}
	
	var topicTextView: EditorTextRowTopicTextView? {
		return (contentView as? EditorTextRowContentView)?.topicTextView
	}
	
	var noteTextView: EditorTextRowNoteTextView? {
		return (contentView as? EditorTextRowContentView)?.noteTextView
	}
	
	private var isDisclosed = false

	private lazy var disclosureIndicator: UIView = {
		let indicator = FixedSizeImageView(image: AppAssets.disclosure)
		
		if traitCollection.userInterfaceIdiom == .mac {
			indicator.dimension = 25
			indicator.tintColor = .systemGray2
		} else {
			indicator.dimension = 44
		}
		
		indicator.isUserInteractionEnabled = true
		indicator.contentMode = .center
		indicator.clipsToBounds = false
		let tap = UITapGestureRecognizer(target: self, action:#selector(toggleDisclosure(_:)))
		indicator.addGestureRecognizer(tap)
		return indicator
	}()
	
	private lazy var bullet: UIView = {
		let bulletView = FixedSizeImageView(image: AppAssets.bullet)
		bulletView.dimension = 4

		if traitCollection.userInterfaceIdiom == .mac {
			bulletView.tintColor = .quaternaryLabel
		}
		
		return bulletView
	}()
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		
		layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

		guard let textRow = textRow else { return }

		indentationLevel = textRow.indentLevel

		// We make the indentation width the same regardless of device if not compact
		if traitCollection.horizontalSizeClass != .compact {
			indentationWidth = 13
		} else {
			indentationWidth = 10
		}
		
		let placement: UICellAccessory.Placement
		if traitCollection.horizontalSizeClass != .compact {
			placement = .leading(displayed: .always, at: { _ in return 0 })
		} else {
			placement = .trailing(displayed: .always, at: { _ in return 0 })
		}

		if textRow.rows?.isEmpty ?? true {
			var accessoryConfig = UICellAccessory.CustomViewConfiguration(customView: bullet, placement: placement)
			accessoryConfig.tintColor = AppAssets.accessory
			accessories = [.customView(configuration: accessoryConfig)]
		} else {
			var accessoryConfig = UICellAccessory.CustomViewConfiguration(customView: disclosureIndicator, placement: placement)
			accessoryConfig.tintColor = AppAssets.accessory
			accessories = [.customView(configuration: accessoryConfig)]
		}
		
		setDisclosure(isExpanded: textRow.isExpanded ?? true, animated: false)

		var content = EditorTextRowContentConfiguration(row: textRow, indentionLevel: indentationLevel, indentationWidth: indentationWidth).updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}

	func restoreSelection(_ textRange: UITextRange) {
		guard let textView = (contentView as? EditorTextRowContentView)?.topicTextView else { return }
		textView.becomeFirstResponder()
		textView.selectedTextRange = textRange
	}
	
	func restoreCursor(_ cursorCoordinates: CursorCoordinates) {
		let textView: OutlineTextView?
		if cursorCoordinates.isInNotes {
			textView = (contentView as? EditorTextRowContentView)?.noteTextView
		} else {
			textView = (contentView as? EditorTextRowContentView)?.topicTextView
		}
		
		if let textView = textView, let textPosition = textView.position(from: textView.beginningOfDocument, offset: cursorCoordinates.cursorPosition) {
			textView.becomeFirstResponder()
			textView.selectedTextRange = textView.textRange(from: textPosition, to: textPosition)
		} else if let textView = textView {
			textView.becomeFirstResponder()
			let endPosition = textView.endOfDocument
			textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
		}
	}
	
	func moveToStart() {
		guard let textView = (contentView as? EditorTextRowContentView)?.topicTextView else { return }
		textView.becomeFirstResponder()
		let startPosition = textView.beginningOfDocument
		textView.selectedTextRange = textView.textRange(from: startPosition, to: startPosition)
	}
	
	func moveToEnd() {
		guard let textView = (contentView as? EditorTextRowContentView)?.topicTextView else { return }
		textView.becomeFirstResponder()
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
	}
	
	func moveToNote() {
		guard let textView = (contentView as? EditorTextRowContentView)?.noteTextView else { return }
		textView.becomeFirstResponder()
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
	}
	
}

// MARK: Helpers

extension EditorTextRowViewCell {
	
	@objc func toggleDisclosure(_ sender: UITapGestureRecognizer) {
		guard sender.state == .ended, let textRow = textRow else { return }
		setDisclosure(isExpanded: !isDisclosed, animated: true)
		delegate?.editorTextRowToggleDisclosure(row: textRow)
	}
	
	private func setDisclosure(isExpanded: Bool, animated: Bool) {
		guard isDisclosed != isExpanded else { return }
		isDisclosed = isExpanded

		if isDisclosed {
			disclosureIndicator.accessibilityLabel = L10n.collapse
			if animated {
				UIView.animate(withDuration: 0.15) {
					self.disclosureIndicator.transform = CGAffineTransform(rotationAngle: 1.570796)
				}
			} else {
				disclosureIndicator.transform = CGAffineTransform(rotationAngle: 1.570796)

			}
		} else {
			disclosureIndicator.accessibilityLabel = L10n.expand
			if animated {
				UIView.animate(withDuration: 0.15) {
					self.disclosureIndicator.transform = CGAffineTransform(rotationAngle: 0)
				}
			} else {
				disclosureIndicator.transform = CGAffineTransform(rotationAngle: 0)
			}
		}
	}
	
}
