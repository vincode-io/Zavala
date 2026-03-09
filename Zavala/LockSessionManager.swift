//
//  LockSessionManager.swift
//  Zavala
//
//  Created by Maurice Parker on 3/8/26.
//

import UIKit
import LocalAuthentication
import CryptoKit
import VinOutlineKit

extension Notification.Name {
	static let LockSessionDidClose = Notification.Name("LockSessionDidClose")
	static let LockSessionDidOpen = Notification.Name("LockSessionDidOpen")
}

@MainActor
final class LockSessionManager {

	static let shared = LockSessionManager()

	private(set) var unlockedOutlineIDs = Set<EntityID>()

	private var backgroundEnteredDate: Date?

	#if targetEnvironment(macCatalyst)
	private let backgroundTimeoutInterval: TimeInterval = 8 * 60
	#else
	private let backgroundTimeoutInterval: TimeInterval = 3 * 60
	#endif

	private init() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appDidEnterBackground),
			name: UIApplication.didEnterBackgroundNotification,
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appWillEnterForeground),
			name: UIApplication.willEnterForegroundNotification,
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(deviceDidLock),
			name: UIApplication.protectedDataWillBecomeUnavailableNotification,
			object: nil
		)
	}

	// MARK: - Session State

	func isUnlocked(_ outlineID: EntityID) -> Bool {
		return unlockedOutlineIDs.contains(outlineID)
	}

	func markUnlocked(_ outlineID: EntityID) {
		unlockedOutlineIDs.insert(outlineID)
		NotificationCenter.default.post(name: .LockSessionDidOpen, object: outlineID)
	}

	func lock(_ outlineIDs: Set<EntityID>) {
		let affectedIDs = unlockedOutlineIDs.intersection(outlineIDs)
		guard !affectedIDs.isEmpty else { return }
		unlockedOutlineIDs.subtract(affectedIDs)
		NotificationCenter.default.post(name: .LockSessionDidClose, object: affectedIDs)
	}

	func lockNow() {
		let affectedIDs = unlockedOutlineIDs
		unlockedOutlineIDs.removeAll()
		NotificationCenter.default.post(name: .LockSessionDidClose, object: affectedIDs)
	}

	// MARK: - Authentication

	nonisolated func authenticate(reason: String) async throws {
		let context = LAContext()
		var error: NSError?
		guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
			throw LockError.authenticationFailed
		}
		let success = try await context.evaluatePolicy(
			.deviceOwnerAuthentication,
			localizedReason: reason
		)
		guard success else {
			throw LockError.authenticationFailed
		}
	}

	/// Unlock an outline: authenticate and mark as unlocked.
	/// The encryption service is set eagerly during `Outline.load()` via the `encryptionServiceProvider`,
	/// so it doesn't need to be configured here.
	func unlockOutline(_ outline: Outline) async throws {
		try await authenticate(reason: String(localized: "Unlock \(outline.title ?? "Outline")", comment: "Auth prompt: Unlock outline"))
		markUnlocked(outline.id)
	}

	// MARK: - Notification Handlers

	@objc private func appDidEnterBackground() {
		backgroundEnteredDate = Date()
	}

	@objc private func appWillEnterForeground() {
		guard let date = backgroundEnteredDate else { return }
		let elapsed = Date().timeIntervalSince(date)
		if elapsed >= backgroundTimeoutInterval {
			lockNow()
		}
		backgroundEnteredDate = nil
	}

	@objc private func deviceDidLock() {
		lockNow()
	}

}
