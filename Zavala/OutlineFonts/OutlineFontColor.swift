//
//  OutlineFontColor.swift
//  Zavala
//
//  Created by Maurice Parker on 1/22/24.
//

import UIKit

enum OutlineFontColor: Int, CustomStringConvertible, CaseIterable {
	case primaryText
	case secondaryText
	case tertiaryText
	case quaternaryText
	case red
	case green
	case blue
	case orange
	case yellow
	case pink
	case purple
	case teal
	case indigo
	case brown
	case mint
	case cyan

	var uiColor: UIColor {
		switch self {
		case .primaryText:
			return .label
		case .secondaryText:
			return .secondaryLabel
		case .tertiaryText:
			return .tertiaryLabel
		case .quaternaryText:
			return .quaternaryLabel
		case .red:
			return .systemRed
		case .green:
			return .systemGreen
		case .blue:
			return .systemBlue
		case .orange:
			return .systemOrange
		case .yellow:
			return .systemYellow
		case .pink:
			return .systemPink
		case .purple:
			return .systemPurple
		case .teal:
			return .systemTeal
		case .indigo:
			return .systemIndigo
		case .brown:
			return .systemBrown
		case .mint:
			return .systemMint
		case .cyan:
			return .systemCyan
		}
	}
	
	var description: String {
		switch self {
		case .primaryText:
			return .primaryTextControlLabel
		case .secondaryText:
			return .secondaryTextControlLabel
		case .tertiaryText:
			return .tertiaryTextControlLabel
		case .quaternaryText:
			return .quaternaryTextControlLabel
		case .red:
			return .redControlLabel
		case .green:
			return .greenControlLabel
		case .blue:
			return .blueControlLabel
		case .orange:
			return .orangeControlLabel
		case .yellow:
			return .yellowControlLabel
		case .pink:
			return .pinkControlLabel
		case .purple:
			return .purpleControlLabel
		case .teal:
			return .tealControlLabel
		case .indigo:
			return .indigoControlLabel
		case .brown:
			return .brownControlLabel
		case .mint:
			return .mintControlLabel
		case .cyan:
			return .cyanControlLabel

		}
	}
	
}
