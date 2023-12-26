//
//  OutlineDefaultsView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct OutlineDefaultsView: View {
	
	@State var autoLinking = AppDefaults.shared.autoLinkingEnabled
	
	var body: some View {
		Section(AppStringAssets.outlineDefaultsControlLabel) {
			Toggle(isOn: $autoLinking) {
				Text(AppStringAssets.autoLinkingControlLabel)
			}
			.onChange(of: autoLinking) {
				AppDefaults.shared.autoLinkingEnabled = $0
			}
		}
	}
	
}

#Preview {
    OutlineDefaultsView()
}
