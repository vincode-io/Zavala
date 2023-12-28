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
				SettingsAccountsView()
				SettingsOutlineDefaultsView()
				SettingsOutlineOwnerView()
				SettingsAppearanceView()
				SettingsHelpView()
			}
			.navigationTitle(AppStringAssets.settingsControlLabel)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: ToolbarItemPlacement.confirmationAction) {
					Button(AppStringAssets.doneControlLabel) {
						dismiss()
					}
				}
			}
		}
    }
}

#Preview {
    SettingsView()
}
