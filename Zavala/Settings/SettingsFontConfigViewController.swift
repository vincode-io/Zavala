//
//  SettingsFontConfigViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/26/21.
//

import UIKit

protocol SettingsFontConfigViewControllerDelegate: AnyObject {
	func didUpdateConfig(field: OutlineFontField, config: OutlineFontConfig)
}

class SettingsFontConfigViewController: UITableViewController {

	var field: OutlineFontField?
	var config: OutlineFontConfig?
	
	@IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
	@IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
	
	@IBOutlet weak var fontButton: UIButton!
	@IBOutlet weak var fontValueStepper: ValueStepper!
	@IBOutlet weak var sampleTextLabel: UILabel!
	
	var cancelButton: UIButton!
	var saveButton: UIButton!

	override func viewDidLoad() {
        super.viewDidLoad()
		
		if let field,
			let outlineFonts = AppDefaults.shared.outlineFonts,
			!outlineFonts.rowFontConfigs.keys.contains(field) {
			saveBarButtonItem.title = .addControlLabel
		}
		
		if UIDevice.current.userInterfaceIdiom == .mac {
			fontValueStepper.widthAnchor.constraint(equalToConstant: 80).isActive = true
			fontValueStepper.heightAnchor.constraint(equalToConstant: 19).isActive = true

			cancelBarButtonItem.isHidden = true
			saveBarButtonItem.isHidden = true
			
			cancelButton = UIButton(type: .system)
			cancelButton.setTitle(.cancelControlLabel, for: .normal)
			cancelButton.isAccessibilityElement = true
			cancelButton.addTarget(self, action: #selector(cancel(_:)), for: .touchUpInside)
			cancelButton.role = .cancel

			saveButton = UIButton(type: .system)
			saveButton.setTitle(.saveControlLabel, for: .normal)
			saveButton.isAccessibilityElement = true
			saveButton.addTarget(self, action: #selector(save(_:)), for: .touchUpInside)
			saveButton.role = .primary

		} else {
			fontValueStepper.widthAnchor.constraint(equalToConstant: 149).isActive = true
			fontValueStepper.heightAnchor.constraint(equalToConstant: 29).isActive = true
		}
		
		navigationItem.title = field?.displayName
		fontButton.setTitle(config?.name, for: .normal)
		fontValueStepper.value = Double(config?.size ?? 0)
		
		updateUI()
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
	}
	
	override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
		return UITableView.automaticDimension
	}
	
	override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		guard UIDevice.current.userInterfaceIdiom == .mac && section == 1 else { return nil }
		
		let footer = UIStackView()
		footer.isLayoutMarginsRelativeArrangement = true
		footer.spacing = 8
		footer.layoutMargins.top = 24
		footer.addArrangedSubview(UIView())
		footer.addArrangedSubview(cancelButton)
		footer.addArrangedSubview(saveButton)
		
		return footer
	}
	
	@IBAction func changeFont(_ sender: Any) {
		let controller = UIFontPickerViewController()
		controller.delegate = self
		present(controller, animated: true)
	}
	
	@IBAction func fontSizeChanged(_ sender: Any) {
		let stepValue = Int(fontValueStepper.value)
		config?.size = stepValue
		updateUI()
	}
	
	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func save(_ sender: Any) {
		guard let field = field, let config = config else { return }
		
		var fontDefaults = AppDefaults.shared.outlineFonts
		fontDefaults?.rowFontConfigs[field] = config
		AppDefaults.shared.outlineFonts = fontDefaults

		dismiss(animated: true)
	}
	
}

// MARK: UIFontPickerViewControllerDelegate

extension SettingsFontConfigViewController: UIFontPickerViewControllerDelegate {
	
	func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
		guard let fontName = viewController.selectedFontDescriptor?.fontAttributes[.family] as? String else { return }
		viewController.dismiss(animated: true)
		fontButton.setTitle(fontName, for: .normal)
		config?.name = fontName
		updateUI()
	}
	
}

// MARK: Helpers

private extension SettingsFontConfigViewController {

	func updateUI() {
		guard let config = config, let font = UIFont(name: config.name, size: CGFloat(config.size)) else { return }
		sampleTextLabel.font = font
		tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
	}

}
