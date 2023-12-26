//
//  AppearanceView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import UIKit
import SwiftUI

struct AppearanceView: View {
	
	@State var rowIndent = AppDefaults.shared.rowIndentSize
	@State var rowSpacing = AppDefaults.shared.rowSpacingSize
	@State var colorPalette = AppDefaults.shared.userInterfaceColorPalette
	
    var body: some View {
		Section(AppStringAssets.appearanceControlLabel) {
			Picker(selection: $rowIndent) {
				ForEach(DefaultsSize.allCases, id: \.self) {
					Text($0.description)
				}
			} label: {
				Text(AppStringAssets.rowIndentControlLabel)
			}
			.pickerStyle(.menu)
			.onChange(of: rowIndent) {
				AppDefaults.shared.rowIndentSize = $0
			}

			Picker(selection: $rowSpacing) {
				ForEach(DefaultsSize.allCases, id: \.self) {
					Text($0.description)
				}
			} label: {
				Text(AppStringAssets.rowSpacingControlLabel)
			}
			.pickerStyle(.menu)
			.onChange(of: rowSpacing) {
				AppDefaults.shared.rowSpacingSize = $0
			}

			Picker(selection: $colorPalette) {
				ForEach(UserInterfaceColorPalette.allCases, id: \.self) {
					Text($0.description)
				}
			} label: {
				Text(AppStringAssets.colorPalettControlLabel)
			}
			.pickerStyle(.menu)
			.onChange(of: colorPalette) {
				AppDefaults.shared.userInterfaceColorPalette = $0
			}
			
			if UIDevice.current.userInterfaceIdiom != .mac {
				NavigationLink(AppStringAssets.fontsControlLabel) {
					FontsView()
				}
			}
		}
    }
}

#Preview {
    AppearanceView()
}
