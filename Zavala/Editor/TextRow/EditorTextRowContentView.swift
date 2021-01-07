//
//  EditorTextRowContentView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

class EditorTextRowContentView: UIView, UIContentView {

	let topicTextView = EditorTextRowTopicTextView()
	var noteTextView: EditorTextRowNoteTextView?
	var barViews = [UIView]()

	private var isDisclosed = false
	
	private lazy var disclosureIndicator: UIButton = {
		let indicator = UIButton()
		indicator.setImage(AppAssets.disclosure, for: .normal)
		#if targetEnvironment(macCatalyst)
		indicator.addTarget(self, action: #selector(toggleDisclosure(_:)), for: UIControl.Event.touchDown)
		#else
		indicator.addTarget(self, action: #selector(toggleDisclosure(_:)), for: UIControl.Event.touchUpInside)
		#endif

		indicator.tintColor = .systemGray2
		indicator.imageView?.contentMode = .center
		indicator.imageView?.clipsToBounds = false
		indicator.translatesAutoresizingMaskIntoConstraints = false
		indicator.addInteraction(UIPointerInteraction(delegate: self))
		
		let dimension: CGFloat = traitCollection.userInterfaceIdiom == .mac ? 25 : 44
		NSLayoutConstraint.activate([
			indicator.widthAnchor.constraint(equalToConstant: dimension),
			indicator.heightAnchor.constraint(equalToConstant: dimension)
		])
		
		return indicator
	}()
	
	private lazy var bullet: UIView = {
		let bulletView = UIImageView(image: AppAssets.bullet)
		
		NSLayoutConstraint.activate([
			bulletView.widthAnchor.constraint(equalToConstant: 4),
			bulletView.heightAnchor.constraint(equalToConstant: 4)
		])

		bulletView.tintColor = .quaternaryLabel
		bulletView.translatesAutoresizingMaskIntoConstraints = false
		
		return bulletView
	}()
	
	var appliedConfiguration: EditorTextRowContentConfiguration!
	
	var textRowStrings: TextRowStrings {
		return TextRowStrings(topic: topicTextView.attributedText, note: noteTextView?.attributedText)
	}
	
	init(configuration: EditorTextRowContentConfiguration) {
		super.init(frame: .zero)

		topicTextView.editorDelegate = self
		topicTextView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(topicTextView)

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
			guard let newConfig = newValue as? EditorTextRowContentConfiguration else { return }
			apply(configuration: newConfig)
		}
	}
	
	private func apply(configuration: EditorTextRowContentConfiguration) {
		guard appliedConfiguration != configuration else { return }
		appliedConfiguration = configuration

		configureTopicTextView(configuration: configuration)
		configureNoteTextView(configuration: configuration)

		let adjustedLeadingIndention: CGFloat
		let adjustedTrailingIndention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			adjustedLeadingIndention = configuration.indentationWidth + 8
			adjustedTrailingIndention = -8
		} else {
			if traitCollection.horizontalSizeClass != .compact {
				adjustedLeadingIndention = configuration.indentationWidth + 12
				adjustedTrailingIndention = -8
			} else {
				adjustedLeadingIndention = configuration.indentationWidth
				adjustedTrailingIndention = -25
			}
		}

		topicTextView.removeConstraintsOwnedBySuperview()
		
		if let noteTextView = noteTextView {
			noteTextView.removeConstraintsOwnedBySuperview()
			NSLayoutConstraint.activate([
				topicTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				topicTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				topicTextView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
				topicTextView.bottomAnchor.constraint(equalTo: noteTextView.topAnchor, constant: -4),
				noteTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				noteTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				noteTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)

			])
		} else {
			NSLayoutConstraint.activate([
				topicTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: adjustedLeadingIndention),
				topicTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: adjustedTrailingIndention),
				topicTextView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
				topicTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
			])
		}

		bullet.removeFromSuperview()
		disclosureIndicator.removeFromSuperview()
		
		if configuration.row?.rows?.isEmpty ?? true {
			addSubview(bullet)
			
			let baseLineConstant = 0 - (OutlineFont.topicCapHeight - 4) / 2
			if traitCollection.horizontalSizeClass != .compact {
				let indentAdjustment: CGFloat = traitCollection.userInterfaceIdiom == .mac ? 1 : 3
				NSLayoutConstraint.activate([
					bullet.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: configuration.indentationWidth + indentAdjustment),
					bullet.firstBaselineAnchor.constraint(equalTo: topicTextView.firstBaselineAnchor, constant: baseLineConstant)
				])
			} else {
				NSLayoutConstraint.activate([
					bullet.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
					bullet.firstBaselineAnchor.constraint(equalTo: topicTextView.firstBaselineAnchor, constant: baseLineConstant)
				])
			}
		} else {
			addSubview(disclosureIndicator)

			let baseLineConstant: CGFloat
			if traitCollection.userInterfaceIdiom == .mac {
				baseLineConstant = 0 - (OutlineFont.topicCapHeight - 6) / 2
			} else {
				baseLineConstant = 0 - (OutlineFont.topicCapHeight - 12) / 2
			}

			if traitCollection.horizontalSizeClass != .compact {
				let indentAdjustment: CGFloat = traitCollection.userInterfaceIdiom == .mac ? -9 : -16
				NSLayoutConstraint.activate([
					disclosureIndicator.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: configuration.indentationWidth + indentAdjustment),
					disclosureIndicator.firstBaselineAnchor.constraint(equalTo: topicTextView.firstBaselineAnchor, constant: baseLineConstant)
				])
			} else {
				NSLayoutConstraint.activate([
					disclosureIndicator.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0),
					disclosureIndicator.firstBaselineAnchor.constraint(equalTo: topicTextView.firstBaselineAnchor, constant: baseLineConstant)
				])
			}
			
			setDisclosure(isExpanded: configuration.row?.isExpanded ?? true, animated: false)
		}
		
		if configuration.indentionLevel < barViews.count {
			for i in (configuration.indentionLevel..<barViews.count).reversed() {
				barViews[i].removeFromSuperview()
				barViews.remove(at: i)
			}
		}

		addBarViews()
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
			for i in 0..<barViews.count {
				barViews[i].removeFromSuperview()
			}
			barViews.removeAll()
			addBarViews()
		}
	}
	
}

