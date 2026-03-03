//
//  EditShortcutsMenuView.swift
//  Zavala
//
//  Created by Maurice Parker on 3/3/26.
//

import SwiftUI

struct EditShortcutsMenuView: View {

	@State private var entries: [String] = AppDefaults.shared.shortcutsMenuEntries
	@State private var newEntryName = ""
	@FocusState private var isNewEntryFocused: Bool

	var body: some View {
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
	}

	private func addEntry() {
		let trimmed = newEntryName.trimmingCharacters(in: .whitespaces)
		guard !trimmed.isEmpty else { return }
		entries.append(trimmed)
		newEntryName = ""
		save()
	}

	private func deleteEntries(at offsets: IndexSet) {
		entries.remove(atOffsets: offsets)
		save()
	}

	private func save() {
		AppDefaults.shared.shortcutsMenuEntries = entries
		UIMenuSystem.main.setNeedsRebuild()
	}

}
