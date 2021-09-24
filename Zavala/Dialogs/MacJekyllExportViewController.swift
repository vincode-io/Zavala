//
//  MacJekyllExportViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 4/15/21.
//

#if targetEnvironment(macCatalyst)

import UIKit
import Templeton

class MacJekyllExportViewController: MacFormViewController {
	
	enum PickerType {
		case root
		case posts
		case images
	}
	
	@IBOutlet weak var rootFolderTextField: EnhancedTextField!
	@IBOutlet weak var postsFolderTextField: EnhancedTextField!
	@IBOutlet weak var imagesFolderTextField: EnhancedTextField!
	@IBOutlet weak var exportButton: UIButton!
	
	weak var outline: Outline?
	
	private var currentPickerType: PickerType? = nil
	
	override func viewDidLoad() {
		exportButton.role = .primary
		rootFolderTextField.text = bookmarkToURL(AppDefaults.shared.jekyllRootBookmark)?.path
		postsFolderTextField.text = bookmarkToURL(AppDefaults.shared.jekyllPostsBookmark)?.path
		imagesFolderTextField.text = bookmarkToURL(AppDefaults.shared.jekyllImagesBookmark)?.path
	}
	
	@IBAction func chooseRootFolder(_ sender: Any) {
		currentPickerType = .root
		showDocumentPicker()
	}
	
	@IBAction func choosePostsFolder(_ sender: Any) {
		currentPickerType = .posts
		showDocumentPicker()
	}
	
	@IBAction func chooseImagesFolder(_ sender: Any) {
		currentPickerType = .images
		showDocumentPicker()
	}
	
	@IBAction override func submit(_ sender: Any) {
		guard let outline = outline,
			  let root = bookmarkToURL(AppDefaults.shared.jekyllRootBookmark),
			  let posts = bookmarkToURL(AppDefaults.shared.jekyllPostsBookmark),
			  let images = bookmarkToURL(AppDefaults.shared.jekyllImagesBookmark) else { return }
		
		outline.exportJekyllPost(root: root, posts: posts, images: images)
		dismiss(animated: true)
	}
	
}

extension MacJekyllExportViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
		
		defer { url.stopAccessingSecurityScopedResource() }
		
		let bookmarkData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
		
		switch currentPickerType! {
		case .root:
			rootFolderTextField.text = url.path
			AppDefaults.shared.jekyllRootBookmark = bookmarkData
		case .posts:
			postsFolderTextField.text = url.path
			AppDefaults.shared.jekyllPostsBookmark = bookmarkData
		case .images:
			imagesFolderTextField.text = url.path
			AppDefaults.shared.jekyllImagesBookmark = bookmarkData
		}
		
		currentPickerType = nil
		updateUI()
	}
	
}

// MARK: Helpers

extension MacJekyllExportViewController {
	
	private func bookmarkToURL(_ data: Data?) -> URL? {
		guard let data = data else { return nil }
		
		var isStale = false
		let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
		
		if !isStale {
			return url
		} else {
			return nil
		}
	}
	
	private func updateUI() {
		if rootFolderTextField.text == nil || postsFolderTextField.text == nil || imagesFolderTextField.text == nil {
			exportButton.isEnabled = false
		} else {
			exportButton.isEnabled = true
		}
	}
	
	private func showDocumentPicker() {
		var initialDirectory: URL? = nil
		if let path = rootFolderTextField.text {
			initialDirectory = URL(fileURLWithPath: path)
		}

		let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
		docPicker.delegate = self
		docPicker.modalPresentationStyle = .formSheet
		docPicker.allowsMultipleSelection = false
		docPicker.directoryURL = initialDirectory
		self.present(docPicker, animated: true)
	}
	
}

#endif
