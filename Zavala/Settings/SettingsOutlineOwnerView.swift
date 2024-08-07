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
					.onChange(of: name) { old, new in
						AppDefaults.shared.ownerName = new
					}
			}
			.textContentType(.name)
			.font(.body)
			
			TextField(text: $email) {
				Text(String.emailControlLabel)
					.onChange(of: email) { old, new in
						AppDefaults.shared.ownerEmail = new
					}
			}
			.textInputAutocapitalization(.never)
			.textContentType(.emailAddress)
			.keyboardType(.emailAddress)
			.font(.body)

			TextField(text: $url) {
				Text(String.urlControlLabel)
					.onChange(of: url) { old, new in
						AppDefaults.shared.ownerURL = new
					}
			}
			.textInputAutocapitalization(.never)
			.textContentType(.URL)
			.keyboardType(.URL)
			.font(.body)

			Text(String.opmlOwnerFieldNote)
				.font(.footnote)
				.foregroundStyle(.secondary)
		}
	}
}
