//
//  SettingsAdvancedView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/29/23.
//

import SwiftUI

struct SettingsAdvancedView: View {
	
	@State var enableMainWindowAsDefault = AppDefaults.shared.enableMainWindowAsDefault
	
	var body: some View {
		Section(AppStringAssets.advancedControlLabel) {
			Toggle(isOn: $enableMainWindowAsDefault) {
				Text(AppStringAssets.useMainWindowAsDefaultControlLabel)
			}
			.onChange(of: enableMainWindowAsDefault) {
				AppDefaults.shared.enableMainWindowAsDefault = $0
			}
		}
	}
	
}
