//
//  EditorHarness.swift
//  ZavalaTests
//
//  Opens a DSL-built outline in a real EditorViewController, in its own window in the
//  test host's scene, and drives it the way the keyboard does: through key commands
//  dispatched along the responder chain.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
final class EditorHarness {

	let outline: Outline
	let editor: EditorViewController
	private let window: UIWindow
	private let account: Account
	private let document: Document

	private init(outline: Outline, editor: EditorViewController, window: UIWindow, account: Account, document: Document) {
		self.outline = outline
		self.editor = editor
		self.window = window
		self.account = account
		self.document = document
	}

	/// Builds the outline in the test host's (temporary) local account and opens it in an editor.
	static func open(_ dsl: String, sourceLocation: SourceLocation = #_sourceLocation) async throws -> EditorHarness {
		#expect(TestHost.isActive, "Editor tests must run in the isolated test host", sourceLocation: sourceLocation)

		let nodes = try OutlineSnapshot.parse(dsl)
		let account = try #require(appDelegate.accountManager.localAccount, sourceLocation: sourceLocation)
		let document = try await account.importOPML(Data(OutlineSnapshot.opml(nodes).utf8), tags: nil)
		let outline = try #require(document.outline, sourceLocation: sourceLocation)

		let scene = try #require(UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
								 "No window scene in the test host", sourceLocation: sourceLocation)
		let window = UIWindow(windowScene: scene)
		window.frame = CGRect(x: 0, y: 0, width: 900, height: 700)
		let editor = EditorViewController()
		window.rootViewController = UINavigationController(rootViewController: editor)
		window.makeKeyAndVisible()

		editor.open(outline)
		applyCollapse(outline.rows, nodes)
		OutlineSnapshot.clearEmptyTopics(outline.rows)
		// open() already built the visible rows; rebuild them so collapsed children are hidden.
		// (The editor's view isn't loaded yet; it loads in edit() and reads the rebuilt rows.)
		outline.prepareForViewing()
		editor.edit()

		editor.undoManager?.groupsByEvent = false
		editor.undoManager?.removeAllActions()

