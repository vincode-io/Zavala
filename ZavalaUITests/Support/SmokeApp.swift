//
//  SmokeApp.swift
//  ZavalaUITests
//
//  Launches Zavala in its isolated test state and drives it with real keystrokes (L3).
//  The outline is read back the way a user could: select every row, copy, and read the clipboard,
//  which holds the rows as a Markdown list (tabs for nesting, ~~text~~ for completed rows).
//

import Foundation
import Testing
import UIKit
import XCTest

@MainActor
final class SmokeApp {

	let app = XCUIApplication()

	/// Launches the app with a temporary accounts folder and settings store, and no iCloud.
	/// (A UI-tested app doesn't get the scheme's environment, so the switch is passed here.)
	init() {
		app.launchEnvironment["ZAVALA_TEST_HOST"] = "1"
		// Don't restore the last run's window: it shows an outline from a temp folder that's gone.
		app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
		app.launch()
		// Keys sent before the window is ready are lost, so wait for the sidebar's "All" row.
		_ = allOutlinesRow.waitForExistence(timeout: 10)
	}

	/// The sidebar's "All" row; its value is the number of outlines.
	var allOutlinesRow: XCUIElement {
		app.cells.matching(NSPredicate(format: "label == 'All'")).firstMatch
	}

	/// A new outline, from the toolbar's New Outline button: click its title, type the title, then Return through
	/// the tags field to its first row (ED-291, ED-292), and wait until that row has the cursor.
	/// (Right after launch, the sidebar sometimes takes keyboard focus after the new outline's title has it, and
	/// a Cmd-N sent then can be lost. Clicking, as a user would, makes the start of every flow the same.)
	static func newOutline(title: String = "Smoke", sourceLocation: SourceLocation = #_sourceLocation) throws -> SmokeApp {
		let smoke = SmokeApp()
		let app = smoke.app
		// Every flow starts in the isolated state: a temporary accounts folder with no outlines in it.
		#expect(smoke.allOutlinesRow.value as? String == "0", "The app isn't running in its isolated test state", sourceLocation: sourceLocation)
		// Right after launch a click on New Outline is sometimes lost (no outline appears), so click once more if
		// none appears. This is setup, not a behavior under test.
		let untitled = app.cells.matching(NSPredicate(format: "label == '(No Title)'")).firstMatch
		app.buttons["New Outline"].firstMatch.click()
		if !untitled.waitForExistence(timeout: 5) {
			app.buttons["New Outline"].firstMatch.click()
		}
		try smoke.require(untitled.waitForExistence(timeout: 5), "the new outline is listed", sourceLocation: sourceLocation)
		app.textViews.firstMatch.click()
		app.typeText("\(title)\n\n")
		// If any of that was lost, the first row won't have the cursor.
		try smoke.waitForFocus(on: app.textViews.element(boundBy: 1), "the new outline's first row has keyboard focus", sourceLocation: sourceLocation)
		return smoke
	}

	func type(_ text: String) {
		app.typeText(text)
	}

	func key(_ key: XCUIKeyboardKey, _ modifiers: XCUIElement.KeyModifierFlags = []) {
		app.typeKey(key, modifierFlags: modifiers)
	}

	func key(_ key: String, _ modifiers: XCUIElement.KeyModifierFlags = []) {
		app.typeKey(key, modifierFlags: modifiers)
	}

	/// The text view with keyboard focus (a row's topic or note, or the title), if any.
	var focusedTextView: XCUIElement? {
		let focused = app.textViews.matching(NSPredicate(format: "hasKeyboardFocus == true"))
		return focused.count > 0 ? focused.firstMatch : nil
	}

	/// The outline as a Markdown list, read by selecting all rows and copying them.
	/// Leaves the editor in row-selection mode with every row selected.
	func outlineMarkdown(sourceLocation: SourceLocation = #_sourceLocation) async throws -> String {
		// Esc leaves text editing for row selection (ED-236); from a note it may take a second press.
		for _ in 0..<2 where focusedTextView != nil {
			key(.escape)
		}
		#expect(focusedTextView == nil, "Couldn't leave text editing to select rows", sourceLocation: sourceLocation)
		key("a", .command)
		UIPasteboard.general.items = []
		key("c", .command)
		let deadline = ContinuousClock.now + .seconds(5)
		while (UIPasteboard.general.string ?? "").isEmpty {
			if ContinuousClock.now > deadline {
				Issue.record("Nothing was copied", sourceLocation: sourceLocation)
				return ""
			}
			try await Task.sleep(for: .milliseconds(50))
		}
		let markdown = UIPasteboard.general.string ?? ""
		UIPasteboard.general.items = []
		return markdown
	}

	/// The rows on screen as the outline DSL ("- Alpha" with two spaces per level), read without pressing any key,
	/// so it doesn't end editing or add undo steps the way `outlineMarkdown` can. Text views after the title are
	/// the rows (don't use with notes showing); nesting comes from how far each one is indented.
	var screenOutline: String {
		let rows = app.textViews.allElementsBoundByIndex.dropFirst()
		let indents = Array(Set(rows.map { Int($0.frame.minX.rounded()) })).sorted()
		return rows.map { row in
			let level = indents.firstIndex(of: Int(row.frame.minX.rounded())) ?? 0
			let text = row.value as? String ?? ""
			return String(repeating: "  ", count: level) + (text.isEmpty ? "-" : "- \(text)")
		}.joined(separator: "\n")
	}

	func waitForFocus(on element: XCUIElement, _ what: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
		let focused = NSPredicate(format: "hasKeyboardFocus == true")
		let expectation = XCTNSPredicateExpectation(predicate: focused, object: element)
		try require(XCTWaiter.wait(for: [expectation], timeout: 5) == .completed, what, sourceLocation: sourceLocation)
	}

	/// Records a failure with what's on screen, and stops the flow.
	func require(_ condition: Bool, _ what: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
		guard !condition else { return }
		Issue.record("Timed out waiting until \(what); outlines: \(allOutlinesRow.value ?? "?"), text views: \(app.textViews.allElementsBoundByIndex.map { $0.value ?? "" })",
					 sourceLocation: sourceLocation)
		print("SMOKE-TREE-BEGIN\n\(app.windows.firstMatch.debugDescription)\nSMOKE-TREE-END")
		throw CancellationError()
	}

	func close() {
		app.terminate()
	}
}
