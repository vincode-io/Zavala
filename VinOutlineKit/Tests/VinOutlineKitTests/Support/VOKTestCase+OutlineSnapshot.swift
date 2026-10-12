//
//  VOKTestCase+OutlineSnapshot.swift
//  VinOutlineKitTests
//

import Foundation
import Testing
@testable import VinOutlineKit

extension VOKTestCase {

	/// Creates an outline in a fresh temporary account from the DSL. Caller deletes the account manager.
	@MainActor
	func makeOutline(_ dsl: String, sourceLocation: SourceLocation = #_sourceLocation) async throws -> (Outline, AccountManager) {
		let nodes = try OutlineSnapshot.parse(dsl)
		let accountManager = buildAccountManager()
		let account = try #require(accountManager.localAccount, sourceLocation: sourceLocation)
		let document = try await account.importOPML(Data(OutlineSnapshot.opml(nodes).utf8), tags: nil)
		let outline = try #require(document.outline, sourceLocation: sourceLocation)

		outline.load()

		// OPML import ignores expansionState (it is applied before rows exist), so set collapse state directly.
		func applyCollapse(_ rows: [Row], _ nodes: [OutlineSnapshot.Node]) {
			for (row, node) in zip(rows, nodes) {
				row.isExpanded = !node.isCollapsed
				applyCollapse(row.rows, node.children)
			}
		}
		applyCollapse(outline.rows, nodes)
		OutlineSnapshot.clearEmptyTopics(outline.rows)

		outline.prepareForViewing()
		outline.incrementBeingViewedCount()

		if undoManager == nil {
			undoManager = UndoManager()
		}

		#expect(OutlineSnapshot.nodes(from: outline) == nodes,
				"Fixture did not load as written:\n\(OutlineSnapshot.render(OutlineSnapshot.nodes(from: outline)))",
				sourceLocation: sourceLocation)
		return (outline, accountManager)
	}

	/// Records a failure, showing both trees, unless the outline matches the DSL exactly.
	@MainActor
	func expectOutline(_ outline: Outline, _ expected: String, sourceLocation: SourceLocation = #_sourceLocation) {
		let actual = OutlineSnapshot.render(OutlineSnapshot.nodes(from: outline))
		let normalizedExpected: String
		do {
			normalizedExpected = try OutlineSnapshot.normalize(expected)
		} catch {
			Issue.record(error, sourceLocation: sourceLocation)
			return
		}
		if let report = OutlineSnapshot.diff(expected: normalizedExpected, actual: actual) {
			Issue.record(Comment(rawValue: report), sourceLocation: sourceLocation)
		}
	}

	/// Checks the outline right after an edit, after undo, and after redo.
	/// `knownUndoBug` names a Zavala bug (ZB-nnn in BEHAVIORS.md) that makes undo restore `before` incorrectly.
	/// The test fails if that bug is ever fixed, so the fix gets noticed.
	@MainActor
	func expectEdit(_ outline: Outline, before: String, after: String, knownUndoBug: Comment? = nil, sourceLocation: SourceLocation = #_sourceLocation) {
		expectOutline(outline, after, sourceLocation: sourceLocation)
		undoManager.undo()
		if let knownUndoBug {
			withKnownIssue(knownUndoBug, sourceLocation: sourceLocation) {
				expectOutline(outline, before, sourceLocation: sourceLocation)
			}
		} else {
			expectOutline(outline, before, sourceLocation: sourceLocation)
		}
		undoManager.redo()
		expectOutline(outline, after, sourceLocation: sourceLocation)
	}
}