		let harness = EditorHarness(outline: outline, editor: editor, window: window, account: account, document: document)
		try await harness.waitUntil("the editor is on screen with a cell for every visible row", sourceLocation: sourceLocation) {
			let section = Outline.Section.rows.rawValue
			let count = outline.shadowTable?.count ?? 0
			return editor.viewIfLoaded?.window != nil
				&& editor.collectionView.numberOfItems(inSection: section) == count
				&& (0..<count).allSatisfy { editor.collectionView.cellForItem(at: IndexPath(row: $0, section: section)) != nil }
		}
		return harness
	}

	private static func applyCollapse(_ rows: [Row], _ nodes: [OutlineSnapshot.Node]) {
		// OPML import ignores collapse state (see BEHAVIORS.md quirks); apply it like the model tests do.
		for (row, node) in zip(rows, nodes) {
			if node.isCollapsed { row.isExpanded = false }
			applyCollapse(row.rows, node.children)
		}
	}

	/// Closes the window and deletes the outline so tests don't see each other's documents.
	func close() async {
		editor.open(nil, saveCurrentOutline: false)
		window.isHidden = true
		window.rootViewController = nil
		account.deleteDocument(document)
	}

	// MARK: Cursor

	/// Puts the text cursor in a row's topic at a character offset.
	func placeCursor(in title: String, at offset: Int, sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let row = try outline.row(titled: title, sourceLocation: sourceLocation)
		editor.restoreCursorPosition(CursorCoordinates(rowID: row.id, isInNotes: false, selection: NSRange(location: offset, length: 0)))
		try await waitUntil("the cursor is in \"\(title)\" at \(offset)", sourceLocation: sourceLocation) {
			self.cursor?.rowID == row.id && self.cursor?.selection.location == offset
		}
		// Let queued UI work finish (the row's "became active" task clears selection), as it would before a key press.
		await settle()
	}

	var cursor: CursorCoordinates? {
		editor.currentCoordinates
	}

	/// Where the cursor is, as (row title, offset, in notes), for readable assertions.
	var cursorDescription: String {
		guard let cursor, let row = outline.findRow(id: cursor.rowID) else { return "no cursor" }
		return "\"\(row.topic?.string ?? "")\" @ \(cursor.selection.location)\(cursor.isInNotes ? " (note)" : "")"
	}

	/// Puts the cursor in the title, as tapping it does.
	func tapTitle(sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let titleView = try #require(firstSubview(of: EditorTitleTextView.self), "The editor has no title", sourceLocation: sourceLocation)
		await event {
			_ = titleView.becomeFirstResponder()
		}
		#expect(isTitleFocused, sourceLocation: sourceLocation)
	}

	var isTitleFocused: Bool {
		focusedTextView is EditorTitleTextView
	}

	/// The title as shown in the editor (the outline's title is saved from it once typing pauses).
	var titleText: String? {
		firstSubview(of: EditorTitleTextView.self)?.text
	}

	/// Where the cursor is in the title, or nil when the title doesn't have keyboard focus.
	var titleSelection: NSRange? {
		guard let titleView = focusedTextView as? EditorTitleTextView else { return nil }
		return titleView.selectedRange
	}

	/// Puts the cursor in the tags field, as clicking it does.
	func tapTagField(sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let tagField = try #require(firstSubview(of: EditorTagInputTextField.self), "The editor has no tags field", sourceLocation: sourceLocation)
		await event {
			_ = tagField.becomeFirstResponder()
		}
		#expect(isTagFieldFocused, sourceLocation: sourceLocation)
	}

	var isTagFieldFocused: Bool {
		UIResponder.currentFirstResponder is EditorTagInputTextField
	}

	// MARK: What's on screen

	/// Titles of the rows on screen, in order. Rows hidden by a collapsed parent or by Focus In are left out.
	var visibleTitles: [String] {
		(outline.shadowTable ?? []).map { $0.topic?.string ?? "" }
	}

	/// The topic text each row's cell actually displays, in order. Compare with `visibleTitles` to catch a cell
	/// that wasn't updated after the outline changed.
	var displayedTopics: [String] {
		let section = Outline.Section.rows.rawValue
		return (0..<(outline.shadowTable?.count ?? 0)).map { index in
			let cell = editor.collectionView.cellForItem(at: IndexPath(row: index, section: section)) as? EditorRowViewCell
			return cell?.topicTextView?.text ?? ""
		}
	}

	/// Whether a row's note text is shown under its topic.
	func isNoteShown(for title: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> Bool {
		let row = try outline.row(titled: title, sourceLocation: sourceLocation)
		let index = try #require(row.shadowTableIndex, "\"\(title)\" isn't visible", sourceLocation: sourceLocation)
		let cell = try #require(editor.collectionView.cellForItem(at: IndexPath(row: index, section: Outline.Section.rows.rawValue)) as? EditorRowViewCell,
								sourceLocation: sourceLocation)
		guard let noteView = cell.noteTextView else { return false }
		return noteView.superview != nil && !noteView.isHidden
	}

	/// Selects a range of text in a row's topic, as dragging or Shift-arrowing does.
	func selectText(in title: String, _ range: NSRange, sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let row = try outline.row(titled: title, sourceLocation: sourceLocation)
		editor.restoreCursorPosition(CursorCoordinates(rowID: row.id, isInNotes: false, selection: range))
		try await waitUntil("\"\(title)\" has the selection \(range)", sourceLocation: sourceLocation) {
			self.focusedTextView?.selectedRange == range
		}
	}

	// MARK: Row selection

	/// Selects whole rows (row-selection mode), as Esc and Shift-click do: text editing ends and the rows are selected.
	func selectRows(_ titles: [String], sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let rows = try titles.map { try outline.row(titled: $0, sourceLocation: sourceLocation) }
		focusedTextView?.resignFirstResponder()
		editor.collectionView.deselectAll()
		for row in rows {
			let index = try #require(row.shadowTableIndex, "\"\(row.topic?.string ?? "")\" isn't visible", sourceLocation: sourceLocation)
			editor.collectionView.selectItem(at: IndexPath(row: index, section: Outline.Section.rows.rawValue), animated: false, scrollPosition: [])
		}
		await settle()
		#expect(selectedTitles == titles, sourceLocation: sourceLocation)
	}

	/// Titles of the selected rows, in display order. Empty when not in row-selection mode.
	var selectedTitles: [String] {
		let indexPaths = editor.collectionView.indexPathsForSelectedItems?.sorted() ?? []
		return indexPaths.compactMap { indexPath in
			guard indexPath.section == Outline.Section.rows.rawValue,
				  let shadowTable = outline.shadowTable, indexPath.row < shadowTable.count else { return nil }
			return shadowTable[indexPath.row].topic?.string ?? ""
		}
	}

	// MARK: Mouse

	/// Clicks a row's disclosure triangle, with or without Option held.
	/// (Tests can't build the click's UIEvent, so this enters where the triangle's action hands off to the editor.)
	func clickDisclosure(of title: String, option: Bool = false, sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let row = try outline.row(titled: title, sourceLocation: sourceLocation)
		await event {
			editor.editorRowToggleDisclosure(rowID: row.id, applyToAll: option)
		}
	}

	// MARK: Keyboard

	/// Types text into the focused row the way the keyboard does, so Return ("\n") and Tab go through
	/// the row's own handling.
	func type(_ text: String, sourceLocation: SourceLocation = #_sourceLocation) async throws {
		if let textField = UIResponder.currentFirstResponder as? UITextField {
			await typeInField(textField, text)
			return
		}
		let textView = try #require(focusedTextView, "Nothing has keyboard focus", sourceLocation: sourceLocation)
		// Keyboard input asks the delegate first; that's where rows handle Return and Tab.
		await event {
			let allowed = textView.delegate?.textView?(textView, shouldChangeTextIn: textView.selectedRange, replacementText: text) ?? true
			if allowed {
				textView.insertText(text)
			}
		}
	}

	/// Typing into a one-line field (the tags field): Return goes to the field's delegate, as the keyboard sends it.
	private func typeInField(_ textField: UITextField, _ text: String) async {
		await event {
			if text == "\n" {
				_ = textField.delegate?.textFieldShouldReturn?(textField)
				return
			}
			let range = textField.selectedTextRange.map {
				NSRange(location: textField.offset(from: textField.beginningOfDocument, to: $0.start),
						length: textField.offset(from: $0.start, to: $0.end))
			} ?? NSRange(location: 0, length: 0)
			let allowed = textField.delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: text) ?? true
			if allowed {
				textField.insertText(text)
			}
		}
	}

	/// The Delete key (delete backward) in the focused row.
	func deleteBackward(sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let textView = try #require(focusedTextView, "Nothing has keyboard focus", sourceLocation: sourceLocation)
		await event {
			textView.deleteBackward()
		}
	}

	/// Cut, Copy, or Paste (Cmd-X/C/V): the standard edit action, sent to whatever has focus, as the Edit menu does.
	func edit(_ action: Selector, sourceLocation: SourceLocation = #_sourceLocation) async throws {
		await event {
			let handled = UIApplication.shared.sendAction(action, to: nil, from: nil, for: nil)
			#expect(handled, "No responder handled \(action)", sourceLocation: sourceLocation)
		}
	}

	/// Paste (Cmd-V), waiting for the outline to change: the editor reads the clipboard asynchronously.
	func pasteAndWait(sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let before = OutlineSnapshot.render(OutlineSnapshot.nodes(from: outline))
		try await edit(#selector(UIResponderStandardEditActions.paste(_:)), sourceLocation: sourceLocation)
		try await waitUntil("the paste changes the outline", sourceLocation: sourceLocation) {
			OutlineSnapshot.render(OutlineSnapshot.nodes(from: self.outline)) != before
		}
	}

	/// Empties the system clipboard. Clipboard tests use the real one (decided 2026-10-09), so they start and end with this.
	static func clearClipboard() {
		UIPasteboard.general.items = []
	}

	/// The focused row's text as on screen, as Markdown (formatting is visible here before it's saved).
	var focusedTextMarkdown: String? {
		(focusedTextView as? EditorRowTextView)?.attributedText.markdownRepresentation
	}

	/// The undo manager of the focused row's text, which is where formatting is recorded (Cmd-Z goes here first).
	var focusedUndoManager: UndoManager? {
		focusedTextView?.undoManager
	}

	/// Saves the focused row's typed text to the outline, as Zavala does when typing pauses or editing ends.
	/// Until then, text typed or inserted by a key command is only in the text view.
	func commitTyping(sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let textView = try #require(focusedTextView as? EditorRowTextView, "No row text has keyboard focus", sourceLocation: sourceLocation)
		await event {
			textView.saveText()
		}
	}

	/// Dispatches the key command offered for this key by the focused view or any responder above it
	/// (row text view, editor, …), the way a key press reaches it.
	/// Records a failure if nothing offers the key right now.
	func press(_ input: String, _ modifiers: UIKeyModifierFlags = [], sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let command = try #require(offeredKeyCommand(input, modifiers),
								   "Nothing offers a key command for \(Self.describe(input, modifiers)) right now",
								   sourceLocation: sourceLocation)
		try await send(command, sourceLocation: sourceLocation)
	}

	/// Presses a menu shortcut, as defined on the app's menu commands, and checks it reaches a responder.
	func pressMenu(_ input: String, _ modifiers: UIKeyModifierFlags = [], sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let menuCommands = Mirror(reflecting: appDelegate!).children.compactMap { $0.value as? UIKeyCommand }
		let command = try #require(menuCommands.first(where: { $0.input == input && $0.modifierFlags == modifiers }),
								   "No menu command uses \(Self.describe(input, modifiers))",
								   sourceLocation: sourceLocation)
		try await send(command, sourceLocation: sourceLocation)
	}

	/// Presses and releases an arrow key (or any key that isn't a key command), delivered to the editor, which
	/// handles Up and Down from the title and the tags field in `pressesBegan`. In the app the press reaches the
	/// editor up the responder chain from the focused text. The harness can't send it through the text: on iPad a
	/// text field passes presses to the on-screen keyboard, which loops forever without a real event (a stack
	/// overflow). What that skips is the tags field's own handling, which only acts while tag suggestions are shown.
	func pressKey(_ keyCode: UIKeyboardHIDUsage, _ modifiers: UIKeyModifierFlags = [], sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let presses: Set<UIPress> = [SimulatedPress(SimulatedKey(keyCode, modifiers))]
		await event {
			editor.pressesBegan(presses, with: nil)
			editor.pressesEnded(presses, with: nil)
		}
	}

	func offersKey(_ input: String, _ modifiers: UIKeyModifierFlags = []) -> Bool {
		offeredKeyCommand(input, modifiers) != nil
	}

	private func offeredKeyCommand(_ input: String, _ modifiers: UIKeyModifierFlags) -> UIKeyCommand? {
		var responder: UIResponder? = focusedTextView ?? editor
		while let current = responder {
			if let command = current.keyCommands?.first(where: { $0.input == input && $0.modifierFlags == modifiers }) {
				return command
			}
			responder = current.next
		}
		return nil
	}

	private func send(_ command: UIKeyCommand, sourceLocation: SourceLocation) async throws {
		let action = try #require(command.action, sourceLocation: sourceLocation)
		await event {
			let handled = UIApplication.shared.sendAction(action, to: nil, from: command, for: nil)
			#expect(handled, "No responder handled \(Self.describe(command.input ?? "", command.modifierFlags))", sourceLocation: sourceLocation)
		}
	}

	private var focusedTextView: UITextView? {
		firstSubview(of: UITextView.self, where: { $0.isFirstResponder })
	}

	private func firstSubview<T: UIView>(of type: T.Type, where matches: (T) -> Bool = { _ in true }) -> T? {
		func find(_ view: UIView) -> T? {
			if let match = view as? T, matches(match) { return match }
			for subview in view.subviews {
				if let found = find(subview) { return found }
			}
			return nil
		}
		return find(window)
	}

	private static func describe(_ input: String, _ modifiers: UIKeyModifierFlags) -> String {
		var parts = [String]()
		if modifiers.contains(.command) { parts.append("Cmd") }
		if modifiers.contains(.control) { parts.append("Ctrl") }
		if modifiers.contains(.alternate) { parts.append("Option") }
		if modifiers.contains(.shift) { parts.append("Shift") }
		switch input {
		case "\t": parts.append("Tab")
		case "\r", "\n": parts.append("Return")
		case UIKeyCommand.inputEscape: parts.append("Esc")
		default: parts.append(input)
		}
		return parts.joined(separator: "-")
	}

	// MARK: Waiting

	/// Runs one simulated key press as its own user event, with its own undo group, as in the app.
	/// (In the app UIKit groups undo by run-loop event; a test never finishes an event, so the harness
	/// turns that off in `open` and groups explicitly here.)
	/// UIKit's text system can also leave a typing group open; an event boundary closes every open group.
	private func event(_ body: () throws -> Void) async rethrows {
		closeUndoGroups()
		// Formatting is recorded on the focused text's own undo manager, which groups by run-loop event too.
		// A test never ends an event, so that manager gets the same one-group-per-key-press treatment.
		let textUndoManager = focusedUndoManager
		textUndoManager?.groupsByEvent = false
		editor.undoManager?.beginUndoGrouping()
		textUndoManager?.beginUndoGrouping()
		defer {
			endUndoGroups(textUndoManager)
			endUndoGroups(editor.undoManager)
		}
		try body()
		await settle()
	}

	private func endUndoGroups(_ undoManager: UndoManager?) {
		guard let undoManager else { return }
		while undoManager.groupingLevel > 0 {
			undoManager.endUndoGrouping()
		}
	}

	/// Closes open groups before a key press starts, on the editor's manager and on the focused text's.
	private func closeUndoGroups() {
		endUndoGroups(editor.undoManager)
		endUndoGroups(focusedUndoManager)
	}

	/// Lets pending UI work (collection view updates, responder changes) run.
	func settle() async {
		for _ in 0..<3 {
			window.layoutIfNeeded()
			await Task.yield()
			try? await Task.sleep(for: .milliseconds(10))
		}
	}

	/// Waits on state, never on time alone. Fails after `timeout`.
	func waitUntil(_ what: String, timeout: Duration = .seconds(5), sourceLocation: SourceLocation = #_sourceLocation, _ condition: () -> Bool) async throws {
		let deadline = ContinuousClock.now + timeout
		while !condition() {
			if ContinuousClock.now > deadline {
				Issue.record("Timed out waiting until \(what)", sourceLocation: sourceLocation)
				throw CancellationError()
			}
			await settle()
		}
	}
}

/// A hardware key, for `pressKey`. UIKit has no public way to make one, so these override the properties it reads.
private final class SimulatedKey: UIKey {
	private let simulatedKeyCode: UIKeyboardHIDUsage
	private let simulatedModifierFlags: UIKeyModifierFlags

	init(_ keyCode: UIKeyboardHIDUsage, _ modifierFlags: UIKeyModifierFlags) {
		simulatedKeyCode = keyCode
		simulatedModifierFlags = modifierFlags
		super.init()
	}

	required init?(coder: NSCoder) {
		nil
	}

	override var keyCode: UIKeyboardHIDUsage { simulatedKeyCode }
	override var modifierFlags: UIKeyModifierFlags { simulatedModifierFlags }
	override var characters: String { "" }
	override var charactersIgnoringModifiers: String { "" }
}

private final class SimulatedPress: UIPress {
	private let simulatedKey: UIKey

	init(_ key: UIKey) {
		simulatedKey = key
		super.init()
	}

	override var key: UIKey? { simulatedKey }
}
