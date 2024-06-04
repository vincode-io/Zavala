//
//  SettingsAccountsView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI
import UIKit

struct SettingsAccountsView: View {
	
	@State var enableLocalAccount = AppDefaults.shared.enableLocalAccount
	@State var enableCloudKit = AppDefaults.shared.enableCloudKit
	@State var cloudKitAlertIsPresenting = false
	
	var body: some View {
		Section(String.accountsControlLabel) {
			Toggle(isOn: $enableLocalAccount) {
				switch UIDevice.current.userInterfaceIdiom {
				case .phone:
					Text(String.enableOnMyIPhoneControlLabel)
				case .mac:
					Text(String.enableOnMyMacControlLabel)
				default:
					Text(String.enableOnMyIPadControlLabel)
				}
			}
			.toggleStyle(.switch)
			.onChange(of: enableLocalAccount) {
				AppDefaults.shared.enableLocalAccount = $0
			}
			Toggle(isOn: $enableCloudKit) {
				Text(String.enableCloudKitControlLabel)
			}
			.toggleStyle(.switch)
			.disabled(AppDefaults.shared.isDeveloperBuild)
			.onChange(of: enableCloudKit) {
				if $0 {
					AppDefaults.shared.enableCloudKit = true
				} else {
					cloudKitAlertIsPresenting = true
				}
			}
		}
		.alert(String.removeICloudAccountTitle, isPresented: $cloudKitAlertIsPresenting) {
			Button(String.cancelControlLabel, role: .cancel) {
				enableCloudKit = true
			}
			Button(String.removeControlLabel, role: .destructive) {
				AppDefaults.shared.enableCloudKit = false
			}
		} message: {
			Text(String.removeICloudAccountMessage)
		}

    }
}

#Preview {
    SettingsAccountsView()
}
