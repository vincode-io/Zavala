//
//  OutlineSnapshot.swift
//  VinOutlineKitTests
//
//  Builds outlines from an indented text DSL and compares live outlines against it.
//  Shared by VinOutlineKitTests and ZavalaTests (symlinked); keep it free of target-specific code.
//
//  DSL, two spaces per level:
//      - Topic              a row
//      -                    an empty row (no text at all, like a row just created in the app)
//      - [x] Topic          a completed row
//      - (+) Topic          a collapsed row
//      - [x] (+) Topic      both, always in this order
//        > note text        the note of the row above (one line per note line)
//

import Foundation
import Testing
@testable import VinOutlineKit

enum OutlineSnapshot {

	struct Node: Equatable {
		var topic: String
		var isComplete = false
		var isCollapsed = false
		var note: [String] = []
		var children: [Node] = []
	}

	struct ParseError: Error, CustomStringConvertible {
		let line: Int
		let message: String
		var description: String { "Outline DSL line \(line): \(message)" }
	}

	// MARK: Parse

	static func parse(_ text: String) throws -> [Node] {
		var roots = [Node]()
		// Path of indices from roots to the most recently added row at each level.
		var path = [Int]()

		func withNode(at path: [Int], _ body: (inout Node) -> Void) {
			func descend(_ nodes: inout [Node], _ path: ArraySlice<Int>) {
				let i = path.first!
				if path.count == 1 {
					body(&nodes[i])
				} else {
					descend(&nodes[i].children, path.dropFirst())
				}
			}
			descend(&roots, path[...])
		}

		for (offset, rawLine) in text.components(separatedBy: "\n").enumerated() {
			let lineNumber = offset + 1
			let line = rawLine.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
			guard !line.isEmpty else { continue }

			let spaces = line.prefix(while: { $0 == " " }).count
			guard spaces % 2 == 0 else {
				throw ParseError(line: lineNumber, message: "indent must be a multiple of two spaces")
			}
			let level = spaces / 2
			let content = line.dropFirst(spaces)

			if content.hasPrefix("> ") || content == ">" {
				guard level >= 1, path.count == level else {
					throw ParseError(line: lineNumber, message: "a note must be indented one level under its row")
				}
				let noteLine = content == ">" ? "" : String(content.dropFirst(2))
				withNode(at: path) { $0.note.append(noteLine) }
				continue
			}

			guard content == "-" || content.hasPrefix("- ") else {
				throw ParseError(line: lineNumber, message: "expected \"- \" or \"> \"")
			}
			guard level <= path.count else {
				throw ParseError(line: lineNumber, message: "indented more than one level past the previous row")
			}

			// Markers may end the line (trailing spaces are trimmed), e.g. "- [x]" is a completed empty row.
			var rest = content.dropFirst(min(2, content.count))
			var node = Node(topic: "")
			if rest == "[x]" || rest.hasPrefix("[x] ") {
				node.isComplete = true
				rest = rest.dropFirst(min(4, rest.count))
			}
			if rest == "(+)" || rest.hasPrefix("(+) ") {
				node.isCollapsed = true
				rest = rest.dropFirst(min(4, rest.count))
			}
			node.topic = String(rest)

			path = Array(path.prefix(level))
			if path.isEmpty {
				roots.append(node)
				path = [roots.count - 1]
			} else {
				var newIndex = 0
				withNode(at: path) {
					$0.children.append(node)
					newIndex = $0.children.count - 1
				}
				path.append(newIndex)
			}
		}

		return roots
	}

	// MARK: Render

