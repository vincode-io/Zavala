# Behavior Suite: Harness Notes

Lessons learned while building the suite, each one hit for real at least once. Read this before writing tests, changing the harness, or changing the tools. Rules live in `SPEC.md`; this file is about how to get the machinery to tell the truth.

Each entry: **symptom → cause → what to do.**

---

## 1. Building and running

- **`swift test` fails to build dependencies.** It resolves VinOutlineKit's `branch: main` dependencies fresh, and those don't compile on Xcode 27 beta. → Always use `xcodebuild` with the project's pinned `Package.resolved` (the `run_tests` function in `tools/behavior-common.sh`).
- **"Unable to resolve module dependency: 'UIKit'".** VinOutlineKit imports UIKit. → On Mac, run it as Mac Catalyst (`platform=macOS,variant=Mac Catalyst`), never plain macOS.
- **`xcodebuild` says it needs Xcode.** `xcode-select` points at the Command Line Tools. → The scripts set `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`.
- **"Setting '…' should be in an xcconfig file".** Zavala's build checks (`tools/VerifyNoBS.swift`) reject build settings in `project.pbxproj`. → New targets get an `xcconfig/Zavala_*_target.xcconfig` and empty `buildSettings` in the project file. Xcode's "New Target" writes settings into the project file, so move them every time.
- **Xcode edits unrelated schemes when you add a target.** It added the new test target to ShareExtension, SpotlightIndexExtension, and Zavala. → Revert those scheme changes; only the target's own scheme should change.
- **App doesn't build: `.notes.appendText` not found.** Upstream's Siri intent needs a newer SDK. → It's excluded on this machine only, in the untracked `../SharedXcodeSettings/DeveloperSettings.xcconfig`. Remove that once Xcode is updated.
- **In zsh, `tools/mutate.sh $ids` passes one argument.** zsh doesn't split variables into words. → Use `… | xargs tools/mutate.sh`.
- **Long runs.** A full mutation sweep takes more than 10 minutes, so run it in the background. Never edit Zavala's source or `BEHAVIORS.md` while `mutate.sh` is running: it applies patches to the real files and reads test names from the inventory.

- **Two test runs at once kill each other.** When another session (or a second terminal) runs tests at the same time, the log shows "Restarting after unexpected exit…" and tests that "started but never finished", with no crash message. Both runs install the same app: on iPad they share the simulator, on Mac there's only one Mac. → Run the report when nothing else is testing (`ps -Ao command | grep "xcodebuild test"`). For iPad, a private simulator avoids the clash: `xcrun simctl create "<name>" <device type> <runtime>`, then `IPAD_DESTINATION="platform=iOS Simulator,id=<udid>"`, and delete it afterwards. Mac has no such workaround. Also give each worktree its own `DERIVED_DATA`.

## 2. Test outlines (the DSL fixtures)

- **Collapsed rows come back expanded.** Zavala's OPML import applies `<expansionState>` before the rows exist (a recorded quirk). → `makeOutline` and `EditorHarness.open` set collapse state directly after loading.
- **Imported empty rows aren't "empty" the way app rows are.** An imported row with `text=""` gets an empty-string topic; a row created in the app has no topic (`nil`). Zavala treats these differently: Return outdents only `nil` (ZB-002). With imported empty rows, ED-036 passed for the wrong reason. → Fixtures convert empty topics to `nil` (`OutlineSnapshot.clearEmptyTopics`). To test an emptied row, type text and delete it in the editor.
- **`row(titled: "")` finds nothing.** It compared `topic?.string`, which is `nil` for empty rows. → It treats a `nil` topic as `""`.
- **The DSL lives in one file used by both test targets.** `VinOutlineKitTests/Support/OutlineSnapshot.swift` is symlinked into `ZavalaTests/Support/`. Keep that file free of target-specific code; helpers for VinOutlineKitTests go in `VOKTestCase+OutlineSnapshot.swift`, and editor helpers in `ZavalaTests/Support/`.
- **Formatting isn't in the DSL.** Compare formatted text as Markdown (`markdownRepresentation` from VinMarkdown). Zavala writes italic as `_text_`, not `*text*` (ED-052).

## 3. The test host (app-hosted `ZavalaTests`)

