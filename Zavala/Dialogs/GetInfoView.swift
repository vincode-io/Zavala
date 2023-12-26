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
	
	@ObservedObject var getInfoViewModel: GetInfoViewModel

    var body: some View {
		#if targetEnvironment(macCatalyst)
			Text(getInfoViewModel.title)
				.lineLimit(1)
				.font(.title)
		#endif
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
}

class GetInfoViewModel: ObservableObject {
	
	var title: String
	@Published var autoLinkingEnabled: Bool
	@Published var ownerName: String
	@Published var ownerEmail: String
	@Published var ownerURL: String
	var createdLabel: String
	var updatedLabel: String
	
	init(outline: Outline?) {
		self.title = outline?.title ?? ""
		self.autoLinkingEnabled = outline?.autoLinkingEnabled ?? false
		self.ownerName = outline?.ownerName ?? ""
		self.ownerEmail = outline?.ownerEmail ?? ""
		self.ownerURL = outline?.ownerURL ?? ""
		
		if let created = outline?.created {
			createdLabel = AppStringAssets.createdOnLabel(date: created)
		} else {
			createdLabel = ""
		}
		
		if let updated = outline?.updated {
			updatedLabel = AppStringAssets.updatedOnLabel(date: updated)
		} else {
			updatedLabel = ""
		}
	}
	
}
