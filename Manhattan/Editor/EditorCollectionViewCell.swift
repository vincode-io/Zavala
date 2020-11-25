//
//  EditorCollectionViewCell.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit
import Templeton

protocol EditorCollectionViewCellDelegate: class {
	func toggleDisclosure(headline: Headline)
	func textChanged(headline: Headline, attributedText: NSAttributedString)
	func deleteHeadline(headline: Headline)
	func createHeadline(headline: Headline)
	func indent(headline: Headline, attributedText: NSAttributedString)
	func outdent(headline: Headline, attributedText: NSAttributedString)
	func moveUp(headline: Headline)
	func moveDown(headline: Headline)
}

class EditorCollectionViewCell: UICollectionViewListCell {

	var headline: Headline? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	weak var delegate: EditorCollectionViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
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
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		
		layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

		guard let headline = headline else { return }

		if headline.headlines?.isEmpty ?? true {
			accessories = []
		} else {
			let placement: UICellAccessory.Placement
			if traitCollection.userInterfaceIdiom == .mac {
				placement = .leading(displayed: .always, at: { _ in return 0 })
			} else {
				placement = .trailing(displayed: .always, at: { _ in return 0 })
			}
			let accessoryConfig = UICellAccessory.CustomViewConfiguration(customView: disclosureIndicator, placement: placement)
			accessories = [.customView(configuration: accessoryConfig)]
		}
		
		setDisclosure(isExpanded: headline.isExpanded ?? true, animated: false)
		
		var content = EditorContentConfiguration(indentionLevel: indentationLevel, indentationWidth: indentationWidth).updated(for: state)
		content.headline = headline
		content.delegate = delegate
		contentConfiguration = content
	}

}

extension EditorCollectionViewCell: TextCursorTarget {
	
	func restoreSelection(_ textRange: UITextRange) {
		guard let textView = (contentView as? EditorContentView)?.textView else { return }
		textView.becomeFirstResponder()
		textView.selectedTextRange = textRange
	}
	
	func moveToEnd() {
		guard let textView = (contentView as? EditorContentView)?.textView else { return }
		textView.becomeFirstResponder()
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
	}
	
}

// MARK: Helpers

extension EditorCollectionViewCell {
	
	@objc func toggleDisclosure(_ sender: UITapGestureRecognizer) {
		guard sender.state == .ended, let headline = headline else { return }
		setDisclosure(isExpanded: !isDisclosed, animated: true)
		delegate?.toggleDisclosure(headline: headline)
	}
	
	private func setDisclosure(isExpanded: Bool, animated: Bool) {
		guard isDisclosed != isExpanded else { return }
		isDisclosed = isExpanded

		if isDisclosed {
			disclosureIndicator.accessibilityLabel = NSLocalizedString("Collapse", comment: "Collapse")
			if animated {
				UIView.animate(withDuration: 0.3) {
					self.disclosureIndicator.transform = CGAffineTransform(rotationAngle: 1.570796)
				}
			} else {
				disclosureIndicator.transform = CGAffineTransform(rotationAngle: 1.570796)

			}
		} else {
			disclosureIndicator.accessibilityLabel = NSLocalizedString("Expand", comment: "Expand")
			if animated {
				UIView.animate(withDuration: 0.3) {
					self.disclosureIndicator.transform = CGAffineTransform(rotationAngle: 0)
				}
			} else {
				disclosureIndicator.transform = CGAffineTransform(rotationAngle: 0)
			}
		}
	}
	
}