- **Running the hosted app touches real data.** Without isolation, the app opens the real accounts folder and settings, consumes the share-extension queue, and starts indexing. → `ZAVALA_TEST_HOST=1` (set only by the `ZavalaTests` scheme) switches the app to a temp accounts folder and a throwaway settings store, and skips iCloud, indexing, and the queue (`Zavala/Utility/TestHost.swift`). `HostIsolationTests` checks this on every run; if it fails, trust nothing else.
- **Collapsed rows still show their children in the editor.** `editor.open` builds the list of visible rows, and `open` used to collapse the fixture's rows after that, so a `(+)` row's children stayed on screen and "the row above" was wrong (ED-054's collapsed case). → `open` rebuilds the visible rows (`outline.prepareForViewing()`) after collapsing. The editor's view isn't loaded yet at that point, so don't touch `collectionView` there.
- **A setting changed in a test has no effect.** The editor reads some settings once, when it's created (for example `childRowIndent` from `createRows`). → Set the setting *before* `EditorHarness.open`, and restore it in a `defer`.

## 4. Driving the editor (`EditorHarness`)

- **The cursor can't be placed right after opening.** The collection view loads before the editor's view joins the window, so cells and first responder aren't available yet. → `open` waits until `editor.view.window != nil` and a cell exists for every visible row. Never wait only on `numberOfItems`.
- **Return inserts a literal line break.** Calling `insertText` from code skips the text view's `shouldChangeTextIn` delegate check, and that check is where Zavala turns Return into a row (and Tab into indent). → `type()` asks the delegate first, as keyboard input does.
- **Return and Delete aren't key commands.** They're text input. → Use `type("\n")` and `deleteBackward()`, not `press`.
- **Some keys live on the row's text view, not the editor.** Shift-Return, Option-Return, Ctrl-P/N, and others. → `press()` searches the responder chain from the focused text view upward. `offersKey()` does the same, so "is this key available right now" is testable.
- **Typed text isn't in the outline yet.** Text typed or inserted by a key command (Option-Return, Option-Tab) stays in the text view until Zavala saves it, when typing pauses or editing ends. The cursor moved but the row's topic hadn't changed (ED-154). → Call `commitTyping()` (the row's `saveText()`, as its own undo step) before checking the outline.
- **Menu shortcuts aren't in any responder's `keyCommands`.** Examples: Ctrl-Return, Cmd-}. → `pressMenu()` finds the `UIKeyCommand` on `AppDelegate` (via `Mirror`), which checks the shortcut *and* its action, then sends the action along the responder chain.
- **Row-selection mode.** `selectRows([...])` ends text editing and selects rows in the collection view, the way Esc and Shift-click leave things; `selectedTitles` reads the selection back. Menu shortcuts such as Delete Rows then act on the selected rows.
- **Arrow keys in the title and tags field aren't key commands.** The editor handles Up and Down from there in `pressesBegan`, and Ctrl-P/N exist only on rows. → `pressKey(.keyboardUpArrow)` sends a press and release to the editor. UIKit can't make a `UIKey`, so the harness subclasses `UIKey` and `UIPress` and overrides the properties Zavala reads. Always send the release too: the editor repeats Up/Down until `pressesEnded` arrives.
- **A simulated press sent to a text field crashes the iPad test host.** On iOS, `UITextField.pressesBegan` passes the press to the on-screen keyboard, and without a real `UIEvent` UIKit forwards it back and forth until the stack overflows ("Thread stack size exceeded due to excessive recursion", `-[UIKeyboard pressesBegan:withEvent:]` repeating). Mac was fine. → `pressKey` sends to the editor directly, not to the focused text.
- **The tags field is a `UITextField`.** Return reaches it as `textFieldShouldReturn`, not `shouldChangeTextIn`. → `type()` checks for a focused text field and calls the field's delegate the way the keyboard does. `tapTitle()` and `tapTagField()` put the cursor there.
- **The title is saved a second after typing stops.** The editor debounces title changes before calling `outline.update(title:)`. → Wait on `outline.title` with `waitUntil`; check the text on screen with `titleText`. Undo of title typing goes to the title's own undo manager (`focusedUndoManager`), and the undone text is saved the same delayed way.
- **`restoreCursorPosition(_:scroll:)` isn't accessible.** It's private. → Use the public `restoreCursorPosition(_:)`. Fine for small fixtures that fit on screen.
- **Undo grouping is the trap to remember.** In the app, UIKit wraps each event in an undo group. In a test the run loop never finishes an event, so:
  - several key presses merged into one undo step, and "undo" reverted two actions;
  - Zavala's `StackedUndoManager` and UIKit's text system open nested groups (typing coalescing), so closing one level isn't enough;
  - closing a group by hand while automatic grouping is on later crashed the app: "must begin a group before registering undo".

  → `open` turns off `groupsByEvent` on the editor window's undo manager. Every simulated key press runs inside `event { }`, which closes *all* open groups, opens one, runs the action, settles, and closes all again. Result: one undo step per key press, as in the app.
