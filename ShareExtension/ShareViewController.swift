//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Maurice Parker on 8/5/26.
//

import UIKit
import UniformTypeIdentifiers

/// A lightweight Share extension. It grabs the shared web page URL, hands it off to the main
/// app via the shared app group queue, briefly shows a "Sent!" confirmation, and then completes
/// so the share sheet dismisses. The heavy lifting (download, Readability, building the Outline,
/// saving to CloudKit) happens in the app.
class ShareViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		view.layer.cornerRadius = 8
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		Task {
			await handleShare()
		}
	}

	private func handleShare() async {
		// Always complete the request so the host's share sheet dismisses, no matter what.
		defer {
			extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
		}

		guard let url = await extractURL() else { return }

		WebImportQueue.enqueue(url)

		await showSentConfirmation()
	}

	/// Briefly shows a "Sent!" pill so the person gets confirmation before the share sheet dismisses.
	private func showSentConfirmation() async {
		let pill = UIVisualEffectView(effect: UIGlassEffect())
		pill.cornerConfiguration = .capsule()
		pill.translatesAutoresizingMaskIntoConstraints = false

		let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
		checkmarkImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title2)
		checkmarkImageView.tintColor = .systemGreen

		let sentLabel = UILabel()
		sentLabel.text = String(localized: "Sent!", comment: "Confirmation message shown after a shared link is sent to Zavala")
		sentLabel.font = .preferredFont(forTextStyle: .headline)
		sentLabel.adjustsFontForContentSizeCategory = true

		let stackView = UIStackView(arrangedSubviews: [checkmarkImageView, sentLabel])
		stackView.axis = .horizontal
		stackView.alignment = .center
		stackView.spacing = 8
		stackView.translatesAutoresizingMaskIntoConstraints = false

		pill.contentView.addSubview(stackView)
		view.addSubview(pill)

		NSLayoutConstraint.activate([
			stackView.topAnchor.constraint(equalTo: pill.contentView.topAnchor, constant: 16),
			stackView.bottomAnchor.constraint(equalTo: pill.contentView.bottomAnchor, constant: -16),
			stackView.leadingAnchor.constraint(equalTo: pill.contentView.leadingAnchor, constant: 24),
			stackView.trailingAnchor.constraint(equalTo: pill.contentView.trailingAnchor, constant: -24),
			pill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			pill.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])

		pill.alpha = 0
		pill.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

		await withCheckedContinuation { continuation in
			UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
				pill.alpha = 1
				pill.transform = .identity
			} completion: { _ in
				continuation.resume()
			}
		}

		// Let the confirmation linger long enough to be read before the sheet dismisses.
		try? await Task.sleep(for: .seconds(1))
	}

	private func extractURL() async -> URL? {
		guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
			return nil
		}

		// Prefer a real URL attachment.
		for item in items {
			for provider in item.attachments ?? [] where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
				if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL,
				   let scheme = url.scheme, scheme.hasPrefix("http") {
					return url
				}
				if let data = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? Data, let url = URL(dataRepresentation: data, relativeTo: nil),
				   let scheme = url.scheme, scheme.hasPrefix("http") {
					return url
				}
			}
		}

		// Fall back to plain text that happens to be a URL.
		for item in items {
			for provider in item.attachments ?? [] where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
				if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String,
				   let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
				   let scheme = url.scheme, scheme.hasPrefix("http") {
					return url
				}
			}
		}

		return nil
	}

}
