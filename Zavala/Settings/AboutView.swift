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
				AppAssets.aboutPanelBackgroundColor.ignoresSafeArea()
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
						.cornerRadius(11)
						.onTapGesture {
							UIApplication.shared.open(AppAssets.websiteURL, options: [:])
						}
					Text(Bundle.main.appName)
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
				Link("Acknowledgements", destination: AppAssets.acknowledgementsURL)
					.buttonStyle(.borderless)
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