- **`canUndo` is true after a key press that did nothing.** Each simulated key press opens its own undo group, and an empty group still counts as something to undo. → To show that a key did nothing, check that Undo and Redo leave the outline unchanged (`expectUndoRedo` with the same tree for `before` and `after`), not `canUndo`.
- **`#expect(try !x)` prints `<not evaluated>`.** Swift Testing can't take apart a negated `try`, so a failure shows no value. → Write `#expect(try x == false)`.
- **The clipboard is the real one.** Cut, Copy, and Paste use `UIPasteboard.general`, which on Mac is your system clipboard. Clipboard tests overwrite it and clear it before and after (`EditorHarness.clearClipboard()`), so running them loses whatever you had copied (decided 2026-10-09). Send Cut/Copy/Paste with `edit(_:)`, which goes to whatever has focus, as the Edit menu does: the row's text view while editing, the editor in row-selection mode.
- **Paste is asynchronous.** The editor reads the clipboard in a `Task`. → `pasteAndWait()` waits until the outline changes.
- **Waiting.** Wait on state (`waitUntil`), never on a fixed sleep. `settle()` gives UIKit a few short passes after each action.

## 5. Reading results without being fooled

- **A crash reported as "passed".** When the test host crashes or hangs, xcodebuild relaunches it, prints "Restarting after unexpected exit…", drops the dead test, and still ends with `** TEST SUCCEEDED **`. → `behavior-report.sh` treats that line, and any test that started but never finished, as a run error.
- **Zero-width spaces.** Swift Testing sometimes puts U+200B in front of `✘`/`✔`, so `^✘` misses those lines. → Strip `\x{200B}` first (Perl with `-CSD -Mutf8`).
- **The run summary looks like a test.** `✘ Test run with N tests … failed` starts like a failing test. → Exclude `Test run with`.
- **Parameterized tests finish differently.** `✔ Test "…" with 6 test cases passed`. → Match the optional `with N test cases`.
- **Known issues.** A test with `withKnownIssue` reports `━ Test "…" passed … with 1 known issue`, which counts as passing. When the bug is fixed, it fails with "Known issue was not recorded".
- **A bug that shows up only on some runs.** Anything that iterates a `Set` of rows (ZB-007) can change from run to run, because Swift seeds hashing per process. One passing run proves nothing; run the test several times. → Wrap it in `withKnownIssue(…, isIntermittent: true)`, so a run where the bug doesn't show isn't reported as "Known issue was not recorded". Its mutation patch has to break a part of the test outside that wrapper.
- **`grep -q` in a pipe under `set -o pipefail`.** grep exits on its first match, the writer gets SIGPIPE, and the pipeline reports failure: "found" reads as "not found". → grep the saved log file, not a pipe.
- **A false "all green".** One early version of the report printed green for a failing run. → If xcodebuild says `** TEST FAILED **` but no failing test was parsed, the report shows a run error. Never let a parsing bug read as success.
- **Readable output.** `test_results <log>` (in `behavior-common.sh`) prints only compile errors and Swift Testing results.

## 6. Mutation checks (`tools/mutate.sh`)

- **A patch can fail to break anything.** ED-014's first patch removed `expand(row:)`, but a later `isExpanded = true` did the same job. → Read the surrounding code and break the behavior, not a line. If a patch survives, decide whether the patch or the test is weak.
- **A build failure isn't a kill.** `mutate.sh` reports BROKEN when the patched code doesn't compile or the test didn't run. Only a failing test counts.
- **Killed for the wrong reason.** "KILLED" only means the test failed. → Read the failure diff in `build/behavior-dd/mutate-<ID>.log` (with `test_results`) and confirm it fails on the behavior.
- **Results go stale.** After changing fixtures, harness, or tools, re-run *every* patch (`ls planning/behaviors/mutations/*.patch | xargs -n1 basename | sed 's/.patch//' | xargs tools/mutate.sh`).
- **Editor-level patches.** They usually live in `Zavala/Editor/…` (for example `EditorRowTopicTextView.textView(_:shouldChangeTextIn:…)` for Return) or in the `Outline` method the editor calls. `mutate.sh` runs them on Mac only.

## 7. Writing the sentences

