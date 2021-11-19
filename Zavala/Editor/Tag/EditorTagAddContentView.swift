//
//  EditorTagAddContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 2/4/21.
//

import UIKit

class EditorTagAddContentView: UIView, UIContentView {

	let button = UIButton(type: .roundedRect)
	weak var delegate: EditorTagAddViewCellDelegate?
	
	var appliedConfiguration: EditorTagAddContentConfiguration!
	
	init(configuration: EditorTagAddContentConfiguration) {
		self.delegate = configuration.delegate
		super.init(frame: .zero)

		addSubview(button)
		
		button.translatesAutoresizingMaskIntoConstraints = false
		button.titleLabel?.font = OutlineFontCache.shared.tag
		button.setTitle(L10n.add, for: .normal)
		
		let action = UIAction() { [weak self] _ in
			self?.delegate?.editorTagAddAddTag()
		}
		button.addAction(action, for: .touchUpInside)
		
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
			guard let newConfig = newValue as? EditorTagAddContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorTagAddContentConfiguration) {
		button.titleLabel?.font = OutlineFontCache.shared.tag

		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		delegate = configuration.delegate
	}
	
}
