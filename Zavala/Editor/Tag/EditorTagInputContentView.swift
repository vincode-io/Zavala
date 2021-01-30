//
//  EditorTagInputContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit

class EditorTagInputContentView: UIView, UIContentView {

	let textField = EditorTagInputTextField()
	weak var delegate: EditorTagInputViewCellDelegate?
	
	var appliedConfiguration: EditorTagInputContentConfiguration!
	
	init(configuration: EditorTagInputContentConfiguration) {
		self.delegate = configuration.delegate
		super.init(frame: .zero)

		let view = UIView()
		addSubview(view)
		
		view.translatesAutoresizingMaskIntoConstraints = false
		view.layer.cornerRadius = 10
		view.layer.borderWidth = 1
		view.layer.borderColor = AppAssets.accessory.cgColor

		view.addSubview(textField)
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.placeholder = L10n.tag
		textField.borderStyle = .none
		textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
		
		NSLayoutConstraint.activate([
			view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
			textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
			textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
			textField.topAnchor.constraint(equalTo: view.topAnchor, constant: 2.5),
			textField.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2.5),
		])
		
		apply(configuration: configuration)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorTagInputContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorTagInputContentConfiguration) {
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		textField.text = ""
	}
	
	@objc func textFieldDidChange(_ textField: UITextField) {
		textField.invalidateIntrinsicContentSize()
		self.appliedConfiguration.delegate?.editorTagInputLayoutEditor()
	}
	
}
