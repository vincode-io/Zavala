# Spec: Zavala Behavior Suite

Intent: `planning/intent/behavior-test-suite.md` (confirmed 2026-10-09).
Harness lessons (read before writing tests or changing tools): `planning/behaviors/HARNESS-NOTES.md`.

## Objective

Build a **behavior inventory** for Zavala's editing and UI core. Each behavior is one plain sentence with a stable ID, and each one is backed by a test that fails when that behavior changes. Once the Embark-on-Mac fork starts changing code, a test run should state exactly which Zavala behaviors broke. Breaks made on purpose go into a **divergence log**, which becomes the record of how the new app differs from Zavala.

The user is the maintainer of the Embark-on-Mac fork. The suite exists so they can see what each change breaks. It is not meant to raise coverage numbers.

### Priorities

| P | Area | Examples |
|---|---|---|
| 1 | Outline editing & UI core | create/delete rows, indent/outdent, move up/down, collapse/expand (single and all), split/join on Return/Delete, notes, complete/uncomplete, cut/copy/paste/duplicate, drag-drop, keyboard navigation and focus, text formatting, title and tags field, undo/redo of all of the above |
| 2 | Settings, search/replace, tags, links, images, numbering, text zoom, history, Open Quickly, backlinks, lock, print, export, share | setting defaults and how each setting changes editor behavior; find/replace; tags; everything else outside the editing core (decided at Checkpoint C) |
| 3 | Sync / CloudKit | low priority, because this area will be heavily reworked |

Mac (Catalyst) is the primary target. iPad (simulator) runs the same L1/L2 tests from the start; L3 is Mac-only.

Embark will be built on a fork of this repo, so the suite lives here and travels with the code.

### Out of scope

- Persistence and file format (being replaced, possibly by Automerge). Export output (P2) is a separate, user-facing feature and is in scope. Tests may use OPML import as a *fixture* loader, but they never assert on file format, save timing, or migration.
- iPhone-only behavior.
- Salvaging tests from the earlier attempt (commits `bc70519e`..`97bdc514`).
- Upstream contributions. This suite serves the fork.

## What makes a test acceptable (the quality bar)

The earlier attempt failed because its tests didn't check behavior anyone cared about. Every test in this suite must meet all of the following:

1. **Behavior first.** The behavior sentence is written into `BEHAVIORS.md` *before* the test, in user terms ("Tab on a row with children indents the row and its whole subtree under the previous sibling"), not code terms ("moveRowsRight sets parent").
2. **Assert the whole observable result.** Compare the full outline shape (text, nesting, expanded and complete state) against an expected snapshot, and compare cursor/selection when the behavior involves them. Don't use partial checks like `trueLevel > 0` or `rows.count == 3` when the full shape can be stated.
3. **Prove it can fail.** Before a test is accepted, temporarily break the behavior in the production code (mutation check). Confirm that the test fails with a readable message, then revert. Record the check in the inventory (`verified: <date>`). A test that never fails is rejected.
4. **Undo is part of the behavior.** Every editing behavior that can be undone also asserts that undo restores the exact prior snapshot and redo re-applies it.
5. **Go through stable entry points.** Tests use commands, `EditorViewController` actions, or key commands, never private internals. That way they keep working through refactors that preserve the behavior.
6. **No tautologies.** No test that only exercises a mock, a getter, an initializer, or restates the implementation.
7. **Zavala bugs are asserted correctly and marked as known.** When Zavala behaves wrongly, the test asserts the correct behavior and wraps the failing part in `withKnownIssue("ZB-nnn …")`, with the bug listed under "Known Zavala bugs" in `BEHAVIORS.md`. Quirks that are odd but not wrong are tested as they are (decided 2026-10-09).

## Tech Stack

- Swift 6, Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`). XCTest is used only where XCUITest requires it.
- Xcode 27 beta at `/Applications/Xcode-beta.app` (`xcode-select` currently points at the Command Line Tools, so commands set `DEVELOPER_DIR`).
- VinOutlineKit (local SPM package, imports UIKit, so on the Mac its tests run under **Mac Catalyst**).
- Upstream's Siri integration (`AppendTextToNoteAppIntent.swift`) needs a newer SDK than Xcode 27A5209h. It's excluded on this machine only, via `EXCLUDED_SOURCE_FILE_NAMES` in the untracked `../SharedXcodeSettings/DeveloperSettings.xcconfig`. Remove that line after updating Xcode (decided 2026-10-09).
- Dependencies are pinned by `Zavala.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. A bare `swift test` resolves fresh `main` branches that don't compile on Xcode 27 beta, so don't use it.

