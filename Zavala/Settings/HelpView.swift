//
//  HelpView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct HelpView: View {
	
	@Environment(\.openURL) private var openURL
	@State var isPresentingAbout = false
	
    var body: some View {
		Section() {
			Button {
				isPresentingAbout = true
			} label: {
				Text(AppStringAssets.aboutZavala)
			}
			.foregroundStyle(.primary)
			.sheet(isPresented: $isPresentingAbout) {
				AboutView()
			}

			Button {
				openURL(URL(string: AppStringAssets.helpURL)!)
			} label: {
				Text(AppStringAssets.helpControlLabel)
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
    HelpView()
}
