//
//  MacJekyllExportViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 4/15/21.
//

import UIKit

protocol JekyllExportViewControllerDelegate: AnyObject {
	func exportJekyll(root: URL, posts: URL, images: URL)
}

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
	
	weak var delegate: JekyllExportViewControllerDelegate?
	
	private var currentPickerType: PickerType? = nil
	
	override func viewDidLoad() {
		rootFolderTextField.text = AppDefaults.shared.jekyllRootFolder
		postsFolderTextField.text = AppDefaults.shared.jekyllPostsFolder
		imagesFolderTextField.text = AppDefaults.shared.jekyllImagesFolder
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
		guard let rootURL = rootFolderTextField.text,
			  let postsURL = postsFolderTextField.text,
			  let imagesURL = imagesFolderTextField.text else { return }

		let root = URL(fileURLWithPath: rootURL)
		let posts = URL(fileURLWithPath: postsURL)
		let images = URL(fileURLWithPath: imagesURL)
		delegate?.exportJekyll(root: root, posts: posts, images: images)
		
		dismiss(animated: true)
	}
	
}

extension MacJekyllExportViewController: UIDocumentPickerDelegate {
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let url = urls.first else { return }
		
		switch currentPickerType! {
		case .root:
			rootFolderTextField.text = url.path
			AppDefaults.shared.jekyllRootFolder = url.path
		case .posts:
			postsFolderTextField.text = url.path
			AppDefaults.shared.jekyllPostsFolder = url.path
		case .images:
			imagesFolderTextField.text = url.path
			AppDefaults.shared.jekyllImagesFolder = url.path
		}
		
		currentPickerType = nil
		updateUI()
	}
	
}

// MARK: Helpers

extension MacJekyllExportViewController {
	
	private func updateUI() {
		if rootFolderTextField.text == nil || postsFolderTextField.text == nil || imagesFolderTextField.text == nil {
			exportButton.isEnabled = false
		} else {
			exportButton.isEnabled = true
		}
	}
	
	private func showDocumentPicker() {
		let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
		docPicker.delegate = self
		docPicker.modalPresentationStyle = .formSheet
		docPicker.allowsMultipleSelection = false
		self.present(docPicker, animated: true)
	}
	
}
