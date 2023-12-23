//
//  AboutView.swift
//  Zavala
//
//  Created by Maurice Parker on 3/11/23.
//

import SwiftUI

struct AboutView: View {
	
	@State private var secondaryLabel = BuildInfo.shared.versionLabel
	
	private var developedBy = NSAttributedString(markdownRepresentation: "Developed by [Maurice C. Parker](https://vincode.io)",
												 attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
	private var iconBy = NSAttributedString(markdownRepresentation: "App icon by [Brad Ellis](https://hachyderm.io/@bradellis)",
											attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
	
	var body: some View {
		ZStack {
			if UIDevice.current.userInterfaceIdiom == .mac {
				ZavalaImageAssets.aboutBackgroundColor.ignoresSafeArea()
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
							UIApplication.shared.open(URL(string: AppStringAssets.websiteURL)!, options: [:])
						}
					Text("Zavala")
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
					AttributedLabelView(string: developedBy)
					AttributedLabelView(string: iconBy)
				}
				VStack(spacing: 5) {
					Link("Acknowledgements", destination: URL(string: AppStringAssets.acknowledgementsURL)!)
						.buttonStyle(.borderless)
					Link("Privacy Policy", destination: URL(string: AppStringAssets.privacyPolicyURL)!)
						.buttonStyle(.borderless)
				}
				Spacer()
			}
			VStack {
				Spacer()
				Text(verbatim: "Copyright © Vincode, Inc. 2020-\(Calendar.current.component(.year, from: Date()))")
					.font(.footnote)
					.padding(10)
			}
		}
	}
}