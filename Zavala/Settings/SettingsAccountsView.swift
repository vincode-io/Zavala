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
		Section(AppStringAssets.accountsControlLabel) {
			Toggle(isOn: $enableLocalAccount) {
				switch UIDevice.current.userInterfaceIdiom {
				case .phone:
					Text(AppStringAssets.enableOnMyIPhoneControlLabel)
				case .pad:
					Text(AppStringAssets.enableOnMyIPadControlLabel)
				default:
					Text(AppStringAssets.enableOnMyMacControlLabel)
				}
			}
			.onChange(of: enableLocalAccount) {
				AppDefaults.shared.enableLocalAccount = $0
			}
			Toggle(isOn: $enableCloudKit) {
				Text(AppStringAssets.enableCloudKitControlLabel)
			}
			.onChange(of: enableCloudKit) {
				if $0 {
					AppDefaults.shared.enableCloudKit = true
				} else {
					cloudKitAlertIsPresenting = true
				}
			}
		}
		.alert(AppStringAssets.removeICloudAccountTitle, isPresented: $cloudKitAlertIsPresenting) {
			Button(AppStringAssets.cancelControlLabel, role: .cancel) {
				enableCloudKit = true
			}
			Button(AppStringAssets.removeControlLabel, role: .destructive) {
				AppDefaults.shared.enableCloudKit = false
			}
		} message: {
			Text(AppStringAssets.removeICloudAccountMessage)
		}

    }
}

#Preview {
    SettingsAccountsView()
}
