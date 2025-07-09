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
		NavigationStack {
			form
				.navigationTitle(getInfoViewModel.title)
				.navigationBarTitleDisplayMode(.inline)
		}
		HStack {
			Spacer()
			cancelButton
			saveButton
		}
		.padding(.init(top: 8, leading: 16, bottom: 16, trailing: 16))
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
				HStack {
					Text(String.numberingStyleControlLabel)
						.font(.body)
					Spacer()
					Picker(selection: $getInfoViewModel.numberingStyle) {
						ForEach(Outline.NumberingStyle.allCases, id: \.self) {
							Text($0.description)
						}
					} label: {
					}
					#if targetEnvironment(macCatalyst)
					.frame(width: SettingsView.pickerWidth)
					#endif
					.pickerStyle(.menu)
				}

				Toggle(isOn: $getInfoViewModel.checkSpellingWhileTyping) {
					Text(String.checkSpellingWhileTypingControlLabel)
				}
				.toggleStyle(.switch)
				.controlSize(.small)

				Toggle(isOn: $getInfoViewModel.correctSpellingAutomatically) {
					Text(String.correctSpellingAutomaticallyControlLabel)
				}
				.toggleStyle(.switch)
				.controlSize(.small)
				.disabled(getInfoViewModel.checkSpellingWhileTyping == false)

				Toggle(isOn: $getInfoViewModel.automaticallyCreateLinks) {
					Text(String.automaticallyCreateLinksControlLabel)
				}
				.toggleStyle(.switch)
				.controlSize(.small)

				Toggle(isOn: $getInfoViewModel.automaticallyChangeLinkTitles) {
					Text(String.automaticallyChangeLinkTitlesControlLabel)
				}
				.toggleStyle(.switch)
				.controlSize(.small)
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
				HStack(alignment: .firstTextBaseline) {
					Text(String.wordCountLabel)
					Spacer()
					Text(String(getInfoViewModel.wordCount))
						.foregroundStyle(.secondary)
				}
				
				HStack(alignment: .firstTextBaseline) {
					Text(String.createdControlLabel)
					Spacer()
					Text(getInfoViewModel.createdLabel)
						.foregroundStyle(.secondary)
				}
				
				HStack(alignment: .firstTextBaseline) {
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
		Button(role: .cancel) {
			dismiss()
		}
		.keyboardShortcut(.cancelAction)
	}
	
	var saveButton: some View {
		Button(role: .confirm) {
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
	@Published var numberingStyle: Outline.NumberingStyle
	@Published var checkSpellingWhileTyping: Bool
	@Published var correctSpellingAutomatically: Bool
	@Published var automaticallyCreateLinks: Bool
	@Published var automaticallyChangeLinkTitles: Bool
	@Published var ownerName: String
	@Published var ownerEmail: String
	@Published var ownerURL: String
	var createdLabel: String
	var updatedLabel: String
	var wordCount: Int
	
	init(outline: Outline) {
		self.outline = outline
		
		self.title = outline.title ?? ""
		self.numberingStyle = outline.numberingStyle ?? .none
		self.checkSpellingWhileTyping = outline.checkSpellingWhileTyping ?? true
		self.correctSpellingAutomatically = outline.correctSpellingAutomatically ?? true
		self.automaticallyCreateLinks = outline.automaticallyCreateLinks ?? true
		self.automaticallyChangeLinkTitles = outline.automaticallyChangeLinkTitles ?? false
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
		outline.update(numberingStyle: numberingStyle,
					   checkSpellingWhileTyping: checkSpellingWhileTyping,
					   correctSpellingAutomatically: correctSpellingAutomatically,
					   automaticallyCreateLinks: automaticallyCreateLinks,
					   automaticallyChangeLinkTitles: automaticallyChangeLinkTitles,
					   ownerName: ownerName,
					   ownerEmail: ownerEmail,
					   ownerURL: ownerURL)
	}
	
}