// MARK: EditorTextViewDelegate

extension EditorTextRowContentView: EditorTextRowTopicTextViewDelegate {
	
	var editorRowTopicTextViewUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorTextRowUndoManager
	}
	
	var editorRowTopicTextViewTextRowStrings: TextRowStrings {
		return textRowStrings
	}
	
	func invalidateLayout(_: EditorTextRowTopicTextView) {
		invalidateIntrinsicContentSize()
		appliedConfiguration.delegate?.editorTextRowLayoutEditor()
	}
	
	func didBecomeActive(_: EditorTextRowTopicTextView) {
		appliedConfiguration.delegate?.editorTextRowTextFieldDidBecomeActive()
	}

	func textChanged(_: EditorTextRowTopicTextView, row: Row, isInNotes: Bool, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorTextRowTextChanged(row: row, textRowStrings: textRowStrings, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func deleteRow(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowDeleteRow(row, textRowStrings: textRowStrings)
	}
	
	func createRow(_: EditorTextRowTopicTextView, beforeRow: Row) {
		appliedConfiguration.delegate?.editorTextRowCreateRow(beforeRow: beforeRow)
	}
	
	func createRow(_: EditorTextRowTopicTextView, afterRow: Row) {
		appliedConfiguration.delegate?.editorTextRowCreateRow(afterRow: afterRow, textRowStrings: textRowStrings)
	}
	
	func indentRow(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowIndentRow(row, textRowStrings: textRowStrings)
	}
	
	func outdentRow(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowOutdentRow(row, textRowStrings: textRowStrings)
	}
	
	func splitRow(_: EditorTextRowTopicTextView, row: Row, topic: NSAttributedString, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorTextRowSplitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func createRowNote(_: EditorTextRowTopicTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowCreateRowNote(row, textRowStrings: textRowStrings)
	}
	
	func editLink(_: EditorTextRowTopicTextView, _ link: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorTextRowEditLink(link, range: range)
	}
	
}

extension EditorTextRowContentView: EditorTextRowNoteTextViewDelegate {

	var editorRowNoteTextViewUndoManager: UndoManager? {
		return appliedConfiguration.delegate?.editorTextRowUndoManager
	}
	
	var editorRowNoteTextViewTextRowStrings: TextRowStrings {
		return textRowStrings
	}
	
	func invalidateLayout(_: EditorTextRowNoteTextView) {
		invalidateIntrinsicContentSize()
		appliedConfiguration.delegate?.editorTextRowLayoutEditor()
	}
	
	func didBecomeActive(_: EditorTextRowNoteTextView) {
		appliedConfiguration.delegate?.editorTextRowTextFieldDidBecomeActive()
	}
	
	func textChanged(_: EditorTextRowNoteTextView, row: Row, isInNotes: Bool, cursorPosition: Int) {
		appliedConfiguration.delegate?.editorTextRowTextChanged(row: row, textRowStrings: textRowStrings, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func deleteRowNote(_: EditorTextRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowDeleteRowNote(row, textRowStrings: textRowStrings)
	}
	
	func moveCursorTo(_: EditorTextRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowMoveCursorTo(row: row)
	}
	
	func moveCursorDown(_: EditorTextRowNoteTextView, row: Row) {
		appliedConfiguration.delegate?.editorTextRowMoveCursorDown(row: row)
	}
	
	func editLink(_: EditorTextRowNoteTextView, _ link: String?, range: NSRange) {
		appliedConfiguration.delegate?.editorTextRowEditLink(link, range: range)
	}
	
}

// MARK: UIPointerInteractionDelegate

extension EditorTextRowContentView: UIPointerInteractionDelegate {
	func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
		var pointerStyle: UIPointerStyle? = nil

		if let interactionView = interaction.view {
			
			let parameters = UIPreviewParameters()
			let newBounds = CGRect(x: 8, y: 8, width: 28, height: 28)
			let visiblePath = UIBezierPath(roundedRect: newBounds, cornerRadius: 10)
			parameters.visiblePath = visiblePath
			
			let targetedPreview = UITargetedPreview(view: interactionView, parameters: parameters)
			pointerStyle = UIPointerStyle(effect: UIPointerEffect.automatic(targetedPreview))
		}
		return pointerStyle
	}
}

// MARK: Helpers

extension EditorTextRowContentView {

	@objc func toggleDisclosure(_ sender: Any?) {
		guard let row = appliedConfiguration.row else { return }
		setDisclosure(isExpanded: !isDisclosed, animated: true)
		appliedConfiguration.delegate?.editorTextRowToggleDisclosure(row: row)
	}
	
	private func setDisclosure(isExpanded: Bool, animated: Bool) {
		guard isDisclosed != isExpanded else { return }
		isDisclosed = isExpanded

		if isDisclosed {
			disclosureIndicator.accessibilityLabel = L10n.collapse
			if animated {
				UIView.animate(withDuration: 0.15) {
					self.disclosureIndicator.transform = CGAffineTransform(rotationAngle: 1.570796)
				}
			} else {
				disclosureIndicator.transform = CGAffineTransform(rotationAngle: 1.570796)
			}
		} else {
			disclosureIndicator.accessibilityLabel = L10n.expand
			if animated {
				UIView.animate(withDuration: 0.15) {
					self.disclosureIndicator.transform = CGAffineTransform(rotationAngle: 0)
				}
			} else {
				disclosureIndicator.transform = CGAffineTransform(rotationAngle: 0)
			}
		}
	}
	
	@objc func swipedLeft(_ sender: UISwipeGestureRecognizer) {
		guard let row = appliedConfiguration.row else { return }
		appliedConfiguration.delegate?.editorTextRowOutdentRow(row, textRowStrings: textRowStrings)
	}
	
	@objc func swipedRight(_ sender: UISwipeGestureRecognizer) {
		guard let row = appliedConfiguration.row else { return }
		appliedConfiguration.delegate?.editorTextRowIndentRow(row, textRowStrings: textRowStrings)
	}
	
	private func configureTopicTextView(configuration: EditorTextRowContentConfiguration) {
		topicTextView.row = configuration.row
		
		let topic = configuration.topic ?? NSAttributedString(string: "")
		
		var attrs = [NSAttributedString.Key : Any]()
		if configuration.isComplete || configuration.isAncestorComplete {
			attrs[.foregroundColor] = UIColor.tertiaryLabel
		} else {
			attrs[.foregroundColor] = UIColor.label
		}
		
		if configuration.isComplete {
			attrs[.strikethroughStyle] = 1
			attrs[.strikethroughColor] = UIColor.tertiaryLabel
		} else {
			attrs[.strikethroughStyle] = 0
		}

		// This is a bit of a hack to make sure that the reused UITextView gets cleared out for the empty attributed string
		if topic.length < 1 {
			let mutableAttrText = NSMutableAttributedString(string: " ")
			let range = NSRange(location: 0, length: mutableAttrText.length)
			attrs[.font] = OutlineFont.topic
			mutableAttrText.addAttributes(attrs, range: range)
			topicTextView.attributedText = mutableAttrText
			topicTextView.attributedText = configuration.topic
		} else {
			let mutableAttrText = NSMutableAttributedString(attributedString: topic)
			let range = NSRange(location: 0, length: mutableAttrText.length)
			mutableAttrText.addAttributes(attrs, range: range)
			mutableAttrText.replaceFont(with: OutlineFont.topic)
			topicTextView.attributedText = mutableAttrText
		}

	}
	
	private func configureNoteTextView(configuration: EditorTextRowContentConfiguration) {
		guard !configuration.isNotesHidden, let noteAttributedText = configuration.row?.textRow?.note else {
			noteTextView?.removeFromSuperview()
			noteTextView = nil
			return
		}
		
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.foregroundColor] = UIColor.secondaryLabel
		
		let mutableAttrText = NSMutableAttributedString(attributedString: noteAttributedText)
		let range = NSRange(location: 0, length: mutableAttrText.length)
		mutableAttrText.replaceFont(with: OutlineFont.note)
		mutableAttrText.addAttributes(attrs, range: range)
		
		if noteTextView == nil {
			noteTextView = EditorTextRowNoteTextView()
			noteTextView!.editorDelegate = self
			noteTextView!.translatesAutoresizingMaskIntoConstraints = false
			addSubview(noteTextView!)
		}
		
		noteTextView!.row = configuration.row
		noteTextView!.attributedText = mutableAttrText
	}
	
	private func addBarViews() {
		let configuration = appliedConfiguration as EditorTextRowContentConfiguration
		
		if configuration.indentionLevel > 0 {
			let barViewsCount = barViews.count
			for i in (1...configuration.indentionLevel) {
				if i > barViewsCount {
					addBarView(indentLevel: i, indentWidth: configuration.indentationWidth, hasChevron: configuration.isChevronShowing)
				}
			}
		}
	}
	
	private func addBarView(indentLevel: Int, indentWidth: CGFloat, hasChevron: Bool) {
		let barView = UIView()
		barView.backgroundColor = AppAssets.accessory
		barView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(barView)
		barViews.append(barView)

		var indention: CGFloat
		if traitCollection.userInterfaceIdiom == .mac {
			indention = CGFloat(28 - ((indentLevel + 1) * 13))
		} else {
			if traitCollection.horizontalSizeClass != .compact {
				indention = CGFloat(30 - ((indentLevel + 1) * 13))
			} else {
				indention = CGFloat(19 - (indentLevel * 10))
			}
		}

		NSLayoutConstraint.activate([
			barView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: indention),
			barView.widthAnchor.constraint(equalToConstant: 2),
			barView.topAnchor.constraint(equalTo: topAnchor),
			barView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
	}
	
}
