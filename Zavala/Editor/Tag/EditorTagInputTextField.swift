//
//  EditorTagInputTextField.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit

protocol EditorTagInputTextFieldDelegate: class {
	var editorTagInputTextFieldUndoManager: UndoManager? { get }
	func invalidateLayout(_: EditorTagInputTextField)
	func didBecomeActive(_ : EditorTagInputTextField)
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
			UIKeyCommand(action: #selector(createTag(_:)), input: "\t")
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
		self.filterStrings(["Home", "Work", "Project", "Zavala"])
		self.startVisible = true
		self.interactedWith = true
		self.tableXOffset = -8
		self.tableYOffset = 3
		
		if traitCollection.userInterfaceStyle == .dark {
			self.theme = .darkTheme()
		}
		
		self.itemSelectionHandler = { [weak self] (filteredResults: [SearchTextFieldItem], index: Int) in
			guard let self = self else { return }
			let name = filteredResults[index].title
			self.editorDelegate?.createTag(self, name: name)
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@discardableResult
	override func becomeFirstResponder() -> Bool {
		editorDelegate?.didBecomeActive(self)
		return super.becomeFirstResponder()
	}
	
	override func textFieldDidChange() {
		super.textFieldDidChange()
		invalidateIntrinsicContentSize()
		editorDelegate?.invalidateLayout(self)
	}

	@objc func createTag(_ sender: Any) {
		guard let name = text, !name.isEmpty else { return }
		text = nil
		invalidateIntrinsicContentSize()
		editorDelegate?.createTag(self, name: name)
	}
	
}

extension EditorTagInputTextField: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		editorDelegate?.createRow(self)
		return false
	}
	
}
