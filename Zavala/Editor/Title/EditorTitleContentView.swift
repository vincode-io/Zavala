//
//  EditorTitleContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton

class EditorTitleContentView: UIView, UIContentView {

	let textView = EditorTitleTextView()
	var textViewHeight: CGFloat?
	
	init(configuration: EditorTitleContentConfiguration) {
		self.configuration = configuration
		super.init(frame: .zero)

		textView.delegate = self
		textView.editorDelegate = self
		textView.isScrollEnabled = false
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		textView.font = OutlineFontCache.shared.title
		textView.textAlignment = .center
		textView.backgroundColor = .clear
		textView.autocapitalizationType = .words
		textView.adjustsFontForContentSizeCategory = true
		textView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(textView)

		let separator = UIView()
		separator.backgroundColor = AppAssets.accessory
		separator.translatesAutoresizingMaskIntoConstraints = false
		addSubview(separator)
		
		NSLayoutConstraint.activate([
			textView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
			textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
		])

		apply()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var configuration: UIContentConfiguration {
		didSet {
			apply()
		}
	}
	
	private var titleConfiguration: EditorTitleContentConfiguration {
		return configuration as! EditorTitleContentConfiguration
	}
	
	private func apply() {
		textView.font = OutlineFontCache.shared.title
		textView.text = titleConfiguration.outline?.title
	}
	
}

// MARK: EditorTitleTextViewDelegate

extension EditorTitleContentView: EditorTitleTextViewDelegate {
	
	var editorTitleTextViewUndoManager: UndoManager? {
		return titleConfiguration.delegate?.editorTitleUndoManager
	}
	
	func didBecomeActive(_: EditorTitleTextView) {
		titleConfiguration.delegate?.editorTitleTextFieldDidBecomeActive()
	}
	
}

// MARK: UITextViewDelegate

extension EditorTitleContentView: UITextViewDelegate {
	
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		textViewHeight = fittingSize.height
		return true
	}

	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		switch text {
		case "\n":
			titleConfiguration.delegate?.editorTitleMoveToTagInput()
			return false
		default:
			return true
		}
	}
	
	func textViewDidChange(_ textView: UITextView) {
		titleConfiguration.delegate?.editorTitleDidUpdate(title: textView.text)
		
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		if textViewHeight != fittingSize.height {
			textViewHeight = fittingSize.height
			invalidateIntrinsicContentSize()
			titleConfiguration.delegate?.editorTitleLayoutEditor()
		}
	}
	
}
