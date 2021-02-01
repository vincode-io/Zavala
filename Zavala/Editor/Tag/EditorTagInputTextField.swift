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
	func didBecomeInactive(_ : EditorTagInputTextField)
	func createRow(_ : EditorTagInputTextField)
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
	
	private var stackedUndoManager: UndoManager?
	private static let dropDelegate = OutlineTextDropDelegate()

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		textDropDelegate = Self.dropDelegate
		delegate = self
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@discardableResult
	override func becomeFirstResponder() -> Bool {
		editorDelegate?.didBecomeActive(self)
		return super.becomeFirstResponder()
	}
	
	@discardableResult
	override func resignFirstResponder() -> Bool {
		editorDelegate?.didBecomeInactive(self)
		return super.resignFirstResponder()
	}
	
	override func textFieldDidChange() {
		super.textFieldDidChange()
		invalidateIntrinsicContentSize()
		editorDelegate?.invalidateLayout(self)
	}

}

extension EditorTagInputTextField: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		editorDelegate?.createRow(self)
		return false
	}
	
}
