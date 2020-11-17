//
//  EditorCollectionViewCell.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/16/20.
//

import Foundation

import UIKit

class EditorCollectionViewCell: UICollectionViewListCell {

	var editableText: String? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		var content = EditorContentConfiguration().updated(for: state)
		content.editableText = editableText
		if traitCollection.userInterfaceIdiom == .mac && accessories.isEmpty {
			content.indentionWidth = indentationWidth
		}
		contentConfiguration = content
	}

}

struct EditorContentConfiguration: UIContentConfiguration, Hashable {

	var editableText: String? = nil
	var indentionWidth: CGFloat? = nil
	
	func makeContentView() -> UIView & UIContentView {
		return EditorContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}
}

class EditorContentView: UIView, UIContentView {

	private let textView = UITextView()
	private var appliedConfiguration: EditorContentConfiguration!

	init(configuration: EditorContentConfiguration) {
		super.init(frame: .zero)
		setupInternalViews()
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
	
	private func setupInternalViews() {
		textView.isScrollEnabled = false
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		textView.font = UIFont.preferredFont(forTextStyle: .body)
		
		addSubview(textView)
		textView.translatesAutoresizingMaskIntoConstraints = false
	}
		
	private func apply(configuration: EditorContentConfiguration) {
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		textView.text = configuration.editableText

		textView.removeConstraintsAssociatedWithSuperView()
		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: configuration.indentionWidth ?? 0.0),
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
