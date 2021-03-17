//
//  EditorBacklinkContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 3/16/21.
//

import UIKit

class EditorBacklinkContentView: UIView, UIContentView {

	let textView = UITextView()
	
	var appliedConfiguration: EditorBacklinkContentConfiguration!
	
	init(configuration: EditorBacklinkContentConfiguration) {
		super.init(frame: .zero)

		textView.isEditable = false
		textView.isScrollEnabled = false
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		textView.backgroundColor = .clear
		textView.adjustsFontForContentSizeCategory = true
		textView.translatesAutoresizingMaskIntoConstraints = false
		textView.linkTextAttributes = [.foregroundColor: UIColor.secondaryLabel, .underlineStyle: 1]
		addSubview(textView)
		
		let adjustment: CGFloat = traitCollection.horizontalSizeClass == .compact ? 10 : 6
		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustment),
			textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: 0 - adjustment),
			textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
		])

		apply(configuration: configuration)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorBacklinkContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorBacklinkContentConfiguration) {
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		textView.attributedText = configuration.reference
	}
	
}
