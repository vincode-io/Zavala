//
//  EditorTagInputTextField.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit
import Templeton

protocol EditorTagInputTextFieldDelegate: class {
	var editorTagInputTextFieldUndoManager: UndoManager? { get }
	var editorTagInputTextFieldIsAddShowing: Bool { get }
	var editorTagInputTextFieldTags: [Tag]? { get }
	func invalidateLayout(_: EditorTagInputTextField)
	func didBecomeActive(_ : EditorTagInputTextField)
	func showAdd(_ : EditorTagInputTextField)
	func hideAdd(_ : EditorTagInputTextField)
	func createRow(_ : EditorTagInputTextField)
	func createTag(_ : EditorTagInputTextField, name: String)
}

class EditorTagInputTextField: SearchTextField {

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
		let keys = [
			UIKeyCommand(action: #selector(createTag(_:)), input: "\t"),
			UIKeyCommand(action: #selector(clearSelection(_:)), input: UIKeyCommand.inputEscape)
		]
		return keys
	}
	
	private var stackedUndoManager: UndoManager?
	private static let dropDelegate = OutlineTextDropDelegate()

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.textDropDelegate = Self.dropDelegate
		self.delegate = self
		
		self.placeholder = L10n.tag
		self.borderStyle = .none
		self.autocorrectionType = .no
		self.tableXOffset = -8
		self.tableYOffset = 3
		self.textColor = .secondaryLabel

		self.itemSelectionHandler = { [weak self] (filteredResults: [SearchTextFieldItem], index: Int) in
			guard let self = self else { return }
			self.text = nil
			self.invalidateIntrinsicContentSize()
			let name = filteredResults[index].title
			self.editorDelegate?.hideAdd(self)
			self.editorDelegate?.createTag(self, name: name)
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@discardableResult
	override func becomeFirstResponder() -> Bool {
		editorDelegate?.didBecomeActive(self)
		resetFilterStrings()
		return super.becomeFirstResponder()
	}
	
	override func textFieldDidChange() {
		super.textFieldDidChange()
		invalidateIntrinsicContentSize()
		editorDelegate?.invalidateLayout(self)
		
		let textIsEmpty = text?.isEmpty ?? true
		let isAddShowing = (editorDelegate?.editorTagInputTextFieldIsAddShowing ?? false)
		if textIsEmpty && isAddShowing {
			editorDelegate?.hideAdd(self)
		} else if !textIsEmpty && !isAddShowing {
			editorDelegate?.showAdd(self)
		}
		
	}

	@objc func createTag(_ sender: Any) {
		activateSelection()
		
		guard let name = text, !name.isEmpty else { return }
		
		text = nil
		invalidateIntrinsicContentSize()
		editorDelegate?.hideAdd(self)
		editorDelegate?.createTag(self, name: name)
		resetFilterStrings()
	}
	
	@objc func clearSelection(_ sender: Any) {
		clearSelection()
	}
}

extension EditorTagInputTextField: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard !isShowingResults else {
			activateSelection()
			return false
		}
		
		if let name = text, !name.isEmpty {
			text = nil
			invalidateIntrinsicContentSize()
			editorDelegate?.hideAdd(self)
			editorDelegate?.createTag(self, name: name)
			resetFilterStrings()
		}
		
		editorDelegate?.createRow(self)
		
		return false
	}
	
}

// MARK: Helpers

extension EditorTagInputTextField {
	
	private func resetFilterStrings() {
		let filterStrings = editorDelegate?.editorTagInputTextFieldTags?.compactMap({ $0.name }) ?? [String]()
		self.filterStrings(filterStrings)
	}
	
}
