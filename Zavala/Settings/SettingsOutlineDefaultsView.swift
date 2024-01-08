//
//  SettingsOutlineDefaultsView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct SettingsOutlineDefaultsView: View {
	
	@State var autoLinking = AppDefaults.shared.autoLinkingEnabled
	
	var body: some View {
		Section(String.outlineDefaultsControlLabel) {
			Toggle(isOn: $autoLinking) {
				Text(String.autoLinkingControlLabel)
			}
			.onChange(of: autoLinking) {
				AppDefaults.shared.autoLinkingEnabled = $0
			}
		}
	}
	
}

#Preview {
    SettingsOutlineDefaultsView()
}