- **Read the code before writing the sentence, and let the test settle it.** Several drafts turned out wrong (ED-042's undo, ED-019/020's undo). When a test fails on unmodified Zavala, the sentence or the harness is wrong, not Zavala.
- **Bug or quirk?** If Zavala is wrong (same visible state, different behavior; undo not restoring), the test asserts the correct behavior inside `withKnownIssue("ZB-nnn …")` and the bug is added to the "Known Zavala bugs" table. If it's only odd, test it as it is and note it under "Observed Zavala quirks".
- **One layer per behavior.** If a sentence mentions the cursor, focus, a key, or a menu shortcut, it's L2, even when the structural part could be L1 (ED-039 moved for this reason).
- **Check undo for every edit.** `expectEdit` (L1) and `expectUndoRedo` (L2) check after, undo, and redo against full snapshots.

## 8. Undo sequences in L1 (`UndoSequenceBehaviors`)

- **Undoing several commands in a row reverts all of them at once.** With no run loop, `groupsByEvent` never closes the first group, so every command registered in a test lands in one undo step, and one `undo()` reverts the whole sequence. `expectEdit` only ever undoes one command, so this didn't show before ED-250. → Set `undoManager.groupsByEvent = false` before the first command, and wrap each command in `beginUndoGrouping()` / `endUndoGrouping()`. Those groups are then top-level, and one `undo()` reverts one command.
- **Checking a sequence.** Record the outline after each step (`expectOutline` as you go), then undo through the recorded states in reverse, then redo forward through them. A check that only looks at the start and end can't tell whether each step is undoable by itself.
- **Empty rows from a create command.** `CreateRowAfterCommand` with `rowStrings` gives the *current* row the typed text and leaves the new row empty. It doesn't put the text in the new row. Pass `rowStrings: nil` to get an empty new row, which the DSL writes as a bare `-`.

## 9. Smoke flows with real keystrokes (L3, `ZavalaUITests`)

- **The UI test runner is killed at launch ("Test crashed with signal kill before establishing connection").** macOS kills a runner signed ad hoc, as the local settings sign macOS builds. → `xcconfig/Zavala_uitests_target.xcconfig` signs it with an Apple Development certificate, and `run_tests` builds L3 with signing (`-allowProvisioningUpdates`), in its own build folder (`$DERIVED_DATA-signed`) so it doesn't make the unsigned L1/L2 builds start over.
- **"The test runner hung before establishing connection".** UI automation needs Developer mode and Automation Mode. → Once per Mac: `sudo DevToolsSecurity -enable` and `sudo automationmodetool enable-automationmode-without-authentication`.
- **The app under a UI test isn't isolated.** The scheme's `ZAVALA_TEST_HOST=1` doesn't reach an app launched by XCUITest. → `SmokeApp` passes it in `launchEnvironment`, plus `-ApplePersistenceIgnoreState YES` so the last run's window (showing an outline from a temp folder that's gone) isn't restored. Each flow checks the sidebar shows 0 outlines before starting.
- **Cmd-N right after launch is unreliable.** The sidebar takes keyboard focus a moment after launch; if that lands after Cmd-N, it takes the cursor from the new outline's title, and a Cmd-N sent too early is lost. → Setup clicks New Outline and then the title, as a user would, and waits until the first row has the cursor. The click on New Outline is occasionally lost too (about 1 flow in 60, no outline appears, the click takes ~45 s), so setup clicks once more if no outline is listed after 5 s.
- **Don't use the Mac while L3 runs.** The flows type real keys; typing, clicking, or switching apps during a run steals keys (seen: "Bra" instead of "BravoX", a lost Delete). A failing L3 run while someone was using the Mac proves nothing. Mac is the only place L3 runs.
- **Every XCUITest action costs about 1s on the Mac** (click, key, query, wait), and launch plus quit about 4.5s. → Keep setup to a few actions; a flow takes 15–20s.
- **Reading the outline back.** `outlineMarkdown()` presses Esc, Cmd-A, Cmd-C and reads the clipboard (a Markdown list: tabs for nesting, `~~text~~` for completed, notes indented). Esc ends editing and can save typed text as an undo step, so undo flows use `screenOutline` instead, which reads the rows' text and indentation from the screen without pressing anything.
- **`#expect(try await x == y)` prints `<not evaluated>`** on failure, like a negated `try`. → Put the value in a `let` first.
- **`hasFocus` crashes the runner on the Mac** (it's tvOS only). → Use the `hasKeyboardFocus` predicate.
- **Undo with real keys differs from the L2 harness.** The harness's `commitTyping()` makes typing its own undo step; real typing never gets one (ZB-012). Tests that call `commitTyping()` before a structural edit don't show what a user sees, so only call it to read the outline after the last key press (ED-252 used to call it before Return and hid ZB-012).
