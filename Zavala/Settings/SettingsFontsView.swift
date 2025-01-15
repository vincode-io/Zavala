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
					.deleteDisabled(fontsViewModel.deleteUnavailable($0))
			}
			.onDelete(perform: fontsViewModel.delete)
		}
		.formStyle(.grouped)
		.navigationTitle(String.fontsControlLabel)
		.toolbar {
			ToolbarItem {
				Button {
					restoreAlertIsPresenting = true
				} label: {
					Label(String.restoreControlLabel, systemImage: "gobackward")
				}
				.help(String.restoreControlLabel)
				.disabled(AppDefaults.shared.outlineFonts == OutlineFontDefaults.defaults)
			}
			ToolbarItem {
				SettingsFontAddMenu()
			}
		}
		.alert(String.restoreDefaultsMessage, isPresented: $restoreAlertIsPresenting) {
			Button(String.cancelControlLabel, role: .cancel) {}
			Button(String.restoreControlLabel, role: .destructive) {
				AppDefaults.shared.outlineFonts = OutlineFontDefaults.defaults
			}
		} message: {
			Text(String.restoreDefaultsInformative)
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
					.font(.body)
				Spacer()
				Text(fieldConfig.config.displayName)
					.font(.footnote)
			}
		}
		.foregroundStyle(.primary)
		.help(String.addControlLabel)
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
				guard let fieldConfig = AppDefaults.shared.outlineFonts?.nextNumberingDefault else { return }
				presentingFieldConfig = FieldConfig(field: fieldConfig.0, config: fieldConfig.1)
			} label: {
				Text(String.addNumberingLevelControlLabel)
			}
			Button {
				guard let fieldConfig = AppDefaults.shared.outlineFonts?.nextTopicDefault else { return }
				presentingFieldConfig = FieldConfig(field: fieldConfig.0, config: fieldConfig.1)
			} label: {
				Text(String.addTopicLevelControlLabel)
			}
			Button {
				guard let fieldConfig = AppDefaults.shared.outlineFonts?.nextNoteDefault else { return }
				presentingFieldConfig = FieldConfig(field: fieldConfig.0, config: fieldConfig.1)
			} label: {
				Text(String.addNoteLevelControlLabel)
			}
		} label: {
			Label(String.addControlLabel, systemImage: "plus")
		}
		.popover(item: $presentingFieldConfig) { fieldConfig in
			SettingsFontConfigView(fieldConfig: fieldConfig)
		}
	}
	
}

@MainActor
class SettingsFontsViewModel: ObservableObject {
	
	@Published var fieldConfigs: [(OutlineFontField, OutlineFontConfig)]
	var lastOutlineFonts = AppDefaults.shared.outlineFonts
	
	init() {
		if let outlineFonts = AppDefaults.shared.outlineFonts {
			self.fieldConfigs = outlineFonts.sortedFields.map { ($0, outlineFonts.rowFontConfigs[$0]!) }
		} else {
			self.fieldConfigs = []
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(checkForUserDefaultsChanges), name: UserDefaults.didChangeNotification, object: nil)
	}

	func deleteUnavailable(_ fontField: OutlineFontField) -> Bool {
		switch fontField {
		case .rowNumbering(let level):
			guard level > 1 else { return true }
			return lastOutlineFonts?.deepestNumberingLevel ?? -1 != level
		case .rowTopic(let level):
			guard level > 1 else { return true }
			return lastOutlineFonts?.deepestTopicLevel ?? -1 != level
		case .rowNote(let level):
			guard level > 1 else { return true }
			return lastOutlineFonts?.deepestNoteLevel ?? -1 != level
		default:
			return true
		}
	}
	
	func delete(at offsets: IndexSet) {
		guard let firstOffset = offsets.first else { return }
		
		let fontField = fieldConfigs[firstOffset].0
		var outlineFonts = AppDefaults.shared.outlineFonts
		outlineFonts?.rowFontConfigs.removeValue(forKey: fontField)
		
		AppDefaults.shared.outlineFonts = outlineFonts
	}
	
	@objc nonisolated private func checkForUserDefaultsChanges() {
		Task { @MainActor in
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
			navController.preferredContentSize = CGSize(width: 300, height: 210)
		} else {
			let contentWidth = UIFontMetrics(forTextStyle: .body).scaledValue(for: 400)
			let contentHeight = UIFontMetrics(forTextStyle: .body).scaledValue(for: 275)
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

//#Preview {
//    SettingsFontsView()
//}
