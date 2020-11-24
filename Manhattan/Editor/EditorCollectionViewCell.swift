//
//  EditorCollectionViewCell.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit

protocol EditorCollectionViewCellDelegate: class {
	func textChanged(item: EditorItem, attributedText: NSAttributedString)
	func deleteHeadline(item: EditorItem)
	func createHeadline(item: EditorItem)
	func indent(item: EditorItem, attributedText: NSAttributedString)
	func outdent(item: EditorItem, attributedText: NSAttributedString)
	func moveUp(item: EditorItem)
	func moveDown(item: EditorItem)
}

class EditorCollectionViewCell: UICollectionViewListCell {

	var editorItem: EditorItem? {
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
		let indicator = UIImageView(image: AppAssets.disclosure)
		
		if traitCollection.userInterfaceIdiom == .mac {
			NSLayoutConstraint.activate([
				indicator.widthAnchor.constraint(greaterThanOrEqualToConstant: 25),
				indicator.heightAnchor.constraint(greaterThanOrEqualToConstant: 25)
			])
			indicator.tintColor = .systemGray2
		} else {
			NSLayoutConstraint.activate([
				indicator.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
				indicator.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
			])
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
		guard let editorItem = editorItem else { return }
	
		if editorItem.children.isEmpty {
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
		
		var content = EditorContentConfiguration(editorItem: editorItem, indentionLevel: indentationLevel, indentationWidth: indentationWidth).updated(for: state)
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
		guard sender.state == .ended else { return }
		setDisclosure(isExpanded: !isDisclosed, animated: true)
//		delegate?.masterFeedTableViewCellDisclosureDidToggle(self, expanding: isDisclosureExpanded)
	}
	
	private func setDisclosure(isExpanded: Bool, animated: Bool) {
		isDisclosed = isExpanded
		let duration = animated ? 0.3 : 0.0

		UIView.animate(withDuration: duration) {
			if self.isDisclosed {
				self.disclosureIndicator.accessibilityLabel = NSLocalizedString("Collapse", comment: "Collapse")
				self.disclosureIndicator.transform = CGAffineTransform(rotationAngle: 1.570796)
			} else {
				self.disclosureIndicator.accessibilityLabel = NSLocalizedString("Expand", comment: "Expand")
				self.disclosureIndicator.transform = CGAffineTransform(rotationAngle: 0)
			}
		}
	}
	
}
