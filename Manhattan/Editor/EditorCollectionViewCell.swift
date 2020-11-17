//
//  EditorCollectionViewCell.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit

protocol EditorCollectionViewCellDelegate: class {
	func indent(item: EditorItem)
	func outdent(item: EditorItem)
	func moveUp(item: EditorItem)
	func moveDown(item: EditorItem)
	func newHeadline(item: EditorItem)
}

class EditorCollectionViewCell: UICollectionViewListCell {

	weak var editorItem: EditorItem? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		
		var content = EditorContentConfiguration().updated(for: state)
		content.editorItem = editorItem
		
		if traitCollection.userInterfaceIdiom == .mac && accessories.isEmpty {
			content.indentationWidth = indentationWidth + 16
		}
		
		contentConfiguration = content
	}

	func takeCursor() {
		(contentView as? EditorContentView)?.textView.becomeFirstResponder()
	}
	
}

struct EditorContentConfiguration: UIContentConfiguration, Hashable {

	weak var editorItem: EditorItem? = nil
	var indentationWidth: CGFloat? = nil
	
	func makeContentView() -> UIView & UIContentView {
		return EditorContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}
	
}

class EditorContentView: UIView, UIContentView {

	let textView = EditorTextView()
	var appliedConfiguration: EditorContentConfiguration!

	init(configuration: EditorContentConfiguration) {
		super.init(frame: .zero)

		textView.isScrollEnabled = false
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		textView.font = UIFont.preferredFont(forTextStyle: .body)
		
		addSubview(textView)
		textView.translatesAutoresizingMaskIntoConstraints = false

		apply(configuration: configuration)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorContentConfiguration) {
		guard appliedConfiguration != configuration, let editorItem = configuration.editorItem else { return }
		appliedConfiguration = configuration
		textView.text = editorItem.plainText

		textView.removeConstraintsAssociatedWithSuperView()
		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: configuration.indentationWidth ?? 0.0),
			textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
		])
	}
	
}

private extension UIView {

	/**
	 Removes all constrains for this view
	 */
	func removeConstraintsAssociatedWithSuperView() {
		let constraints = self.superview?.constraints.filter{
			$0.firstItem as? UIView == self || $0.secondItem as? UIView == self
		} ?? []

		self.superview?.removeConstraints(constraints)
		self.removeConstraints(self.constraints)
	}
	
}