## Commands

```sh
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer

MAC='platform=macOS,variant=Mac Catalyst'
IPAD='platform=iOS Simulator,name=iPad Pro 11-inch (M5)'

# Layer 1: model/command behaviors, on both destinations
# (verified 2026-10-09 on branch behavior-suite @ 6fb8dec1: 92 tests, 39 suites,
#  pass on Mac in ~1s and on iPad in ~23s)
xcodebuild test -project Zavala.xcodeproj -scheme VinOutlineKitTests -destination "$MAC"  CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Zavala.xcodeproj -scheme VinOutlineKitTests -destination "$IPAD" CODE_SIGNING_ALLOWED=NO

# Layer 2: app-hosted editor behaviors (target created in the plan), on both destinations
xcodebuild test -project Zavala.xcodeproj -scheme ZavalaTests -destination "$MAC"
xcodebuild test -project Zavala.xcodeproj -scheme ZavalaTests -destination "$IPAD"

# One behavior group, by Swift Testing tag/suite
xcodebuild test ... -only-testing:VinOutlineKitTests/IndentBehaviors

# Behavior report: runs L1 and L2 on Mac and iPad, maps failures to behavior IDs
tools/behavior-report.sh
# Plus the L3 smoke flows (Mac only; nobody may use the Mac while they run)
tools/behavior-report.sh --with-l3
```

## Test Layers

| Layer | Target | Covers | Drives |
|---|---|---|---|
| **L1 Model** | `VinOutlineKitTests` | Outline structure, commands, undo/redo, search, tags | `OutlineCommand` subclasses and `Outline` APIs |
| **L2 Editor** | `ZavalaTests` (app-hosted) | What the editor does with input: which command a key triggers, cursor/focus after the edit, selection, collapse UI, settings effects | `EditorViewController` actions and its `UIKeyCommand`s on a real view in a window |
| **L3 Smoke** | `ZavalaUITests` (XCUITest) | A handful of end-to-end typing flows that prove L2's assumptions hold for real keystrokes | Real keyboard events |

Most behaviors live in L1. A behavior moves up to L2 only when the editor adds something the model doesn't (cursor position, focus, which key maps to what). L2 drives the editor code directly (decided 2026-10-09). L3 stays small: about 10 flows, as a canary.

When a behavior legitimately differs between Mac and iPad (e.g. a Mac-only menu command), the inventory says so in the sentence, and the test uses a platform condition rather than being skipped.

## Project Structure

```
SPEC.md                              ← this file
planning/intent/                     ← confirmed intent docs
planning/behaviors/BEHAVIORS.md      ← the inventory (source of truth)
planning/behaviors/DIVERGENCES.md    ← intended breaks, newest first
tools/behavior-report.sh             ← runs layers, prints failures by behavior ID
VinOutlineKit/Tests/VinOutlineKitTests/
  Behaviors/<Area>Behaviors.swift    ← new L1 behavior suites, one per area
  Support/OutlineSnapshot.swift      ← outline ⇄ text DSL + assertions
  Commands/…                         ← upstream tests, kept as-is
ZavalaTests/Behaviors/…              ← L2 suites
ZavalaUITests/…                      ← L3 smoke flows
```

### BEHAVIORS.md format

```markdown
## ED: Editing — Indent / Outdent

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-010 | Tab indents a row under its previous sibling, carrying its whole subtree | L1 | IndentBehaviors/ed010 | covered · verified 2026-10-12 |
| ED-011 | Tab on the first child does nothing | L1 | IndentBehaviors/ed011 | covered · verified 2026-10-12 |
| ED-012 | After Tab, the cursor stays at the same character offset in the moved row | L2 | — | uncovered |
| ED-013 | … | | | diverged → DV-003 |
```

The status is one of `uncovered`, `covered · verified <date>`, or `diverged → DV-nnn`. IDs never change and are never reused.

### DIVERGENCES.md format

