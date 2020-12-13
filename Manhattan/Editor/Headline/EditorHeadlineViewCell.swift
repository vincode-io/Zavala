//
//  EditorCollectionViewCell.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit
import Templeton

protocol EditorHeadlineViewCellDelegate: class {
	var editorHeadlineUndoManager: UndoManager? { get }
	func editorHeadlineInvalidateLayout()
	func editorHeadlineToggleDisclosure(headline: Headline)
	func editorHeadlineTextChanged(headline: Headline, attributedTexts: HeadlineTexts)
	func editorHeadlineDeleteHeadline(_ headline: Headline, attributedTexts: HeadlineTexts)
	func editorHeadlineCreateHeadline(_ afterHeadline: Headline?)
	func editorHeadlineIndentHeadline(_ headline: Headline, attributedTexts: HeadlineTexts)
	func editorHeadlineOutdentHeadline(_ headline: Headline, attributedTexts: HeadlineTexts)
	func editorHeadlineSplitHeadline(_: Headline, attributedText: NSAttributedString, cursorPosition: Int)
}

class EditorHeadlineViewCell: UICollectionViewListCell {

	var headline: Headline? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	weak var delegate: EditorHeadlineViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	var attributedTexts: HeadlineTexts? {
		return (contentView as? EditorHeadlineContentView)?.attributedTexts
	}
	
	var textWidth: CGFloat? {
		return (contentView as? EditorHeadlineContentView)?.textView.intrinsicContentSize.width
	}
	
	var selectionRange: UITextRange? {
		guard let textView = (contentView as? EditorHeadlineContentView)?.textView else { return nil }
		return textView.selectedTextRange
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

		guard let headline = headline else { return }

		indentationLevel = headline.indentLevel

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

		if headline.headlines?.isEmpty ?? true {
			var accessoryConfig = UICellAccessory.CustomViewConfiguration(customView: bullet, placement: placement)
			accessoryConfig.tintColor = AppAssets.accessory
			accessories = [.customView(configuration: accessoryConfig)]
		} else {
			var accessoryConfig = UICellAccessory.CustomViewConfiguration(customView: disclosureIndicator, placement: placement)
			accessoryConfig.tintColor = AppAssets.accessory
			accessories = [.customView(configuration: accessoryConfig)]
		}
		
		setDisclosure(isExpanded: headline.isExpanded ?? true, animated: false)

		var content = EditorHeadlineContentConfiguration(headline: headline, indentionLevel: indentationLevel, indentationWidth: indentationWidth).updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}

	func restoreSelection(_ textRange: UITextRange) {
		guard let textView = (contentView as? EditorHeadlineContentView)?.textView else { return }
		textView.becomeFirstResponder()
		textView.selectedTextRange = textRange
	}
	
	func moveToStart() {
		guard let textView = (contentView as? EditorHeadlineContentView)?.textView else { return }
		textView.becomeFirstResponder()
		let startPosition = textView.beginningOfDocument
		textView.selectedTextRange = textView.textRange(from: startPosition, to: startPosition)
	}
	
	func moveToEnd() {
		guard let textView = (contentView as? EditorHeadlineContentView)?.textView else { return }
		textView.becomeFirstResponder()
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
	}
	
}

// MARK: Helpers

extension EditorHeadlineViewCell {
	
	@objc func toggleDisclosure(_ sender: UITapGestureRecognizer) {
		guard sender.state == .ended, let headline = headline else { return }
		setDisclosure(isExpanded: !isDisclosed, animated: true)
		delegate?.editorHeadlineToggleDisclosure(headline: headline)
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
