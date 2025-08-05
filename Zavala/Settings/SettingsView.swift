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
				SettingsGeneralView()
				SettingsAccountsView()
				SettingsOutlineDefaultsView()
				SettingsOutlineOwnerView()
				SettingsEditorView()
				#if !targetEnvironment(macCatalyst)
				SettingsHelpView()
				#endif
			}
			.navigationTitle(String.settingsControlLabel)
			.navigationBarTitleDisplayMode(.inline)
			#if !targetEnvironment(macCatalyst)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(role: .confirm) {
						dismiss()
					}
				}
			}
			#endif
		}		
	}
}

#Preview {
	SettingsView()
		.frame(width: 400)
}
