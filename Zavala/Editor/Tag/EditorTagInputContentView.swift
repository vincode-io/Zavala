//
//  EditorTagInputContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit
import VinOutlineKit

class EditorTagInputContentView: UIView, UIContentView {

	let inputPill = EditorTagInputPill()
	
	weak var delegate: EditorTagInputViewCellDelegate?
	
	var appliedConfiguration: EditorTagInputContentConfiguration!
	
	init(configuration: EditorTagInputContentConfiguration) {
		self.delegate = configuration.delegate
		super.init(frame: .zero)

		layoutMargins = .init(top: 8, left: 4, bottom: 8, right: 4)
		
		inputPill.translatesAutoresizingMaskIntoConstraints = false
		addSubview(inputPill)

		NSLayoutConstraint.activate([
			inputPill.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			inputPill.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			inputPill.topAnchor.constraint(equalTo: topAnchor),
			inputPill.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
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
		inputPill.editorDelegate = self
		inputPill.updateAppearance()
		
		if appliedConfiguration != configuration {
			inputPill.reset()
		}
		
		appliedConfiguration = configuration
	}
	
}

extension EditorTagInputContentView: EditorTagInputPillDelegate {

	var editorTagInputPillUndoManager: UndoManager? {
		return delegate?.editorTagInputUndoManager
	}
	
	var editorTagInputPillTags: [Tag]? {
		return delegate?.editorTagInputTags
	}
	
	func invalidateLayout(_: EditorTagInputPill) {
		delegate?.editorTagInputLayoutEditor()
	}
	
	func didBecomeActive(_ editorTagInputPill: EditorTagInputPill) {
		delegate?.editorTagInputTextFieldDidBecomeActive(editorTagInputPill.textField)
	}
	
	func didBecomeInactive(_ editorTagInputPill: EditorTagInputPill) {
		delegate?.editorTagInputTextFieldDidBecomeInactive()
	}

	func didReturn(_: EditorTagInputPill) {
		delegate?.editorTagInputTextFieldDidReturn()
	}
	
	func createTag(_: EditorTagInputPill, name: String) {
		delegate?.editorTagInputTextFieldCreateTag(name: name)
	}
	
}
