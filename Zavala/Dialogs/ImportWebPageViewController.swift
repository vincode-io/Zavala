//
//  ImportWebPageViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 8/6/26.
//

import UIKit

/// A sheet that prompts for a web page address to import, presented within the main window. It uses
/// a macOS-style panel (a field with Cancel/Import buttons along the bottom) on the Mac and a
/// navigation-bar form sheet on iOS, mirroring the Link dialog. (Single-outline editor windows use a
/// native AppKit prompt via the AppKitPlugin instead.)
final class ImportWebPageViewController: UIViewController, UITextFieldDelegate {

	var prefilledURLString: String?
	var onImport: ((URL) -> Void)?

	override var keyCommands: [UIKeyCommand]? {
		guard traitCollection.userInterfaceIdiom == .mac else { return nil }
		return [
			UIKeyCommand(action: #selector(cancel(_:)), input: UIKeyCommand.inputEscape),
			UIKeyCommand(action: #selector(submit(_:)), input: "\r"),
		]
	}

	private let urlTextField = UITextField()
	private var importButton: UIButton?
	private lazy var importBarButtonItem = UIBarButtonItem(title: .importControlLabel,
														   image: nil,
														   primaryAction: UIAction { [weak self] _ in self?.submitAndDismiss() },
														   menu: nil)

	override func viewDidLoad() {
		super.viewDidLoad()

		title = .importWebPageControlLabel
		view.backgroundColor = .systemBackground

		urlTextField.placeholder = "https://example.com"
		urlTextField.keyboardType = .URL
		urlTextField.autocapitalizationType = .none
		urlTextField.autocorrectionType = .no
		urlTextField.clearButtonMode = .whileEditing
		urlTextField.borderStyle = .roundedRect
		urlTextField.returnKeyType = .go
		urlTextField.delegate = self
		urlTextField.text = prefilledURLString
		urlTextField.addAction(UIAction { [weak self] _ in self?.updateImportEnabledState() }, for: .editingChanged)
		urlTextField.translatesAutoresizingMaskIntoConstraints = false

		if traitCollection.userInterfaceIdiom == .mac {
			setupMacLayout()
		} else {
			setupPhoneLayout()
		}

		updateImportEnabledState()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		urlTextField.becomeFirstResponder()
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		submitAndDismiss()
		return false
	}

	@objc func cancel(_ sender: Any?) {
		dismiss(animated: true)
	}

	@objc func submit(_ sender: Any?) {
		submitAndDismiss()
	}

}

// MARK: - Layout

private extension ImportWebPageViewController {

	func setupPhoneLayout() {
		navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
			self?.dismiss(animated: true)
		})
		navigationItem.rightBarButtonItem = importBarButtonItem

		let messageLabel = makeMessageLabel()

		view.addSubview(messageLabel)
		view.addSubview(urlTextField)

		let margins = view.layoutMarginsGuide
		NSLayoutConstraint.activate([
			messageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
			messageLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
			messageLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),

			urlTextField.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 12),
			urlTextField.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
			urlTextField.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
		])
	}

	func setupMacLayout() {
		let messageLabel = makeMessageLabel()

		var cancelConfiguration = UIButton.Configuration.bordered()
		cancelConfiguration.title = .cancelControlLabel
		let cancelButton = UIButton(configuration: cancelConfiguration, primaryAction: UIAction { [weak self] _ in
			self?.dismiss(animated: true)
		})

		var importConfiguration = UIButton.Configuration.borderedProminent()
		importConfiguration.title = .importControlLabel
		let importButton = UIButton(configuration: importConfiguration, primaryAction: UIAction { [weak self] _ in
			self?.submitAndDismiss()
		})
		self.importButton = importButton

		let buttonStack = UIStackView(arrangedSubviews: [cancelButton, importButton])
		buttonStack.axis = .horizontal
		buttonStack.spacing = 12
		buttonStack.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(messageLabel)
		view.addSubview(urlTextField)
		view.addSubview(buttonStack)

		let margins = view.layoutMarginsGuide
		NSLayoutConstraint.activate([
			messageLabel.topAnchor.constraint(equalTo: margins.topAnchor, constant: 16),
			messageLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
			messageLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),

			urlTextField.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 10),
			urlTextField.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
			urlTextField.trailingAnchor.constraint(equalTo: margins.trailingAnchor),

			buttonStack.topAnchor.constraint(greaterThanOrEqualTo: urlTextField.bottomAnchor, constant: 16),
			buttonStack.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
			buttonStack.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -16),
		])
	}

	func makeMessageLabel() -> UILabel {
		let messageLabel = UILabel()
		messageLabel.text = .importWebPagePromptMessage
		messageLabel.font = .preferredFont(forTextStyle: .body)
		messageLabel.textColor = .secondaryLabel
		messageLabel.numberOfLines = 0
		messageLabel.translatesAutoresizingMaskIntoConstraints = false
		return messageLabel
	}

	var enteredURL: URL? {
		let text = urlTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		guard let url = URL(string: text), let scheme = url.scheme, scheme.hasPrefix("http") else {
			return nil
		}
		return url
	}

	func updateImportEnabledState() {
		let isEnabled = enteredURL != nil
		if traitCollection.userInterfaceIdiom == .mac {
			importButton?.isEnabled = isEnabled
		} else {
			importBarButtonItem.isEnabled = isEnabled
		}
	}

	func submitAndDismiss() {
		guard let url = enteredURL else { return }
		dismiss(animated: true) { [onImport] in
			onImport?(url)
		}
	}

}
