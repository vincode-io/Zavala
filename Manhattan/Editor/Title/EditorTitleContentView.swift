//
//  EditorTitleContentView.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton

class EditorTitleContentView: UIView, UIContentView {

	let textView = UITextView()
	var textViewHeight: CGFloat?
	var adjustingSeparatorWidthContraint: NSLayoutConstraint?
	
	var outline: Outline
	var appliedConfiguration: EditorTitleContentConfiguration!
	
	init(configuration: EditorTitleContentConfiguration) {
		self.outline = configuration.outline
		super.init(frame: .zero)

		textView.delegate = self
		textView.isScrollEnabled = false
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		textView.font = UIFont.preferredFont(forTextStyle: .largeTitle)
		textView.textAlignment = .center
		textView.backgroundColor = .clear
		textView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(textView)

		let separator = UIView()
		separator.backgroundColor = AppAssets.accessory
		separator.translatesAutoresizingMaskIntoConstraints = false
		addSubview(separator)
		
		adjustingSeparatorWidthContraint = separator.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
		
		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
			
			separator.heightAnchor.constraint(equalToConstant: 2),
			adjustingSeparatorWidthContraint!,
			separator.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
			separator.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: 4),
			separator.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor)
		])

		apply(configuration: configuration)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorTitleContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorTitleContentConfiguration) {
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration
		outline = configuration.outline
		textView.text = outline.title
		updateAdjustingSeparatorWidthContraint()
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
			appliedConfiguration.delegate?.createHeadline()
			return false
		default:
			return true
		}
	}
	
	func textViewDidChange(_ textView: UITextView) {
		outline.update(title: textView.text)
		
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		if textViewHeight != fittingSize.height {
			textViewHeight = fittingSize.height
			invalidateIntrinsicContentSize()
			appliedConfiguration.delegate?.invalidateLayout()
		}
		
		updateAdjustingSeparatorWidthContraint()
	}
	
}

// MARK: Helpers

extension EditorTitleContentView {
	
	func updateAdjustingSeparatorWidthContraint() {
		let fittingSize = textView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: textView.frame.height))
		adjustingSeparatorWidthContraint?.constant = fittingSize.width
	}
	
}
