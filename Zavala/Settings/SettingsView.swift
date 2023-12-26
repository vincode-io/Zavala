//
//  SettingsView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct SettingsView: View {
	
	@Environment(\.dismiss) var dismiss
	
    var body: some View {
		NavigationStack {
			Form {
				AccountsView()
				OutlineDefaultsView()
				OutlineOwnerView()
				AppearanceView()
				HelpView()
			}
			.navigationTitle(AppStringAssets.settingsControlLabel)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				Button(AppStringAssets.doneControlLabel) {
					dismiss()
				}
			}
		}
    }
}

#Preview {
    SettingsView()
}
