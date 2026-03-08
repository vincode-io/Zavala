//
//  EditShortcutsMenuView.swift
//  Zavala
//
//  Created by Maurice Parker on 3/3/26.
//

import SwiftUI

struct EditShortcutsMenuView: View {

	@Environment(\.dismiss) var dismiss
	@State private var entries: [String] = AppDefaults.shared.shortcutsMenuEntries
	@State private var newEntryName = ""
	@FocusState private var isNewEntryFocused: Bool

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				List {
					ForEach(entries, id: \.self) { entry in
						Text(entry)
							.contextMenu {
								Button(role: .destructive) {
									if let index = entries.firstIndex(of: entry) {
										deleteEntries(at: IndexSet(integer: index))
									}
								} label: {
									Label(String.deleteControlLabel, systemImage: "trash")
								}
							}
					}
					.onDelete(perform: deleteEntries)
					.onMove(perform: moveEntries)
				}
				Divider()
				HStack {
					TextField(String.shortcutNamePlaceholderLabel, text: $newEntryName)
						.textFieldStyle(.roundedBorder)
						.focused($isNewEntryFocused)
						.onSubmit {
							addEntry()
						}
					Button(String.addControlLabel) {
						addEntry()
					}
					.disabled(newEntryName.trimmingCharacters(in: .whitespaces).isEmpty)
				}
				.padding()
			}
			.onAppear {
				isNewEntryFocused = true
			}
			#if !targetEnvironment(macCatalyst)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(role: .confirm) {
						dismiss()
					}
				}
			}
			#endif
		}
	}

	private func addEntry() {
		let trimmed = newEntryName.trimmingCharacters(in: .whitespaces)
		guard !trimmed.isEmpty else { return }
		entries.append(trimmed)
		newEntryName = ""
		save()
	}

	private func moveEntries(from source: IndexSet, to destination: Int) {
		entries.move(fromOffsets: source, toOffset: destination)
		save()
	}

	private func deleteEntries(at offsets: IndexSet) {
		entries.remove(atOffsets: offsets)
		save()
	}

	private func save() {
		AppDefaults.shared.shortcutsMenuEntries = entries
		UIMenuSystem.main.setNeedsRebuild()
		NotificationCenter.default.post(name: .ShortcutsMenuEntriesDidChange, object: self, userInfo: nil)
	}

}
