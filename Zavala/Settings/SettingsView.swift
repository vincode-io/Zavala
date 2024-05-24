//
//  SettingsView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct SettingsView: View {
	
	static var pickerWidth: CGFloat = 110
	
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
		.frame(width: 400)
}
