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
				#if targetEnvironment(macCatalyst)
				SettingsAdvancedView()
				#else
				SettingsHelpView()
				#endif
			}
			.navigationTitle(String.settingsControlLabel)
			.navigationBarTitleDisplayMode(.inline)
			#if !targetEnvironment(macCatalyst)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(String.doneControlLabel) {
						dismiss()
					}
				}
			}
			#endif
		}
		.onAppear {
			let navigationAppearance = UINavigationBarAppearance()
			navigationAppearance.configureWithOpaqueBackground()
			UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
			UINavigationBar.appearance().standardAppearance = navigationAppearance
		}
		
	}
}

#Preview {
	SettingsView()
}
