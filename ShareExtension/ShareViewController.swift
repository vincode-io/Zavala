//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Maurice Parker on 8/5/26.
//

import UIKit
import UniformTypeIdentifiers

/// A minimal, UI-less Share extension. It grabs the shared web page URL, hands it off to the main
/// app via the shared app group queue, nudges the app to open, and immediately completes so the
/// share sheet dismisses. The heavy lifting (download, Readability, building the Outline, saving to
/// CloudKit) happens in the app.
class ShareViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .clear
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
