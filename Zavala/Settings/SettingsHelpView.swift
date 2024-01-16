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
		Section(String.helpControlLabel) {
			Button {
				isPresentingAbout = true
			} label: {
				Text(String.aboutZavala)
			}
			.foregroundStyle(.primary)
			.formSheet(isPresented: $isPresentingAbout, width: 350, height: 450) {
				AboutView()
			}

			Button {
				openURL(URL(string: .helpURL)!)
			} label: {
				Text(String.zavalaHelpControlLabel)
			}
			.foregroundStyle(.primary)

			Button {
				openURL(URL(string: .communityURL)!)
			} label: {
				Text(String.communityControlLabel)
			}
			.foregroundStyle(.primary)

			Button {
				openURL(URL(string: .feedbackURL)!)
			} label: {
				Text(String.feedbackControlLabel)
			}
			.foregroundStyle(.primary)
		}
    }
}

#Preview {
    SettingsHelpView()
}
