//
//  EditorContentView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

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
		textView.attributedText = NSAttributedString(string: "", attributes: [.foregroundColor: AppAssets.textColor])
		
		addSubview(textView)
		textView.translatesAutoresizingMaskIntoConstraints = false

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
		guard appliedConfiguration != configuration, let editorItem = configuration.editorItem else { return }
		appliedConfiguration = configuration
		
		// Don't overlay the default attributed text field for new Headlines
		if let attrText = editorItem.attributedText {
			textView.attributedText = attrText
		}

		let adjustedIndentionWidth: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			if configuration.isChevronShowing {
				adjustedIndentionWidth = configuration.indentationWidth - 12
			} else {
				adjustedIndentionWidth = configuration.indentationWidth + 16
			}
		} else {
			adjustedIndentionWidth = configuration.indentationWidth
		}
		
		textView.removeConstraintsIncludingOwnedBySuperview()
		NSLayoutConstraint.activate([
			textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedIndentionWidth),
			textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
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
		appliedConfiguration.delegate?.textChanged(item: appliedConfiguration.editorItem!, attributedText: textView.attributedText)
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		switch text {
		case "\n":
			appliedConfiguration.delegate?.createHeadline(item: appliedConfiguration.editorItem!)
			return false
		default:
			return true
		}
	}
	
}

// MARK: EditorTextViewDelegate

extension EditorContentView: EditorTextViewDelegate {
	
	var item: EditorItem? {
		return appliedConfiguration.editorItem
	}
	
	func deleteHeadline(_: EditorTextView) {
		appliedConfiguration.delegate?.deleteHeadline(item: appliedConfiguration.editorItem!)
	}
	
	func createHeadline(_: EditorTextView) {
		appliedConfiguration.delegate?.createHeadline(item: appliedConfiguration.editorItem!)
	}
	
	func indent(_: EditorTextView, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.indent(item: appliedConfiguration.editorItem!, attributedText: attributedText)
	}
	
	func outdent(_: EditorTextView, attributedText: NSAttributedString) {
		appliedConfiguration.delegate?.outdent(item: appliedConfiguration.editorItem!, attributedText: attributedText)
	}
	
	func moveUp(_: EditorTextView) {
		appliedConfiguration.delegate?.moveUp(item: appliedConfiguration.editorItem!)
	}
	
	func moveDown(_: EditorTextView) {
		appliedConfiguration.delegate?.moveDown(item: appliedConfiguration.editorItem!)
	}
	
}

// MARK: Helpers

extension EditorContentView {
	
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
				bulletView!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 21),
				bulletView!.widthAnchor.constraint(equalToConstant: 4),
				bulletView!.heightAnchor.constraint(equalToConstant: 4),
				bulletView!.centerYAnchor.constraint(equalTo: centerYAnchor)
			])
		} else {
			bulletView!.tintColor = AppAssets.accentColor
			NSLayoutConstraint.activate([
				bulletView!.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
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
			indention = CGFloat(22 - (indentLevel * 13))
			if hasChevron {
				indention = indention - 29
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
