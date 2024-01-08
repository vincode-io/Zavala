//
//  SettingsAdvancedView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/29/23.
//

import SwiftUI

struct SettingsAdvancedView: View {
	
	@State var enableMainWindowAsDefault = AppDefaults.shared.enableMainWindowAsDefault
	@State var disableEditorAnimations = AppDefaults.shared.disableEditorAnimations

	var body: some View {
		Section(String.advancedControlLabel) {
			Toggle(isOn: $enableMainWindowAsDefault) {
				Text(String.useMainWindowAsDefaultControlLabel)
			}
			.onChange(of: enableMainWindowAsDefault) {
				AppDefaults.shared.enableMainWindowAsDefault = $0
			}
			Toggle(isOn: $disableEditorAnimations) {
				Text(String.disableEditorAnimationsControlLabel)
			}
			.onChange(of: disableEditorAnimations) {
				AppDefaults.shared.disableEditorAnimations = $0
			}
		}
	}
	
}
