//
//  SettingsOutlineDefaultsView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct SettingsOutlineDefaultsView: View {
	
	@State var checkSpellingWhileTyping = AppDefaults.shared.checkSpellingWhileTyping
	@State var correctSpellingAutomatically = AppDefaults.shared.correctSpellingAutomatically
	@State var autoLinking = AppDefaults.shared.autoLinkingEnabled

	var body: some View {
		Section(String.outlineDefaultsControlLabel) {
			Toggle(isOn: $checkSpellingWhileTyping) {
				Text(String.checkSpellingWhileTypingControlLabel)
			}
			.toggleStyle(.switch)
			.onChange(of: checkSpellingWhileTyping) {
				AppDefaults.shared.checkSpellingWhileTyping = $0
			}

			Toggle(isOn: $correctSpellingAutomatically) {
				Text(String.correctSpellingAutomaticallyControlLabel)
			}
			.toggleStyle(.switch)
			.onChange(of: correctSpellingAutomatically) {
				AppDefaults.shared.correctSpellingAutomatically = $0
			}
			.disabled(checkSpellingWhileTyping == false)

			Toggle(isOn: $autoLinking) {
				Text(String.autoLinkingControlLabel)
			}
			.toggleStyle(.switch)
			.onChange(of: autoLinking) {
				AppDefaults.shared.autoLinkingEnabled = $0
			}
		}
	}
	
}

#Preview {
    SettingsOutlineDefaultsView()
}
