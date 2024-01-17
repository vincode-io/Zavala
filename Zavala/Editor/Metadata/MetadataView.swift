//
//  MetadataView.swift
//  Zavala
//
//  Created by Maurice Parker on 10/28/21.
//

import UIKit

class MetadataView: UIView {

	init(key: String, value: String, level: Int) {
		super.init(frame: .zero)
		
		let keyLabel = makeLabel(text: key, level: level)
		addSubview(keyLabel)
		
		let valueLabel = makeLabel(text: value, level: level)
		addSubview(valueLabel)
		valueLabel.frame = CGRect(x: keyLabel.bounds.width + 2, y: 0, width: valueLabel.bounds.width, height: valueLabel.bounds.height)
		
		let totalWidth = keyLabel.bounds.width + valueLabel.bounds.width + 2
		frame = CGRect(x: 0, y: 0, width: totalWidth, height: keyLabel.bounds.height)

		let maskView = UIView(frame: bounds)
		maskView.layer.cornerRadius = 5
		maskView.backgroundColor = .black
		mask = maskView
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

// MARK: Helpers

private extension MetadataView {
	
	func makeLabel(text: String, level: Int) -> UILabel {
		let keyLabel = InsetLabel(top: 1.0, left: 2.0, bottom: 1.0, right: 2.0)
		keyLabel.text = text
		keyLabel.textColor = .label
		keyLabel.font = OutlineFontCache.shared.metadataFont(level: level)
		keyLabel.backgroundColor = .systemGray4
		keyLabel.sizeToFit()
		return keyLabel
	}
	
}
