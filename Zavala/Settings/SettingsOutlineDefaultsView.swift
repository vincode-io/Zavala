//
//  SettingsOutlineDefaultsView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI
import VinOutlineKit

struct SettingsOutlineDefaultsView: View {
	
	@State var checkSpellingWhileTyping = AppDefaults.shared.checkSpellingWhileTyping
	@State var correctSpellingAutomatically = AppDefaults.shared.correctSpellingAutomatically
	@State var automaticallyCreateLinks = AppDefaults.shared.automaticallyCreateLinks
	@State var automaticallyChangeLinkTitles = AppDefaults.shared.automaticallyChangeLinkTitles
	@State var numberingStyle = AppDefaults.shared.numberingStyle

	var body: some View {
		Section(String.outlineDefaultsControlLabel) {
			HStack {
				Text(String.numberingStyleControlLabel)
					.font(.body)
				Spacer()
				Picker(selection: $numberingStyle) {
					ForEach(Outline.NumberingStyle.allCases, id: \.self) {
						Text($0.description)
					}
				} label: {
				}
				#if targetEnvironment(macCatalyst)
				.frame(width: SettingsView.pickerWidth)
				#endif
				.pickerStyle(.menu)
				.onChange(of: numberingStyle) { old, new in
					AppDefaults.shared.numberingStyle = new
				}
			}

			Toggle(isOn: $checkSpellingWhileTyping) {
				Text(String.checkSpellingWhileTypingControlLabel)
			}
			.toggleStyle(.switch)
			.onChange(of: checkSpellingWhileTyping) { old, new in
				AppDefaults.shared.checkSpellingWhileTyping = new
			}

			Toggle(isOn: $correctSpellingAutomatically) {
				Text(String.correctSpellingAutomaticallyControlLabel)
			}
			.toggleStyle(.switch)
			.onChange(of: correctSpellingAutomatically) { old, new in
				AppDefaults.shared.correctSpellingAutomatically = new
			}
			.disabled(checkSpellingWhileTyping == false)

			Toggle(isOn: $automaticallyCreateLinks) {
				Text(String.automaticallyCreateLinksControlLabel)
			}
			.toggleStyle(.switch)
			.onChange(of: automaticallyCreateLinks) { old, new in
				AppDefaults.shared.automaticallyCreateLinks = new
			}

			Toggle(isOn: $automaticallyChangeLinkTitles) {
				Text(String.automaticallyChangeLinkTitlesControlLabel)
			}
			.toggleStyle(.switch)
			.onChange(of: automaticallyChangeLinkTitles) { old, new in
				AppDefaults.shared.automaticallyChangeLinkTitles = new
			}
		}
	}
	
}

#Preview {
    SettingsOutlineDefaultsView()
}
