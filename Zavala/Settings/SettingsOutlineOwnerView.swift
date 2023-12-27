//
//  SettingsOutlineOwnerView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct SettingsOutlineOwnerView: View {
	
	@State var name = AppDefaults.shared.ownerName ?? ""
	@State var email = AppDefaults.shared.ownerEmail ?? ""
	@State var url = AppDefaults.shared.ownerURL ?? ""
	
    var body: some View {
		Section(AppStringAssets.outlineOwnerControlLabel) {
			TextField(text: $name) {
				Text(AppStringAssets.nameControlLabel)
					.onChange(of: name) {
						AppDefaults.shared.ownerName = $0
					}
			}
			TextField(text: $email) {
				Text(AppStringAssets.emailControlLabel)
					.onChange(of: email) {
						AppDefaults.shared.ownerEmail = $0
					}
			}
			TextField(text: $url) {
				Text(AppStringAssets.urlControlLabel)
					.onChange(of: url) {
						AppDefaults.shared.ownerURL = $0
					}
			}
			Text(AppStringAssets.opmlOwnerFieldNote)
				.font(.footnote)
				.foregroundStyle(.secondary)
		}    }
}

#Preview {
    SettingsOutlineOwnerView()
}
