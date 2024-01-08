//
//  SettingsAppearanceView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct SettingsAppearanceView: View {
	
	@State var colorPalette = AppDefaults.shared.userInterfaceColorPalette
	@State var rowIndent = AppDefaults.shared.rowIndentSize
	@State var rowSpacing = AppDefaults.shared.rowSpacingSize
	
    var body: some View {
		Section(String.appearanceControlLabel) {
			HStack {
				Text(String.colorPalettControlLabel)
				Spacer()
				Picker(selection: $colorPalette) {
					ForEach(UserInterfaceColorPalette.allCases, id: \.self) {
						Text($0.description)
					}
				} label: {
				}
				#if targetEnvironment(macCatalyst)
				.frame(width: 100)
				#endif
				.pickerStyle(.menu)
				.onChange(of: colorPalette) {
					AppDefaults.shared.userInterfaceColorPalette = $0
				}
			}
			
			HStack {
				Text(String.rowIndentControlLabel)
				Spacer()
				Picker(selection: $rowIndent) {
					ForEach(DefaultsSize.allCases, id: \.self) {
						Text($0.description)
					}
				} label: {
				}
				#if targetEnvironment(macCatalyst)
				.frame(width: 100)
				#endif
				.pickerStyle(.menu)
				.onChange(of: rowIndent) {
					AppDefaults.shared.rowIndentSize = $0
				}
			}

			HStack {
				Text(String.rowSpacingControlLabel)
				Spacer()
				Picker(selection: $rowSpacing) {
					ForEach(DefaultsSize.allCases, id: \.self) {
						Text($0.description)
					}
				} label: {
				}
				#if targetEnvironment(macCatalyst)
				.frame(width: 100)
				#endif
				.pickerStyle(.menu)
				.onChange(of: rowSpacing) {
					AppDefaults.shared.rowSpacingSize = $0
				}
			}

			NavigationLink(String.fontsControlLabel) {
				SettingsFontsView()
			}
		}
    }
}

#Preview {
    SettingsAppearanceView()
}
