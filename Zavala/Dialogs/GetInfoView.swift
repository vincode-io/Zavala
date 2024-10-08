//
//  GetInfoView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/22/23.
//

import SwiftUI
import Combine
import VinOutlineKit

struct GetInfoView: View {
	
	@Environment(\.dismiss) var dismiss
	@ObservedObject var getInfoViewModel: GetInfoViewModel
	
	init(outline: Outline) {
		getInfoViewModel = GetInfoViewModel(outline: outline)
	}
	
#if targetEnvironment(macCatalyst)
	var body: some View {
		if getInfoViewModel.title.isEmpty {
			Text(String.noTitleLabel)
				.lineLimit(1)
				.font(.title)
				.padding(8)
		} else {
			Text(getInfoViewModel.title)
				.lineLimit(1)
				.font(.title)
				.padding(8)
		}
		form
		HStack {
			Spacer()
			cancelButton
			saveButton
		}
		.padding(16)
	}
#else
	var body: some View {
		NavigationStack {
			form
				.navigationTitle(getInfoViewModel.title)
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						cancelButton
					}
					ToolbarItem(placement: .confirmationAction) {
						saveButton
					}
				}
		}
	}
#endif
	
	var form: some View {
		Form {
			Section(String.settingsControlLabel) {
				Toggle(isOn: $getInfoViewModel.checkSpellingWhileTyping) {
					Text(String.checkSpellingWhileTypingControlLabel)
				}
				.toggleStyle(.switch)
				Toggle(isOn: $getInfoViewModel.correctSpellingAutomatically) {
					Text(String.correctSpellingAutomaticallyControlLabel)
				}
				.toggleStyle(.switch)
				.disabled(getInfoViewModel.checkSpellingWhileTyping == false)
				Toggle(isOn: $getInfoViewModel.autoLinkingEnabled) {
					Text(String.autoLinkingControlLabel)
				}
				.toggleStyle(.switch)
			}
			Section(String.ownerControlLabel) {
				TextField(text: $getInfoViewModel.ownerName) {
					Text(String.nameControlLabel)
				}
				.textContentType(.name)

				TextField(text: $getInfoViewModel.ownerEmail) {
					Text(String.emailControlLabel)
				}
				.textInputAutocapitalization(.never)
				.textContentType(.emailAddress)
				.keyboardType(.emailAddress)

				TextField(text: $getInfoViewModel.ownerURL) {
					Text(String.urlControlLabel)
				}
				.textInputAutocapitalization(.never)
				.textContentType(.URL)
				.keyboardType(.URL)

				Text(String.opmlOwnerFieldNote)
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
			Section(String.statisticsControlLabel) {
				HStack {
					Text(String.wordCountLabel)
					Spacer()
					Text(String(getInfoViewModel.wordCount))
						.foregroundStyle(.secondary)
				}
				
				HStack {
					Text(String.createdControlLabel)
					Spacer()
					Text(getInfoViewModel.createdLabel)
						.foregroundStyle(.secondary)
				}
				
				HStack {
					Text(String.updatedControlLabel)
					Spacer()
					Text(getInfoViewModel.updatedLabel)
						.foregroundStyle(.secondary)
				}
			}
		}
		.formStyle(.grouped)
	}
	
	var cancelButton: some View {
		Button(String.cancelControlLabel, role: .cancel) {
			dismiss()
		}
		.keyboardShortcut(.cancelAction)
	}
	
	var saveButton: some View {
		Button(String.saveControlLabel) {
			getInfoViewModel.update()
			dismiss()
		}
		.keyboardShortcut(.defaultAction)
	}
}

@MainActor
class GetInfoViewModel: ObservableObject {
	
	private var outline: Outline
	
	var title: String
	@Published var checkSpellingWhileTyping: Bool
	@Published var correctSpellingAutomatically: Bool
	@Published var autoLinkingEnabled: Bool
	@Published var ownerName: String
	@Published var ownerEmail: String
	@Published var ownerURL: String
	var createdLabel: String
	var updatedLabel: String
	var wordCount: Int
	
	init(outline: Outline) {
		self.outline = outline
		
		self.title = outline.title ?? ""
		self.checkSpellingWhileTyping = outline.checkSpellingWhileTyping ?? true
		self.correctSpellingAutomatically = outline.correctSpellingAutomatically ?? true
		self.autoLinkingEnabled = outline.autoLinkingEnabled ?? false
		self.ownerName = outline.ownerName ?? ""
		self.ownerEmail = outline.ownerEmail ?? ""
		self.ownerURL = outline.ownerURL ?? ""
		
		if let created = outline.created {
			createdLabel = .createdOnLabel(date: created)
		} else {
			createdLabel = ""
		}
		
		if let updated = outline.updated {
			updatedLabel = .updatedOnLabel(date: updated)
		} else {
			updatedLabel = ""
		}
		
		wordCount = outline.wordCount
	}
	
	func update() {
		outline.update(checkSpellingWhileTyping: checkSpellingWhileTyping,
					   correctSpellingAutomatically: correctSpellingAutomatically,
					   autoLinkingEnabled: autoLinkingEnabled,
					   ownerName: ownerName,
					   ownerEmail: ownerEmail,
					   ownerURL: ownerURL)
	}
	
}
