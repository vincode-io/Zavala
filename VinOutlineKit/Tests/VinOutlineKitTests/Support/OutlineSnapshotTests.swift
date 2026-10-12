//
//  OutlineSnapshotTests.swift
//  VinOutlineKitTests
//
//  Tests for the test DSL itself. If these are wrong, every behavior test is wrong.
//

import Foundation
import Testing
@testable import VinOutlineKit

private let snapshotSamples: [String] = [
	"""
	- A
	""",
	"""
	- A
	- B
	- C
	""",
	"""
	- A
	  - A1
	    - A1a
	  - A2
	- B
	""",
	"""
	- [x] Done
	- (+) Folded
	  - Hidden child
	- [x] (+) Both
	  - Child
	""",
	"""
	-
	- [x]
	- (+)
	  - Child of an empty collapsed row
	""",
	"""
	- Has note
	  > first line
	  >
	  > third line
	  - Child with note
	    > child note
	- Ampersand & <angle> "quotes"
	""",
]

@Suite("Outline snapshot DSL")
final class OutlineSnapshotTests: VOKTestCase {

	@Test("Each sample loads into a real outline and renders back unchanged", arguments: snapshotSamples)
	func roundTripsThroughOutline(_ sample: String) async throws {
		let (outline, accountManager) = try await makeOutline(sample)
		defer { deleteAccountManager(accountManager) }

		#expect(OutlineSnapshot.render(OutlineSnapshot.nodes(from: outline)) == sample)
		expectOutline(outline, sample)
	}

	@Test("Parsing builds the expected tree")
	func parsesStructure() throws {
		let nodes = try OutlineSnapshot.parse("""
			- [x] (+) A
			  > note
			  - B
			- C
			""")
		#expect(nodes == [
			.init(topic: "A", isComplete: true, isCollapsed: true, note: ["note"],
				  children: [.init(topic: "B")]),
			.init(topic: "C"),
		])
	}

	@Test("Trailing spaces and blank lines don't affect comparison")
	func normalizesFormatting() throws {
		#expect(try OutlineSnapshot.normalize("\n- A   \n\n  - B\n\n") == "- A\n  - B")
	}

	@Test("Malformed DSL is rejected", arguments: [
		"- A\n   - odd indent",
		"- A\n    - skips a level",
		"> note without a row",
		"- A\nplain text",
	])
	func rejectsMalformed(_ text: String) {
		#expect(throws: OutlineSnapshot.ParseError.self) { try OutlineSnapshot.parse(text) }
	}

	@Test("A mismatch reports both trees and marks the differing lines")
	func diffReport() throws {
		let report = try #require(OutlineSnapshot.diff(expected: "- A\n  - B", actual: "- A\n- B"))
		#expect(report == """
			Outline does not match.

			Expected:
			    - A
			  ≠   - B

			Actual:
			    - A
			  ≠ - B
			""")
		#expect(OutlineSnapshot.diff(expected: "- A", actual: "- A") == nil)
	}

	@Test("expectOutline records a failure when the outline differs")
	func expectOutlineFails() async throws {
		let (outline, accountManager) = try await makeOutline("- A\n- B")
		defer { deleteAccountManager(accountManager) }

		withKnownIssue {
			expectOutline(outline, "- A\n  - B")
		}
	}

	@Test("row(titled:) finds a nested row and fails on missing or duplicate titles")
	func rowLookup() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - Target
			- Dup
			- Dup
			""")
		defer { deleteAccountManager(accountManager) }

		#expect(try outline.row(titled: "Target").topic?.string == "Target")
		withKnownIssue {
			_ = try outline.row(titled: "Missing")
		}
		withKnownIssue {
			_ = try outline.row(titled: "Dup")
		}
	}
}
