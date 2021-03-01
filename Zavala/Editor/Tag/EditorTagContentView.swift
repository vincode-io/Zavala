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
		button.backgroundColor = .systemGray4
		button.setTitleColor(.secondaryLabel, for: .normal)
		button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)

		if traitCollection.userInterfaceIdiom == .mac {
			button.layer.cornerRadius = 10
		} else {
			button.layer.cornerRadius = 13
		}

		let deleteAction = UIAction(title: L10n.delete, image: AppAssets.delete, attributes: .destructive) { [weak self] _ in
			guard let self = self, let name = self.button.currentTitle else { return }
			self.delegate?.editorTagDeleteTag(name: name)
		}
		let menu = UIMenu(title: "", image: nil, identifier: nil, options: [], children: [deleteAction])
		button.menu = menu
		button.showsMenuAsPrimaryAction = true

		NSLayoutConstraint.activate([
			button.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			button.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			button.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
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
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		delegate = configuration.delegate
		button.setTitle(configuration.name, for: .normal)
	}
	
}

