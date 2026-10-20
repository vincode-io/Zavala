//
//  SmokeFlows.swift
//  ZavalaUITests
//
//  End-to-end smoke flows (L3), Mac only: real keystrokes into the running app, to show that what the L1 and L2
//  tests drive directly also happens for real key presses. Each flow is named with the IDs of the behaviors it
//  confirms. The cursor's position is shown by typing "X" and reading where it landed.
//

import Foundation
import Testing
import XCTest

@MainActor
@Suite("Smoke flows with real keystrokes", .serialized)
struct SmokeFlows {

	@Test("ED-290 ED-291 ED-292 ED-030 A new outline: type its title, Return through the tags field into the first row, Return between rows")
	func newOutline() async throws {
		let smoke = try SmokeApp.newOutline(title: "Smoke")
		defer { smoke.close() }

		smoke.type("Alpha\nBravo\nCharlie")

		let outline = try await smoke.outlineMarkdown()
		#expect(outline == "* Alpha\n* Bravo\n* Charlie")
		let listed = smoke.app.cells.matching(NSPredicate(format: "label == 'Smoke'")).firstMatch
		#expect(listed.waitForExistence(timeout: 5), "The outline isn't listed under its typed title")
	}

	@Test("ED-010 ED-012 ED-015 Tab indents a row and keeps the cursor in it; Shift-Tab outdents")
	func indentOutdent() async throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha\nBravo\tX\nCharlie")
		smoke.key(.tab, .shift)

		let outline = try await smoke.outlineMarkdown()
		#expect(outline == "* Alpha\n\t* BravoX\n* Charlie")
	}

	@Test("ED-050 Return in the middle of a row splits it, and the cursor goes to the start of the new row")
	func split() async throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("AlphaBravo")
		for _ in 0..<5 { smoke.key(.leftArrow) }
		smoke.type("\nX")

		let outline = try await smoke.outlineMarkdown()
		#expect(outline == "* Alpha\n* XBravo")
	}

	@Test("ED-054 ED-057 Delete at the start of a row joins it onto the row above, with the cursor at the join")
	func join() async throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha\nBravo")
		smoke.key(.leftArrow, .command)
		smoke.key(.delete)
		smoke.type("X")

		let outline = try await smoke.outlineMarkdown()
		#expect(outline == "* AlphaXBravo")
	}

	@Test("ED-070 Delete in an empty row deletes it and puts the cursor at the end of the row above")
	func deleteEmptyRow() async throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha\n")
		smoke.key(.delete)
		smoke.type("X")

		let outline = try await smoke.outlineMarkdown()
		#expect(outline == "* AlphaX")
	}

	@Test("ED-035 Return in an empty last child outdents it")
	func returnOutdents() async throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha\nBravo\t\n\nCharlie")

		let outline = try await smoke.outlineMarkdown()
		#expect(outline == "* Alpha\n\t* Bravo\n* Charlie")
	}

	@Test("ED-130 Cmd-Return marks the current row complete; pressing it again marks it incomplete")
	func complete() async throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha\nBravo")
		smoke.key(.return, .command)
		smoke.key(.upArrow)
		smoke.key(.return, .command)
		smoke.key(.return, .command)

		let outline = try await smoke.outlineMarkdown()
		#expect(outline == "* Alpha\n* ~~Bravo~~")
	}

	@Test("ED-150 Ctrl-- gives the row a note and puts the cursor in it")
	func addNote() async throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha")
		smoke.key("-", .control)
		smoke.type("A note")

		let outline = try await smoke.outlineMarkdown()
		#expect(outline == "* Alpha\n\n  A note\n\n")
	}

	@Test("ED-231 ED-232 Up arrow and Ctrl-P move the cursor up a row, keeping its position")
	func moveUp() async throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha\nBravo\nCharlie")
		smoke.key(.leftArrow, .command)
		smoke.key(.upArrow)
		smoke.key("p", .control)
		smoke.type("X")

		let outline = try await smoke.outlineMarkdown()
		#expect(outline == "* XAlpha\n* Bravo\n* Charlie")
	}

	@Test("ED-236 ED-072 Esc selects the current row; Delete Rows deletes it with its children")
	func deleteRows() async throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha\nBravo\nB1\t\n")
		smoke.key(.tab, .shift)
		smoke.type("Charlie")
		smoke.key(.upArrow)
		smoke.key(.upArrow)
		smoke.key(.escape)
		smoke.key(.delete, [.shift, .command])

		let outline = try await smoke.outlineMarkdown()
		#expect(outline == "* Alpha\n* Charlie")
	}

	@Test("ED-252 ED-042 After typing in a row and pressing Return, Cmd-Z removes the new row and keeps the typing; the next Cmd-Z undoes the typing")
	func undoTypingThenReturn() throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha\nBravo\nCharlie")
		smoke.key(.upArrow)
		smoke.key(.rightArrow, .command)
		smoke.type("!\n")
		#expect(smoke.screenOutline == "- Alpha\n- Bravo!\n-\n- Charlie")

		smoke.key("z", .command)
		#expect(smoke.screenOutline == "- Alpha\n- Bravo!\n- Charlie")

		smoke.key("z", .command)
		#expect(smoke.screenOutline == "- Alpha\n- Bravo\n- Charlie")
	}

	@Test("ED-252 ED-010 After typing in a row and pressing Tab, Cmd-Z undoes the indent only; the next Cmd-Z undoes the typing")
	func undoTypingThenTab() throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha\nBravo\nCharlie")
		smoke.key(.upArrow)
		smoke.key(.rightArrow, .command)
		smoke.type("!")
		smoke.key(.tab)
		#expect(smoke.screenOutline == "- Alpha\n  - Bravo!\n- Charlie")

		smoke.key("z", .command)
		#expect(smoke.screenOutline == "- Alpha\n- Bravo!\n- Charlie")
	}

	@Test("ED-251 Shift-Cmd-Z redoes undone edits in order")
	func redo() throws {
		let smoke = try SmokeApp.newOutline()
		defer { smoke.close() }

		smoke.type("Alpha\nBravo\nCharlie")
		smoke.key(.upArrow)
		smoke.key(.tab)
		smoke.key(.downArrow)
		smoke.key(.tab)
		#expect(smoke.screenOutline == "- Alpha\n  - Bravo\n  - Charlie")

		smoke.key("z", .command)
		smoke.key("z", .command)
		#expect(smoke.screenOutline == "- Alpha\n- Bravo\n- Charlie")

		smoke.key("z", [.shift, .command])
		#expect(smoke.screenOutline == "- Alpha\n  - Bravo\n- Charlie")
		smoke.key("z", [.shift, .command])
		#expect(smoke.screenOutline == "- Alpha\n  - Bravo\n  - Charlie")
	}
}
