//
//  EditorTitleTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import VinOutlineKit

@MainActor
protocol EditorTitleTextViewDelegate: AnyObject {
	var editorTitleTextViewUndoManager: UndoManager? { get }
	func didBecomeActive(_: EditorTitleTextView)
}

class EditorTitleTextView: UITextView, EditorTextInput {
	
	weak var editorDelegate: EditorTitleTextViewDelegate?

	override var undoManager: UndoManager? {
		guard let textViewUndoManager = super.undoManager, let controllerUndoManager = editorDelegate?.editorTitleTextViewUndoManager else { return nil }
		if stackedUndoManager == nil {
			stackedUndoManager = StackedUndoManger(mainUndoManager: textViewUndoManager, fallBackUndoManager: controllerUndoManager)
		}
		return stackedUndoManager
	}
	
	var isSelecting: Bool {
		return !(selectedTextRange?.isEmpty ?? true)
	}

	private var stackedUndoManager: UndoManager?
	private static let dropDelegate = OutlineTextDropDelegate()

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		textDropDelegate = Self.dropDelegate

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
		let result = super.becomeFirstResponder()
		CursorCoordinates.clearLastKnownCoordinates()
		editorDelegate?.didBecomeActive(self)
		return result
	}
	
}

private extension EditorTitleTextView {
	
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
