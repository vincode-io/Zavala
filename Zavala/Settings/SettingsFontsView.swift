//
//  SettingsFontsView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct SettingsFontsView: View {
	
	@ObservedObject var fontsViewModel = SettingsFontsViewModel()
	@State var restoreAlertIsPresenting = false
	
	var body: some View {
		Form {
			ForEach(fontsViewModel.fieldConfigs, id: \.0) {
				SettingsSelectFontButton(fieldConfig: FieldConfig(field: $0, config: $1))
			}
		}
		.formStyle(.grouped)
		.navigationTitle(AppStringAssets.fontsControlLabel)
		.toolbar {
			ToolbarItem {
				Button {
					restoreAlertIsPresenting = true
				} label: {
					Label(AppStringAssets.restoreControlLabel, systemImage: "gobackward")
				}
				.disabled(AppDefaults.shared.outlineFonts == OutlineFontDefaults.defaults)
			}
			ToolbarItem {
				SettingsFontAddMenu()
			}
		}
		.alert(AppStringAssets.restoreDefaultsMessage, isPresented: $restoreAlertIsPresenting) {
			Button(AppStringAssets.cancelControlLabel, role: .cancel) {}
			Button(AppStringAssets.restoreControlLabel, role: .destructive) {
				AppDefaults.shared.outlineFonts = OutlineFontDefaults.defaults
			}
		} message: {
			Text(AppStringAssets.restoreDefaultsInformative)
		}
	}
	
}

struct SettingsSelectFontButton: View {
	
	var fieldConfig: FieldConfig
	@State var presentingFieldConfig: FieldConfig? = nil
	
	var body: some View {
		Button {
			presentingFieldConfig = fieldConfig
		} label: {
			HStack {
				Text(fieldConfig.field.displayName)
				Spacer()
				Text(fieldConfig.config.displayName)
					.font(.footnote)
			}
		}
		.foregroundStyle(.primary)
		.popover(item: $presentingFieldConfig) { fieldConfig in
			SettingsFontConfigView(fieldConfig: fieldConfig)
		}
	}
	
}

struct SettingsFontAddMenu: View {
	
	@State var presentingFieldConfig: FieldConfig? = nil
	
	var body: some View {
		Menu {
			Button {
				guard let fieldConfig = AppDefaults.shared.outlineFonts?.nextTopicDefault else { return }
				presentingFieldConfig = FieldConfig(field: fieldConfig.0, config: fieldConfig.1)
			} label: {
				Label(AppStringAssets.addTopicLevelControlLabel, systemImage: "textformat.size.larger")
			}
			Button {
				guard let fieldConfig = AppDefaults.shared.outlineFonts?.nextNoteDefault else { return }
				presentingFieldConfig = FieldConfig(field: fieldConfig.0, config: fieldConfig.1)
			} label: {
				Label(AppStringAssets.addNoteControlLabel, systemImage: "textformat.size.smaller")
			}
		} label: {
			Label(AppStringAssets.addControlLabel, systemImage: "plus")
		}
		.popover(item: $presentingFieldConfig) { fieldConfig in
			SettingsFontConfigView(fieldConfig: fieldConfig)
		}
	}
	
}

class SettingsFontsViewModel: ObservableObject {
	
	@Published var fieldConfigs: [(OutlineFontField, OutlineFontConfig)]
	var lastOutlineFonts = AppDefaults.shared.outlineFonts
	
	init() {
		if let outlineFonts = AppDefaults.shared.outlineFonts {
			self.fieldConfigs = outlineFonts.sortedFields.map { ($0, outlineFonts.rowFontConfigs[$0]!) }
		} else {
			self.fieldConfigs = []
		}
		
		NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
			guard let self else { return }
			if AppDefaults.shared.outlineFonts != self.lastOutlineFonts {
				if let outlineFonts = AppDefaults.shared.outlineFonts {
					self.fieldConfigs = outlineFonts.sortedFields.map { ($0, outlineFonts.rowFontConfigs[$0]!) }
				} else {
					self.fieldConfigs = []
				}
				self.lastOutlineFonts = AppDefaults.shared.outlineFonts
			}
		}
	}
	
}

struct SettingsFontConfigView: UIViewControllerRepresentable {
	
	var fieldConfig: FieldConfig?

	func makeUIViewController(context: Context) -> UINavigationController {
		let navController =  UIStoryboard.settings.instantiateViewController(withIdentifier: "SettingsFontConfigViewControllerNav") as! UINavigationController
		navController.modalPresentationStyle = .formSheet
		
		if UIDevice.current.userInterfaceIdiom == .mac {
			navController.preferredContentSize = CGSize(width: 300, height: 200)
		} else {
			let contentWidth = UIFontMetrics(forTextStyle: .body).scaledValue(for: 400)
			let contentHeight = UIFontMetrics(forTextStyle: .body).scaledValue(for: 250)
			navController.preferredContentSize = CGSize(width: contentWidth, height: contentHeight)
		}
		
		let controller = navController.topViewController as! SettingsFontConfigViewController
		controller.field = fieldConfig?.field
		controller.config = fieldConfig?.config
		return navController
	}
	
	func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
		
	}
}

struct FieldConfig: Identifiable {
	var field: OutlineFontField
	var config: OutlineFontConfig
	
	var id: String {
		return field.displayName
	}
}

#Preview {
    SettingsFontsView()
}
