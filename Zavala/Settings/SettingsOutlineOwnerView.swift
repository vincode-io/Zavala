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
		Section(String.outlineOwnerControlLabel) {
			TextField(text: $name) {
				Text(String.nameControlLabel)
					.onChange(of: name) {
						AppDefaults.shared.ownerName = $0
					}
			}
			TextField(text: $email) {
				Text(String.emailControlLabel)
					.onChange(of: email) {
						AppDefaults.shared.ownerEmail = $0
					}
			}
			TextField(text: $url) {
				Text(String.urlControlLabel)
					.onChange(of: url) {
						AppDefaults.shared.ownerURL = $0
					}
			}
			Text(String.opmlOwnerFieldNote)
				.font(.footnote)
				.foregroundStyle(.secondary)
		}    }
}

#Preview {
    SettingsOutlineOwnerView()
}
