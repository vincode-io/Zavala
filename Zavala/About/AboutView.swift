//
//  AboutView.swift
//  Zavala
//
//  Created by Maurice Parker on 3/11/23.
//

import SwiftUI
import VinUtility

struct AboutView: View {
	
	@State private var secondaryLabel = BuildInfo.shared.versionLabel
	
	var body: some View {
		ZStack {
			if UIDevice.current.userInterfaceIdiom == .mac {
				Color.aboutBackgroundColor.ignoresSafeArea()
			} else {
				VStack() {
					Capsule()
						.fill(Color.secondary.opacity(0.5))
						.frame(width: 40, height: 5)
						.padding(10)
					Spacer()
				}
			}
			VStack(alignment: .center, spacing: 30) {
				Spacer()
				VStack {
					Image(uiImage: UIImage.appIconImage!)
						.resizable()
						.frame(width: 75, height: 75)
						.clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
						.onTapGesture {
							UIApplication.shared.open(URL(string: .websiteURL)!, options: [:])
						}
					Text(BuildInfo.shared.appName)
						.foregroundColor(.primary)
						.font(.title)
					Text(secondaryLabel)
						.foregroundColor(.secondary)
						.font(.footnote)
						.onTapGesture {
							if secondaryLabel == BuildInfo.shared.versionLabel {
								secondaryLabel = BuildInfo.shared.buildLabel
							} else {
								secondaryLabel = BuildInfo.shared.versionLabel
							}
						}
				}
				VStack(spacing: 5) {
					Text(try! AttributedString(markdown: String.appDevelopedByCreditLabel))
						.tint(.accentColor)
					Text(try! AttributedString(markdown: String.appIconCreditLabel))
						.tint(.accentColor)
				}
				VStack(spacing: 5) {
					Link(String.acknowledgementsControlLabel, destination: URL(string: .acknowledgementsURL)!)
						.buttonStyle(.borderless)
					Link(String.privacyPolicyControlLabel, destination: URL(string: .privacyPolicyURL)!)
						.buttonStyle(.borderless)
				}
				Spacer()
			}
			VStack {
				Spacer()
				Text(String.copyrightLabel())
					.font(.footnote)
					.padding(10)
			}
		}
	}
}