```markdown
## DV-003 · ED-013 · 2026-11-02
Zavala: Return on an empty child row outdents it.
Embark: Return on an empty child row creates a sibling.
Why: matches Embark's itinerary entry flow.
Test: updated to assert the new behavior (still ID ED-013).
```

## Code Style

Match the upstream test style: tabs, `@testable import`, and suites subclassing `VOKTestCase`. Each test's display name starts with its behavior ID. Assertions compare whole snapshots:

```swift
@Suite("Indent / Outdent")
final class IndentBehaviors: VOKTestCase {

	@Test("ED-010 Tab indents a row under its previous sibling, carrying its whole subtree")
	func ed010() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			- B
			  - B1
			""")
		defer { deleteAccountManager(accountManager) }
		let b = try outline.row(titled: "B")

		MoveRowRightCommand(actionName: "", undoManager: undoManager, delegate: self,
							outline: outline, rows: [b], rowStrings: nil).execute()

		expectOutline(outline, """
			- A
			  - B
			    - B1
			""")

		undoManager.undo()
		expectOutline(outline, """
			- A
			- B
			  - B1
			""")
	}
}
```

DSL markers: `- ` is a row, two spaces per level, `[x]` means complete, `(+)` means collapsed, and an indented `> text` line is the row's note. `makeOutline`, `row(titled:)`, and `expectOutline` are built in Task 1. A failing `expectOutline` prints both trees as a diff.

## Boundaries

**Always**
- Write the behavior sentence in `BEHAVIORS.md` before writing its test.
- Run the mutation check before marking a behavior `covered`.
- Run L1 (and L2 once it exists) before each commit; keep the suite green on the Zavala baseline.
- Commit on a feature branch, in small groups of behaviors (one area section per commit).

**Ask first**
- Adding a third-party test dependency (e.g. a snapshot library).
- Changing production code to make it testable (adding a seam/hook). Keep these minimal and list each one in the commit.
- Changing project/scheme/test-plan settings beyond adding the new targets.
- Deleting or rewriting upstream tests.

**Never**
- Mark a behavior `covered` without a recorded failing-mutation check.
- Weaken an assertion, or `.disabled` / skip a test, to get green. A failure is either a bug report or a divergence entry.
- Assert on persistence format, save timing, or CloudKit record shape (out of scope).
- Rewrite a test for an intended Embark change without adding a `DIVERGENCES.md` entry.

## Success Criteria

1. Before the suite is called done for any area, every P1 area has a complete behavior list in `BEHAVIORS.md`, with uncovered gaps listed openly.
2. 100% of P1 behaviors are `covered · verified`, with no `uncovered` rows left in P1.
3. Running `tools/behavior-report.sh` against unmodified Zavala reports all green on both Mac and iPad. Breaking any single P1 behavior by hand makes the report list that behavior's ID and sentence.
4. Spot audit: for 10 randomly chosen covered behaviors, re-running the mutation check makes the test fail. 10 out of 10 is required.
5. The full L1+L2 run on both destinations finishes in under 5 minutes, so it gets run on every change.
6. P2 (settings) follows the same process once P1 is done. P3 is inventory-only (behavior list, no tests) unless promoted.

## Starting Point

- Branch `behavior-suite` = upstream `origin/main` (`e930af3e`, fetched 2026-10-09) + cherry-picked `49d2315e` (entitlements and dependency pins; without it the project doesn't build on a personal team / Xcode 27 beta). It does not track `origin` (`vincode-io/Zavala`).
- The earlier attempt, including its `ZavalaTests` target, is preserved on branch `first-attempt` (`97bdc514`) for reference. Nothing is carried over from it, and L2 gets a fresh `ZavalaTests` target.
- Keep the 92 upstream tests. They become L1 tests without IDs. Where one overlaps a new behavior, the new ID'd test replaces its assertions, and the upstream file is left alone.
- To pick up later upstream changes: `git fetch origin && git rebase origin/main` on `behavior-suite`.

## Decisions (2026-10-09)

1. Embark is built on a fork of this repo, and the suite lives here.
2. L2 drives the editor code directly (not XCUITest-first).
3. Start from latest upstream. Earlier attempt saved on `first-attempt`.
4. iPad simulator runs L1/L2 from the start.
5. Search/replace and tags are P2.

## Open Questions

None blocking. To revisit once P1 is done: whether L3 smoke flows are worth their maintenance cost.
