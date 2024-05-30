//
//  EditorTagInputTextField.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit
import VinOutlineKit

protocol EditorTagInputTextFieldDelegate: AnyObject {
	var editorTagInputTextFieldUndoManager: UndoManager? { get }
	var editorTagInputTextFieldTags: [Tag]? { get }
	func didBecomeActive(_ : EditorTagInputTextField)
	func textDidChange(_ : EditorTagInputTextField)
	func didReturn(_ : EditorTagInputTextField)
	func createTag(_ : EditorTagInputTextField, name: String)
}

class EditorTagInputTextField: SearchTextField, EditorTextInput {

	#if targetEnvironment(macCatalyst)
	@objc(_focusRingType)
	var focusRingType: UInt {
		return 1 //NSFocusRingTypeNone
	}
	#endif
	
	weak var editorDelegate: EditorTagInputTextFieldDelegate?
	
	override var undoManager: UndoManager? {
		guard let textViewUndoManager = super.undoManager, let controllerUndoManager = editorDelegate?.editorTagInputTextFieldUndoManager else { return nil }
		if stackedUndoManager == nil {
			stackedUndoManager = StackedUndoManger(mainUndoManager: textViewUndoManager, fallBackUndoManager: controllerUndoManager)
		}
		return stackedUndoManager
	}
	
	override var keyCommands: [UIKeyCommand]? {
		let tab = UIKeyCommand(action: #selector(createTag), input: "\t")
		tab.wantsPriorityOverSystemBehavior = true

		let esc = UIKeyCommand(action: #selector(closeSuggestionList), input: UIKeyCommand.inputEscape)
		esc.wantsPriorityOverSystemBehavior = true

		return [tab, esc]
	}
	
	private var stackedUndoManager: UndoManager?
	private static let dropDelegate = OutlineTextDropDelegate()

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.textDropDelegate = Self.dropDelegate
		self.delegate = self
		
		self.placeholder = .tagDataEntryPlaceholder
		self.borderStyle = .none
		self.autocorrectionType = .no
		self.tableXOffset = -8
		self.tableYOffset = 3
		self.textColor = .secondaryLabel

		self.itemSelectionHandler = { [weak self] (filteredResults: [SearchTextFieldItem], index: Int) in
			guard let self else { return }
			self.text = nil
			self.invalidateIntrinsicContentSize()
			let name = filteredResults[index].title
			self.editorDelegate?.createTag(self, name: name)
		}
		
		#if targetEnvironment(macCatalyst)
		let appleColorPreferencesChangedNotification = Notification.Name(rawValue: "AppleColorPreferencesChangedNotification")
		DistributedNotificationCenter.default.addObserver(self, selector: #selector(appleColorPreferencesChanged(_:)), name: appleColorPreferencesChangedNotification, object: nil)
		#endif

		updateTintColor()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@discardableResult
	override func becomeFirstResponder() -> Bool {
		resetFilterStrings()
		let result = super.becomeFirstResponder()
		CursorCoordinates.clearLastKnownCoordinates()
		editorDelegate?.didBecomeActive(self)
		return result
	}
	
	override func textFieldDidChange() {
		super.textFieldDidChange()
		invalidateIntrinsicContentSize()
		editorDelegate?.textDidChange(self)
	}
	
	// MARK: Actions
	
	@objc func createTag() {
		activateSelection()
		
		guard let name = text, !name.isEmpty else { return }
		
		text = nil
		invalidateIntrinsicContentSize()
		editorDelegate?.createTag(self, name: name)
		resetFilterStrings()
	}
	
	@objc func closeSuggestionList() {
		super.clearSelection()
		super.hideResultsList()
	}
	
}

extension EditorTagInputTextField: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard !isSelecting else {
			activateSelection()
			return false
		}
		
		if let name = text, !name.isEmpty {
			text = nil
			invalidateIntrinsicContentSize()
			editorDelegate?.createTag(self, name: name)
			resetFilterStrings()
		}
		
		editorDelegate?.didReturn(self)
		
		return false
	}
	
}

// MARK: Helpers

private extension EditorTagInputTextField {
	
	func resetFilterStrings() {
		let filterStrings = editorDelegate?.editorTagInputTextFieldTags?.compactMap({ $0.name }) ?? [String]()
		self.filterStrings(filterStrings)
	}
	
	func updateTintColor() {
		if UIColor.accentColor.isDefaultAccentColor {
			tintColor = .brightenedDefaultAccentColor
		} else {
			tintColor = .accentColor
		}
	}

	@objc func appleColorPreferencesChanged(_ note: Notification? = nil) {
		updateTintColor()
	}
	
}
