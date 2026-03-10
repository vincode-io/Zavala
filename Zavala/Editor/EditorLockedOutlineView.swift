//
//  Created by Maurice Parker on 3/8/26.
//

import SwiftUI
import VinOutlineKit

struct EditorLockedOutlineView: View {

	let outline: Outline
	let onAuthenticated: () -> Void

	@State private var isAuthenticating = false
	@State private var errorMessage: String?
	@State private var groupHeight: CGFloat = 0

	var body: some View {
		GeometryReader { geometry in
			let totalHeight = geometry.size.height

			VStack(spacing: 0) {
				// Lock group centered vertically
				VStack(spacing: 20) {
					Image(systemName: "lock.fill")
						.font(.system(size: 48))
						.foregroundStyle(.secondary)

					Text(String.lockedOutlineLabel)
						.foregroundStyle(.secondary)

					if let errorMessage {
						Text(errorMessage)
							.font(.caption)
							.foregroundStyle(.red)
					}

					Button(String.unlockOutlineControlLabel) {
						authenticate()
					}
					.buttonStyle(.bordered)
					.disabled(isAuthenticating)
				}
				.background(GeometryReader { groupProxy in
					Color.clear.preference(key: GroupHeightKey.self, value: groupProxy.size.height)
				})
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.overlay(alignment: .top) {
				// Title centered between top of view and top of lock group
				Text(outline.title ?? .noTitleLabel)
					.font(.largeTitle)
					.fontWeight(.semibold)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity)
					.offset(y: max(0, (totalHeight - groupHeight) / 4))
			}
			.onPreferenceChange(GroupHeightKey.self) { height in
				groupHeight = height
			}
		}
	}

	private func authenticate() {
		isAuthenticating = true
		errorMessage = nil
		Task { @MainActor in
			do {
				try await LockSessionManager.shared.unlockOutline(outline)
				onAuthenticated()
			} catch {
				errorMessage = error.localizedDescription
			}
			isAuthenticating = false
		}
	}

}

private struct GroupHeightKey: PreferenceKey {
	static let defaultValue: CGFloat = 0
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}
