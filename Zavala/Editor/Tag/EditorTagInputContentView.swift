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
		view.layer.borderWidth = 1
		view.layer.borderColor = AppAssets.accessory.cgColor

		if traitCollection.userInterfaceIdiom == .mac {
			view.layer.cornerRadius = 10
		} else {
			view.layer.cornerRadius = 13
		}

		view.addSubview(textField)
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.placeholder = L10n.tag
		textField.borderStyle = .none
		textField.editorDelegate = self
		textField.filterStrings(["Home", "Work", "Project", "Zavala"])
		
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
	
}

extension EditorTagInputContentView: EditorTagInputTextFieldDelegate {

	var editorTagInputTextFieldUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorTagInputUndoManager
	}
	
	func invalidateLayout(_: EditorTagInputTextField) {
		appliedConfiguration.delegate?.editorTagInputLayoutEditor()
	}
	
	func didBecomeActive(_: EditorTagInputTextField) {
		appliedConfiguration.delegate?.editorTagInputTextFieldDidBecomeActive()
	}
	
	func didBecomeInactive(_: EditorTagInputTextField) {
		appliedConfiguration.delegate?.editorTagInputTextFieldDidBecomeInactive()
	}
	
	func createRow(_: EditorTagInputTextField) {
		appliedConfiguration.delegate?.editorTagInputTextFieldCreateRow()
	}
	
}
