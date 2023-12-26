//
//  FontsView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/26/23.
//

import SwiftUI

struct FontsView: UIViewControllerRepresentable {

	func makeUIViewController(context: Context) -> SettingsFontViewController {
		return UIStoryboard.settings.instantiateInitialViewController() as! SettingsFontViewController
	}
	
	func updateUIViewController(_ uiViewController: SettingsFontViewController, context: Context) {
		
	}
}

#Preview {
    FontsView()
}
