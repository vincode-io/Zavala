//
//  EditorTagContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit

class EditorTagContentView: UIView, UIContentView {

	let button = UIButton()
	weak var delegate: EditorTagViewCellDelegate?
	
	var appliedConfiguration: EditorTagContentConfiguration!
	
	init(configuration: EditorTagContentConfiguration) {
		self.delegate = configuration.delegate
		super.init(frame: .zero)

		addSubview(button)
		
		button.translatesAutoresizingMaskIntoConstraints = false
		button.titleLabel?.font = OutlineFontCache.shared.tagFont
		button.backgroundColor = .systemGray4
		button.setTitleColor(OutlineFontCache.shared.tagColor, for: .normal)
		button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
		button.layer.cornerRadius = button.intrinsicContentSize.height / 2

		let deleteAction = UIAction(title: .removeTagControlLabel, image: .delete, attributes: .destructive) { [weak self] _ in
			guard let self, let name = self.button.currentTitle else { return }
			self.delegate?.editorTagDeleteTag(name: name)
		}
		let menu = UIMenu(title: "", image: nil, identifier: nil, options: [], children: [deleteAction])
		button.menu = menu

		NSLayoutConstraint.activate([
			button.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			button.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			button.topAnchor.constraint(equalTo: topAnchor),
			button.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
		])

		apply(configuration: configuration)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorTagContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorTagContentConfiguration) {
		button.titleLabel?.font = OutlineFontCache.shared.tagFont
		button.setTitleColor(OutlineFontCache.shared.tagColor, for: .normal)
		button.layer.cornerRadius = button.intrinsicContentSize.height / 2
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		delegate = configuration.delegate
		button.setTitle(configuration.name, for: .normal)
	}
	
}

