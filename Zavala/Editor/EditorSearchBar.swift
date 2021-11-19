//
//  EditorSearchBar.swift
//  NetNewsWire
//
//  Created by Brian Sanders on 5/8/20.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import UIKit

@objc protocol SearchBarDelegate: NSObjectProtocol {
	@objc optional func nextWasPressed(_ searchBar: EditorSearchBar)
	@objc optional func previousWasPressed(_ searchBar: EditorSearchBar)
	@objc optional func doneWasPressed(_ searchBar: EditorSearchBar)
	@objc optional func searchBar(_ searchBar: EditorSearchBar, textDidChange: String)
}


@IBDesignable final class EditorSearchBar: UIStackView {
	var searchField: UISearchTextField!
	var nextButton: UIButton!
	var prevButton: UIButton!
	var doneButton: UIButton!
	var background: UIView!
	
	weak private var resultsLabel: UILabel!
	private var searchWorkItem: DispatchWorkItem?

	var resultsCount: Int = 0 {
		didSet {
			updateUI()
		}
	}
	var selectedResult: Int = 1 {
		didSet {
			updateUI()
		}
	}
	
	weak var delegate: SearchBarDelegate?
	
	override var keyCommands: [UIKeyCommand]? {
		return [UIKeyCommand(title: "Exit Find", action: #selector(donePressed(_:)), input: UIKeyCommand.inputEscape)]
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	required init(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	
	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		layer.backgroundColor = AppAssets.barBackgroundColor.cgColor
		isOpaque = true
		NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextField.textDidChangeNotification, object: searchField)
	}
	
	private func updateUI() {
		if resultsCount > 0 {
			let format = NSLocalizedString("%d of %d", comment: "Results selection and count")
			resultsLabel.text = String.localizedStringWithFormat(format, selectedResult, resultsCount)
		} else {
			resultsLabel.text = ""
		}
		
		nextButton.isEnabled = resultsCount > 1
		prevButton.isEnabled = resultsCount > 1
	}
	
	@discardableResult override func becomeFirstResponder() -> Bool {
		searchField.becomeFirstResponder()
	}
	
	@discardableResult override func resignFirstResponder() -> Bool {
		searchField.resignFirstResponder()
	}
	
	override var isFirstResponder: Bool {
		searchField.isFirstResponder
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	func commonInit() {
		isLayoutMarginsRelativeArrangement = true
		alignment = .center
		spacing = 8
		
		if traitCollection.userInterfaceIdiom == .mac {
			layoutMargins.top = 0
			layoutMargins.bottom = 0
		}
		
		layoutMargins.left = 8
		layoutMargins.right = 8

		doneButton = UIButton(type: .custom)
		doneButton.setTitle(L10n.done, for: .normal)
		doneButton.isAccessibilityElement = true
		doneButton.addTarget(self, action: #selector(donePressed), for: .touchUpInside)
		doneButton.isEnabled = true
		doneButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
		doneButton.setTitleColor(UIColor.label, for: .normal)
		if traitCollection.userInterfaceIdiom == .mac {
			doneButton.setBackgroundImage(UIColor.systemGray4.asImage(), for: .highlighted)
			doneButton.layer.borderWidth = 1.0
			doneButton.layer.borderColor = UIColor.tertiaryLabel.cgColor
			doneButton.layer.cornerRadius = 5
			doneButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
		} else {
			doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
		}
		addArrangedSubview(doneButton)
		
		let resultsLabel = UILabel()
		searchField = EnhancedSearchTextField()
		searchField.autocapitalizationType = .none
		searchField.autocorrectionType = .no
		searchField.returnKeyType = .search
		searchField.delegate = self
		if traitCollection.userInterfaceIdiom == .mac {
			searchField.heightAnchor.constraint(equalToConstant: 30).isActive = true
		}
		
		resultsLabel.font = .systemFont(ofSize: UIFont.smallSystemFontSize)
		resultsLabel.textColor = .secondaryLabel
		resultsLabel.text = ""
		resultsLabel.textAlignment = .right
		resultsLabel.adjustsFontSizeToFitWidth = true
		searchField.rightView = resultsLabel
		searchField.rightViewMode = .always
		
		self.resultsLabel = resultsLabel
		addArrangedSubview(searchField)
		
		prevButton = UIButton(type: .custom)
		prevButton.isEnabled = false
		prevButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
		prevButton.accessibilityLabel = L10n.previousResult
		prevButton.isAccessibilityElement = true
		prevButton.addTarget(self, action: #selector(previousPressed), for: .touchUpInside)
		addArrangedSubview(prevButton)
		
		nextButton = UIButton(type: .custom)
		nextButton.isEnabled = false
		nextButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
		nextButton.accessibilityLabel = L10n.nextResult
		nextButton.isAccessibilityElement = true
		nextButton.addTarget(self, action: #selector(nextPressed), for: .touchUpInside)
		addArrangedSubview(nextButton)
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		if traitCollection.userInterfaceIdiom == .mac {
			if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? false {
				doneButton.setBackgroundImage(UIColor.systemGray4.asImage(), for: .highlighted)
				doneButton.layer.borderColor = UIColor.tertiaryLabel.cgColor
			}
		}
	}
	
}

private extension EditorSearchBar {
	
	@objc func textDidChange(_ notification: Notification) {
		searchWorkItem?.cancel()
		searchWorkItem = DispatchWorkItem { [weak self] in
			guard let self = self else { return }
			self.delegate?.searchBar?(self, textDidChange: self.searchField.text ?? "")
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: searchWorkItem!)
		
		if searchField.text?.isEmpty ?? true {
			searchField.rightViewMode = .never
		} else {
			searchField.rightViewMode = .always
		}
	}
	
	@objc func nextPressed() {
		delegate?.nextWasPressed?(self)
	}
	
	@objc func previousPressed() {
		delegate?.previousWasPressed?(self)
	}
	
	@objc func donePressed(_ _: Any? = nil) {
		delegate?.doneWasPressed?(self)
	}
}

extension EditorSearchBar: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		delegate?.nextWasPressed?(self)
		return false
	}
}
