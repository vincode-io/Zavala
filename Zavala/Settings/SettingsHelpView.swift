//
//  SettingsHelpView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI
import VinUtility

struct SettingsHelpView: View {
	
	@Environment(\.openURL) private var openURL
	@State var isPresentingAbout = false
	
    var body: some View {
		Section(AppStringAssets.helpControlLabel) {
			Button {
				isPresentingAbout = true
			} label: {
				Text(AppStringAssets.aboutZavala)
			}
			.foregroundStyle(.primary)
			.formSheet(isPresented: $isPresentingAbout, width: 350, height: 450) {
				AboutView()
			}

			Button {
				openURL(URL(string: AppStringAssets.helpURL)!)
			} label: {
				Text(AppStringAssets.zavalaHelpControlLabel)
			}
			.foregroundStyle(.primary)

			Button {
				openURL(URL(string: AppStringAssets.reportAnIssueURL)!)
			} label: {
				Text(AppStringAssets.feedbackControlLabel)
			}
			.foregroundStyle(.primary)

		}
    }
}

#Preview {
    SettingsHelpView()
}
