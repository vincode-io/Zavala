//
//  LockedOutlineView.swift
//  Zavala
//
//  Created by Maurice Parker on 3/8/26.
//

import SwiftUI
import VinOutlineKit

struct LockedOutlineView: View {

	let outline: Outline
	let onAuthenticated: () -> Void

	@State private var isAuthenticating = false
	@State private var errorMessage: String?

	var body: some View {
		VStack(spacing: 20) {
			Spacer()

			Image(systemName: "lock.fill")
				.font(.system(size: 48))
				.foregroundStyle(.secondary)

			Text(String.lockedOutlineLabel)
				.font(.headline)
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

			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
//		.onAppear {
//			authenticate()
//		}
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