	static func render(_ nodes: [Node]) -> String {
		var lines = [String]()
		func visit(_ node: Node, level: Int) {
			let indent = String(repeating: "  ", count: level)
			var line = indent + "- "
			if node.isComplete { line += "[x] " }
			if node.isCollapsed { line += "(+) " }
			line += node.topic
			lines.append(line.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression))
			for noteLine in node.note {
				lines.append(indent + "  " + (noteLine.isEmpty ? ">" : "> " + noteLine))
			}
			node.children.forEach { visit($0, level: level + 1) }
		}
		nodes.forEach { visit($0, level: 0) }
		return lines.joined(separator: "\n")
	}

	/// Imported empty rows get an empty topic, but rows created in the app have none, and Zavala treats the
	/// two differently (ZB-002). Fixtures use the app's form.
	@MainActor
	static func clearEmptyTopics(_ rows: [Row]) {
		for row in rows {
			if row.topic?.length == 0 { row.topic = nil }
			clearEmptyTopics(row.rows)
		}
	}

	@MainActor
	static func nodes(from outline: Outline) -> [Node] {
		func node(from row: Row) -> Node {
			let note = row.note?.string
			return Node(topic: row.topic?.string ?? "",
						isComplete: row.isComplete ?? false,
						isCollapsed: !row.isExpanded,
						note: note.map { $0.components(separatedBy: "\n") } ?? [],
						children: row.rows.map(node(from:)))
		}
		return outline.rows.map(node(from:))
	}

	/// Normalizes a DSL string so that formatting differences (trailing spaces, blank lines) don't count.
	static func normalize(_ text: String) throws -> String {
		return render(try parse(text))
	}

	// MARK: OPML (fixture loading only — tests never assert on OPML)

	static func opml(_ nodes: [Node]) -> String {
		func escape(_ s: String) -> String {
			s.replacingOccurrences(of: "&", with: "&amp;")
				.replacingOccurrences(of: "<", with: "&lt;")
				.replacingOccurrences(of: ">", with: "&gt;")
				.replacingOccurrences(of: "\"", with: "&quot;")
				.replacingOccurrences(of: "\n", with: "&#10;")
		}
		var body = ""
		func visit(_ node: Node, level: Int) {
			body += String(repeating: "  ", count: level + 2) + "<outline text=\"\(escape(node.topic))\""
			if !node.note.isEmpty {
				body += " _note=\"\(escape(node.note.joined(separator: "\n")))\""
			}
			if node.isComplete {
				body += " _status=\"checked\""
			}
			if node.children.isEmpty {
				body += "/>\n"
			} else {
				body += ">\n"
				node.children.forEach { visit($0, level: level + 1) }
				body += String(repeating: "  ", count: level + 2) + "</outline>\n"
			}
		}
		nodes.forEach { visit($0, level: 0) }
		return """
			<?xml version="1.0" encoding="UTF-8"?>
			<opml version="2.0">
			<head>
			  <title>Behavior Fixture</title>
			</head>
			<body>
			\(body)</body>
			</opml>
			"""
	}

	// MARK: Diff

	/// Returns nil when equal, otherwise a side-by-side report of both trees with differing lines marked.
	static func diff(expected: String, actual: String) -> String? {
		guard expected != actual else { return nil }
		let e = expected.components(separatedBy: "\n")
		let a = actual.components(separatedBy: "\n")
		var report = ["Outline does not match.", "", "Expected:"]
		for (i, line) in e.enumerated() {
			report.append((i < a.count && a[i] == line ? "    " : "  ≠ ") + line)
		}
		report.append("")
		report.append("Actual:")
		for (i, line) in a.enumerated() {
			report.append((i < e.count && e[i] == line ? "    " : "  ≠ ") + line)
		}
		return report.joined(separator: "\n")
	}
}

extension Outline {

	/// The single row whose topic is exactly `title`, anywhere in the outline.
	func row(titled title: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> Row {
		var matches = [Row]()
		func visit(_ row: Row) {
			if (row.topic?.string ?? "") == title { matches.append(row) }
			row.rows.forEach(visit)
		}
		rows.forEach(visit)
		return try #require(matches.count == 1 ? matches.first : nil,
							"Expected exactly one row titled \"\(title)\", found \(matches.count)",
							sourceLocation: sourceLocation)
	}
}
