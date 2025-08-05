//
//  SettingsAdvancedView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/29/23.
//

import SwiftUI

struct SettingsGeneralView: View {
	
	@State var colorPalette = AppDefaults.shared.userInterfaceColorPalette
	@State var enableMainWindowAsDefault = AppDefaults.shared.enableMainWindowAsDefault

	var body: some View {
		Section(String.generalControlLabel) {
			HStack {
				Text(String.colorPalettControlLabel)
					.font(.body)
				Spacer()
				Picker(selection: $colorPalette) {
					ForEach(UserInterfaceColorPalette.allCases, id: \.self) {
						Text($0.description)
					}
				} label: {
				}
				.pickerStyle(.menu)
				.onChange(of: colorPalette) { old, new in
					AppDefaults.shared.userInterfaceColorPalette = new
				}
			}

			#if targetEnvironment(macCatalyst)
			Toggle(isOn: $enableMainWindowAsDefault) {
				Text(String.useMainWindowAsDefaultControlLabel)
			}
			.toggleStyle(.switch)
			.controlSize(.small)
			.onChange(of: enableMainWindowAsDefault) { old, new in
				AppDefaults.shared.enableMainWindowAsDefault = new
			}
			#endif
		}
	}
	
}
