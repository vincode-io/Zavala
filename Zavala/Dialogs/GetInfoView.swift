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
			Section(header: Text("Settings")) {
				Toggle(isOn: $getInfoViewModel.autoLinkingEnabled) {
					Text("Automatic Link Title Change")
				}
			}
			Section(header: Text("Owner")) {
				TextField(text: $getInfoViewModel.ownerName) {
					Text("Name")
				}
				TextField(text: $getInfoViewModel.ownerEmail) {
					Text("Email")
				}
				TextField(text: $getInfoViewModel.ownerURL) {
					Text("URL")
				}
				Text("This information is included in OPML documents to attribute ownership.")
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
			Section(header: Text("Statistics")) {
				HStack {
					Text("Created")
					Spacer()
					Text(getInfoViewModel.createdLabel)
				}
				HStack {
					Text("Updated")
					Spacer()
					Text(getInfoViewModel.updatedLabel)
				}
			}
		}
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
