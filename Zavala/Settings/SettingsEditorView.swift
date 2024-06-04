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
				.onChange(of: editorMaxWidth) {
					AppDefaults.shared.editorMaxWidth = $0
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
				.onChange(of: scrollMode) {
					AppDefaults.shared.scrollMode = $0
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
				.onChange(of: rowIndent) {
					AppDefaults.shared.rowIndentSize = $0
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
				.onChange(of: rowSpacing) {
					AppDefaults.shared.rowSpacingSize = $0
				}
			}

			NavigationLink(String.fontsControlLabel) {
				SettingsFontsView()
			}
			.font(.body)

			Toggle(isOn: $disableEditorAnimations) {
				Text(String.disableAnimationsControlLabel)
			}
			.toggleStyle(.switch)
			.onChange(of: disableEditorAnimations) {
				AppDefaults.shared.disableEditorAnimations = $0
			}
		}
    }
}

#Preview {
	Form {
		SettingsEditorView()
	}
}
