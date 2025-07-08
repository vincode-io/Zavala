//
//  SettingsAppearanceView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct SettingsEditorView: View {
	
	@State var editorMaxWidth = AppDefaults.shared.editorMaxWidth
	@State var scrollMode = AppDefaults.shared.scrollMode
	@State var rowIndent = AppDefaults.shared.rowIndentSize
	@State var rowSpacing = AppDefaults.shared.rowSpacingSize
	@State var disableEditorAnimations = AppDefaults.shared.disableEditorAnimations

    var body: some View {
		Section(String.editorControlLabel) {
			
			HStack {
				Text(String.maxWidthControlLabel)
					.font(.body)
				Spacer()
				Picker(selection: $editorMaxWidth) {
					ForEach(EditorMaxWidth.allCases, id: \.self) {
						Text($0.description)
					}
				} label: {
				}
				#if targetEnvironment(macCatalyst)
				.frame(width: SettingsView.pickerWidth)
				#endif
				.pickerStyle(.menu)
				.onChange(of: editorMaxWidth) { old, new in
					AppDefaults.shared.editorMaxWidth = new
				}
			}

			HStack {
				Text(String.rowIndentControlLabel)
					.font(.body)
				Spacer()
				Picker(selection: $rowIndent) {
					ForEach(DefaultsSize.allCases, id: \.self) {
						Text($0.description)
					}
				} label: {
				}
				#if targetEnvironment(macCatalyst)
				.frame(width: SettingsView.pickerWidth)
				#endif
				.pickerStyle(.menu)
				.onChange(of: rowIndent) { old, new in
					AppDefaults.shared.rowIndentSize = new
				}
			}

			HStack {
				Text(String.rowSpacingControlLabel)
					.font(.body)
				Spacer()
				Picker(selection: $rowSpacing) {
					ForEach(DefaultsSize.allCases, id: \.self) {
						Text($0.description)
					}
				} label: {
				}
				#if targetEnvironment(macCatalyst)
				.frame(width: SettingsView.pickerWidth)
				#endif
				.pickerStyle(.menu)
				.onChange(of: rowSpacing) { old, new in
					AppDefaults.shared.rowSpacingSize = new
				}
			}

			HStack {
				Text(String.scrollModeControlLabel)
					.font(.body)
				Spacer()
				Picker(selection: $scrollMode) {
					ForEach(ScrollMode.allCases, id: \.self) {
						Text($0.description)
					}
				} label: {
				}
				#if targetEnvironment(macCatalyst)
				.frame(width: SettingsView.pickerWidth)
				#endif
				.pickerStyle(.menu)
				.onChange(of: scrollMode) { old, new in
					AppDefaults.shared.scrollMode = new
				}
			}

			Toggle(isOn: $disableEditorAnimations) {
				Text(String.disableAnimationsControlLabel)
			}
			.toggleStyle(.switch)
			.controlSize(.small)
			.onChange(of: disableEditorAnimations) { old, new in
				AppDefaults.shared.disableEditorAnimations = new
			}

			NavigationLink(String.fontsControlLabel) {
				SettingsFontsView()
			}
			.font(.body)
		}
    }
}

#Preview {
	Form {
		SettingsEditorView()
	}
}
