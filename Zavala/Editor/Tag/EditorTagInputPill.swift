//
//  EditorTagInputPill.swift
//  Zavala
//
//  Created by Maurice Parker on 11/20/21.
//

import UIKit
import VinOutlineKit

@MainActor
protocol EditorTagInputPillDelegate: AnyObject {
	var editorTagInputPillUndoManager: UndoManager? { get }
	var editorTagInputPillTags: [Tag]? { get }
	func invalidateLayout(_: EditorTagInputPill)
	func didBecomeActive(_ : EditorTagInputPill)
	func didReturn(_ : EditorTagInputPill)
	func createTag(_ : EditorTagInputPill, name: String)
}

class EditorTagInputPill: UIView {
	
	weak var editorDelegate: EditorTagInputPillDelegate?
	
	let border: UIView
	
	let textField: EditorTagInputTextField
	var textFieldTrailingConstraint: NSLayoutConstraint?

	let button: UIButton
	var buttonWidthConstraint: NSLayoutConstraint?
	var buttonIsShowing = false
	
	var cornerRadius: CGFloat {
		return (textField.intrinsicContentSize.height + 8) / 2
	}
	
	override init(frame: CGRect) {
		border = UIView()
		textField = EditorTagInputTextField()
		button = UIButton()

		super.init(frame: frame)

		addSubview(border)

		textField.editorDelegate = self
		textField.placeholder = "Tag"
		textField.font = OutlineFontCache.shared.tagFont
		textField.textColor = OutlineFontCache.shared.tagColor
		textField.translatesAutoresizingMaskIntoConstraints = false
		border.addSubview(textField)

		button.addTarget(textField, action: #selector(EditorTagInputTextField.createTag), for: .touchUpInside)
		button.tintColor = .white
		button.contentEdgeInsets = .init(top: 0, left: 5, bottom: 0, right: 8)
		button.translatesAutoresizingMaskIntoConstraints = false
		addSubview(button)
		
		buttonWidthConstraint = button.widthAnchor.constraint(equalToConstant: layoutMargins.right)
		textFieldTrailingConstraint = textField.trailingAnchor.constraint(equalTo: button.leadingAnchor)
		
		let textFieldMaxWidth = UIFontMetrics(forTextStyle: .body).scaledValue(for: 200)
		
		NSLayoutConstraint.activate([
			border.topAnchor.constraint(equalTo: topAnchor),
			border.leadingAnchor.constraint(equalTo: leadingAnchor),
			border.bottomAnchor.constraint(equalTo: bottomAnchor),
			border.trailingAnchor.constraint(equalTo: trailingAnchor),
			textField.topAnchor.constraint(equalTo: border.topAnchor, constant: 4),
			textField.leadingAnchor.constraint(equalTo: border.layoutMarginsGuide.leadingAnchor),
			textField.bottomAnchor.constraint(equalTo: border.bottomAnchor, constant: -4),
			textField.widthAnchor.constraint(lessThanOrEqualToConstant: textFieldMaxWidth),
			button.topAnchor.constraint(equalTo: topAnchor),
			button.trailingAnchor.constraint(equalTo: trailingAnchor),
			button.bottomAnchor.constraint(equalTo: bottomAnchor),
			buttonWidthConstraint!,
			textFieldTrailingConstraint!,
		])
		
		let cornerRadius = cornerRadius
		
		clipsToBounds = true
		layer.cornerRadius = cornerRadius
		
		border.translatesAutoresizingMaskIntoConstraints = false
		border.layer.borderWidth = 1
		border.layer.borderColor = UIColor.tertiarySystemBackground.cgColor
		border.layer.cornerRadius = cornerRadius
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? false {
			border.layer.borderColor = UIColor.tertiarySystemBackground.cgColor
		}
	}
	
	// MARK: API
	
	func updateAppearance() {
		textField.font = OutlineFontCache.shared.tagFont
		textField.textColor = OutlineFontCache.shared.tagColor
		let cornerRadius = cornerRadius
		layer.cornerRadius = cornerRadius
		border.layer.cornerRadius = cornerRadius
		button.titleLabel?.font = UIFont.systemFont(ofSize: OutlineFontCache.shared.tagFont.pointSize)
	}
	
	func reset() {
		textField.text = nil
		hideButton()
	}
}

// MARK: EditorTagInputTextFieldDelegate

extension EditorTagInputPill: EditorTagInputTextFieldDelegate {
	
	var editorTagInputTextFieldUndoManager: UndoManager? {
		return editorDelegate?.editorTagInputPillUndoManager
	}
	
	var editorTagInputTextFieldTags: [Tag]? {
		return editorDelegate?.editorTagInputPillTags
	}
	
	func didBecomeActive(_: EditorTagInputTextField) {
		editorDelegate?.didBecomeActive(self)
	}

	func textDidChange(_: EditorTagInputTextField) {
		updateUI()
	}

	func didReturn(_: EditorTagInputTextField) {
		editorDelegate?.didReturn(self)
	}
	
	func createTag(_: EditorTagInputTextField, name: String) {
		editorDelegate?.createTag(self, name: name)
		updateUI()
	}
	
}

// MARK: Helpers

private extension EditorTagInputPill {
	
	func updateUI() {
		if textField.hasText != buttonIsShowing {
			updateButtonVisibility()
		} else {
			UIView.animate(withDuration: 0.1) {
				self.editorDelegate?.invalidateLayout(self)
			}
		}
	}
	
	func updateButtonVisibility() {
		if textField.hasText {
			UIView.animate(withDuration: 0.2) {
				self.showButton()
				self.editorDelegate?.invalidateLayout(self)
			}
		} else {
			UIView.animate(withDuration: 0.2) {
				self.hideButton()
				self.editorDelegate?.invalidateLayout(self)
			}
		}
	}
	
	func showButton() {
		self.button.backgroundColor = .accentColor
		self.buttonWidthConstraint?.isActive = false
		self.textFieldTrailingConstraint?.constant = -4
		self.button.setTitle(.addControlLabel, for: .normal)
		buttonIsShowing = true
	}
	
	func hideButton() {
		self.button.setTitle("", for: .normal)
		self.button.backgroundColor = nil
		self.buttonWidthConstraint?.isActive = true
		self.textFieldTrailingConstraint?.constant = 0
		buttonIsShowing = false
	}
	
}
