//
//  SettingsAppearanceView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct SettingsAppearanceView: View {
	
	@State var rowIndent = AppDefaults.shared.rowIndentSize
	@State var rowSpacing = AppDefaults.shared.rowSpacingSize
	@State var colorPalette = AppDefaults.shared.userInterfaceColorPalette
	
    var body: some View {
		Section(AppStringAssets.appearanceControlLabel) {
			HStack {
				Text(AppStringAssets.rowIndentControlLabel)
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
				Text(AppStringAssets.rowSpacingControlLabel)
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

			HStack {
				Text(AppStringAssets.colorPalettControlLabel)
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
			
			NavigationLink(AppStringAssets.fontsControlLabel) {
				SettingsFontsView()
			}
		}
    }
}

#Preview {
    SettingsAppearanceView()
}
