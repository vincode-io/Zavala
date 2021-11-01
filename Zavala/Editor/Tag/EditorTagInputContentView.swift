//
//  EditorTagInputContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit
import Templeton

class EditorTagInputContentView: UIView, UIContentView {

	let borderView = UIView()
	let textField = EditorTagInputTextField()
	
	weak var delegate: EditorTagInputViewCellDelegate?
	
	var appliedConfiguration: EditorTagInputContentConfiguration!
	
	init(configuration: EditorTagInputContentConfiguration) {
		self.delegate = configuration.delegate
		super.init(frame: .zero)

		addSubview(borderView)
		
		borderView.translatesAutoresizingMaskIntoConstraints = false
		borderView.layer.borderWidth = 1
		borderView.layer.borderColor = UIColor.systemGray4.cgColor

		borderView.addSubview(textField)
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.font = OutlineFontCache.shared.tag
		textField.editorDelegate = self
		
		NSLayoutConstraint.activate([
			borderView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			borderView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			borderView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			borderView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
			textField.leadingAnchor.constraint(equalTo: borderView.leadingAnchor, constant: 8),
			textField.trailingAnchor.constraint(equalTo: borderView.trailingAnchor, constant: -8),
			textField.topAnchor.constraint(equalTo: borderView.topAnchor, constant: 2.5),
			textField.bottomAnchor.constraint(equalTo: borderView.bottomAnchor, constant: -2.5),
		])

		borderView.layer.cornerRadius = (textField.intrinsicContentSize.height + 5) / 2

		apply(configuration: configuration)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? false {
			borderView.layer.borderColor = UIColor.tertiarySystemBackground.cgColor
		}
	}
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorTagInputContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorTagInputContentConfiguration) {
		textField.font = OutlineFontCache.shared.tag
		borderView.layer.cornerRadius = (textField.intrinsicContentSize.height + 5) / 2
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		textField.text = ""
	}
	
}

extension EditorTagInputContentView: EditorTagInputTextFieldDelegate {

	var editorTagInputTextFieldUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorTagInputUndoManager
	}
	
	var editorTagInputTextFieldIsAddShowing: Bool {
		return appliedConfiguration.delegate?.editorTagInputIsAddShowing ?? false
	}
	
	var editorTagInputTextFieldTags: [Tag]? {
		return appliedConfiguration.delegate?.editorTagInputTags
	}
	
	var editorTagInputAccessoryView: UIView? {
		return appliedConfiguration.delegate?.editorTagInputAccessoryView
	}

	func invalidateLayout(_: EditorTagInputTextField) {
		appliedConfiguration.delegate?.editorTagInputLayoutEditor()
	}
	
	func didBecomeActive(_: EditorTagInputTextField) {
		appliedConfiguration.delegate?.editorTagInputTextFieldDidBecomeActive()
	}
	
	func showAdd(_: EditorTagInputTextField) {
		appliedConfiguration.delegate?.editorTagInputTextFieldShowAdd()
	}
	
	func hideAdd(_: EditorTagInputTextField) {
		appliedConfiguration.delegate?.editorTagInputTextFieldHideAdd()
	}
	
	func createRow(_: EditorTagInputTextField) {
		appliedConfiguration.delegate?.editorTagInputTextFieldCreateRow()
	}
	
	func createTag(_: EditorTagInputTextField, name: String) {
		appliedConfiguration.delegate?.editorTagInputTextFieldCreateTag(name: name)
	}
	
}
