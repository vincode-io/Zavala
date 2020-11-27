//
//  EditorContentView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

class EditorContentView: UIView, UIContentView {

	let textView = EditorTextView()
	var bulletView: UIImageView?
	var barViews = [UIView]()
	var appliedConfiguration: EditorContentConfiguration!

	init(configuration: EditorContentConfiguration) {
		super.init(frame: .zero)

		textView.delegate = self
		textView.editorDelegate = self
		
		textView.isScrollEnabled = false
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		textView.font = UIFont.preferredFont(forTextStyle: .body)
		
		addSubview(textView)
		textView.translatesAutoresizingMaskIntoConstraints = false

		let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft(_:)))
		swipeLeftGesture.direction = .left
		addGestureRecognizer(swipeLeftGesture)
		
		let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight(_:)))
		swipeRightGesture.direction = .right
		addGestureRecognizer(swipeRightGesture)
		
		apply(configuration: configuration)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var configuration: UIContentConfiguration {
		get { appliedConfiguration }
		set {
			guard let newConfig = newValue as? EditorContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorContentConfiguration) {
		guard appliedConfiguration != configuration, let headline = configuration.headline else { return }
		appliedConfiguration = configuration
		
		textView.headline = configuration.headline
		
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.foregroundColor] = UIColor.label
		attrs[.font] = UIFont.preferredFont(forTextStyle: .body)
		
		if let attrText = headline.attributedText {
			let mutableAttrText = NSMutableAttributedString(attributedString: attrText)
			let range = NSRange(location: 0, length: mutableAttrText.length)
			mutableAttrText.addAttributes(attrs, range: range)
			textView.attributedText = mutableAttrText
		} else {
			textView.attributedText = NSAttributedString(string: "", attributes: attrs)
		}

		let adjustedLeadingIndention: CGFloat
		let adjustedTrailingIndention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			if configuration.isChevronShowing {
				adjustedLeadingIndention = configuration.indentationWidth - 18
			} else {
				adjustedLeadingIndention = configuration.indentationWidth + 16
			}
			adjustedTrailingIndention = 0
		} else {
			adjustedLeadingIndention = configuration.indentationWidth
			adjustedTrailingIndention = -25
		}
		
		textView.removeConstraintsIncludingOwnedBySuperview()
		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
			textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
			textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
		])

		// TODO: Figure out how to only remove the necessary barViews
		for barView in barViews {
			barView.removeFromSuperview()
		}
		barViews = [UIView]()

		for i in (0...configuration.indentionLevel) {
			if i == 0 {
				if configuration.isChevronShowing {
					removeBullet()
				} else {
					addBullet()
				}
			} else {
				addBarView(indentLevel: i, hasChevron: configuration.isChevronShowing)
			}
		}

	}
	
}

// MARK: UITextViewDelegate

extension EditorContentView: UITextViewDelegate {
	
	func textViewDidEndEditing(_ textView: UITextView) {
		guard let headline = appliedConfiguration.headline else { return }
		appliedConfiguration.delegate?.textChanged(headline: headline, attributedText: textView.attributedText)
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		guard let headline = appliedConfiguration.headline else { return true }
		switch text {
		case "\n":
			appliedConfiguration.delegate?.createHeadline(headline)
			return false
		default:
			return true
		}
	}
	
}

// MARK: EditorTextViewDelegate

extension EditorContentView: EditorTextViewDelegate {
	
	var currentKeyPresses: Set<UIKeyboardHIDUsage> {
		appliedConfiguration.delegate?.currentKeyPresses ?? Set<UIKeyboardHIDUsage>()
	}
	
	func deleteHeadline(_ headline: Headline) {
		appliedConfiguration.delegate?.deleteHeadline(headline)
	}
	
	func createHeadline(_ headline: Headline) {
		appliedConfiguration.delegate?.createHeadline(headline)
	}
	
	func indentHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.indentHeadline(headline, attributedText: attributedText)
	}
	
	func outdentHeadline(_ headline: Headline, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.outdentHeadline(headline, attributedText: attributedText)
	}
	
	func moveCursorUp(headline: Headline) {
		appliedConfiguration.delegate?.moveCursorUp(headline: headline)
	}
	
	func moveCursorDown(headline: Headline) {
		appliedConfiguration.delegate?.moveCursorDown(headline: headline)
	}
	
}

// MARK: Helpers

extension EditorContentView {
	
	@objc func swipedLeft(_ sender: UISwipeGestureRecognizer) {
		guard let headline = appliedConfiguration.headline else { return }
		appliedConfiguration.delegate?.outdentHeadline(headline, attributedText: textView.attributedText)
	}
	
	@objc func swipedRight(_ sender: UISwipeGestureRecognizer) {
		guard let headline = appliedConfiguration.headline else { return }
		appliedConfiguration.delegate?.indentHeadline(headline, attributedText: textView.attributedText)
	}
	
	private func removeBullet() {
		guard let bulletView = bulletView else { return }
		bulletView.removeFromSuperview()
		self.bulletView = nil
	}
	
	private func addBullet() {
		guard bulletView == nil else { return }
		
		bulletView = UIImageView()
		bulletView!.image = UIImage(systemName: "circle.fill")
		bulletView!.translatesAutoresizingMaskIntoConstraints = false
		addSubview(bulletView!)

		if traitCollection.userInterfaceIdiom == .mac {
			bulletView!.tintColor = .quaternaryLabel
			NSLayoutConstraint.activate([
				bulletView!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
				bulletView!.widthAnchor.constraint(equalToConstant: 4),
				bulletView!.heightAnchor.constraint(equalToConstant: 4),
				bulletView!.centerYAnchor.constraint(equalTo: centerYAnchor)
			])
		} else {
			bulletView!.tintColor = AppAssets.accent
			NSLayoutConstraint.activate([
				bulletView!.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -21),
				bulletView!.widthAnchor.constraint(equalToConstant: 4),
				bulletView!.heightAnchor.constraint(equalToConstant: 4),
				bulletView!.centerYAnchor.constraint(equalTo: centerYAnchor)
			])
		}
	}
	
	private func addBarView(indentLevel: Int, hasChevron: Bool) {
		let barView = UIView()
		barView.backgroundColor = .quaternaryLabel
		barView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(barView)
		barViews.append(barView)

		var indention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			indention = CGFloat(21 - (indentLevel * 13))
			if hasChevron {
				indention = indention - 34
			}
		} else {
			indention = CGFloat(19 - (indentLevel * 10))
		}

		NSLayoutConstraint.activate([
			barView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: indention),
			barView.widthAnchor.constraint(equalToConstant: 2),
			barView.topAnchor.constraint(equalTo: topAnchor),
			barView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
	}
	
}
