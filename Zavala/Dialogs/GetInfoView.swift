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
		Text(getInfoViewModel.title)
			.lineLimit(1)
			.font(.title)
			.padding(8)
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
			Section(AppStringAssets.settingsControlLabel) {
				Toggle(isOn: $getInfoViewModel.autoLinkingEnabled) {
					Text(AppStringAssets.autoLinkingControlLabel)
				}
			}
			Section(AppStringAssets.ownerControlLabel) {
				TextField(text: $getInfoViewModel.ownerName) {
					Text(AppStringAssets.nameControlLabel)
				}
				TextField(text: $getInfoViewModel.ownerEmail) {
					Text(AppStringAssets.emailControlLabel)
				}
				TextField(text: $getInfoViewModel.ownerURL) {
					Text(AppStringAssets.urlControlLabel)
				}
				Text(AppStringAssets.opmlOwnerFieldNote)
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
			Section(AppStringAssets.statisticsControlLabel) {
				HStack {
					Text(AppStringAssets.wordCountLabel)
					Spacer()
					Text(String(getInfoViewModel.wordCount))
						.foregroundStyle(.secondary)
				}
				HStack {
					Text(AppStringAssets.createdControlLabel)
					Spacer()
					Text(getInfoViewModel.createdLabel)
						.foregroundStyle(.secondary)
				}
				HStack {
					Text(AppStringAssets.updatedControlLabel)
					Spacer()
					Text(getInfoViewModel.updatedLabel)
						.foregroundStyle(.secondary)
				}
			}
		}
		.formStyle(.grouped)
	}
	
	var cancelButton: some View {
		Button(AppStringAssets.cancelControlLabel, role: .cancel) {
			dismiss()
		}
		.keyboardShortcut(.cancelAction)
	}
	
	var saveButton: some View {
		Button(AppStringAssets.saveControlLabel) {
			getInfoViewModel.update()
			dismiss()
		}
		.keyboardShortcut(.defaultAction)
	}
}

class GetInfoViewModel: ObservableObject {
	
	private var outline: Outline
	
	var title: String
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
		self.autoLinkingEnabled = outline.autoLinkingEnabled ?? false
		self.ownerName = outline.ownerName ?? ""
		self.ownerEmail = outline.ownerEmail ?? ""
		self.ownerURL = outline.ownerURL ?? ""
		
		if let created = outline.created {
			createdLabel = AppStringAssets.createdOnLabel(date: created)
		} else {
			createdLabel = ""
		}
		
		if let updated = outline.updated {
			updatedLabel = AppStringAssets.updatedOnLabel(date: updated)
		} else {
			updatedLabel = ""
		}
		
		wordCount = outline.wordCount
	}
	
	func update() {
		outline.update(autoLinkingEnabled: autoLinkingEnabled,
					   ownerName: ownerName,
					   ownerEmail: ownerEmail,
					   ownerURL: ownerURL)
	}
	
}
