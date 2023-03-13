//
//  AppAssets.swift
//  Zavala
//
//  Created by Maurice Parker on 11/12/20.
//

import UIKit
import SwiftUI

struct AppAssets {
	
	static var accent: UIColor = {
		return UIColor(named: "AccentColor")!
	}()
	
	static var accessory: UIColor = {
		return .tertiaryLabel
	}()
	
	static var aboutPanelBackgroundColor: Color {
		return Color("AboutBackgroundColor")
	}
	
	static var acknowledgementsURL = URL(string: "https://github.com/vincode-io/Zavala/wiki/Acknowledgements")!

	static var add: UIImage = {
		return UIImage(systemName: "plus")!
	}()
	
	static var barBackgroundColor: UIColor = {
		return UIColor(named: "BarBackgroundColor")!
	}()

	static var bold: UIImage = {
		return UIImage(systemName: "bold")!
	}()
	
	static var bullet: UIImage = {
		return UIImage(systemName: "circle.fill")!.applyingSymbolConfiguration(.init(pointSize: 4, weight: .heavy))!
	}()

	static var collaborate: UIImage = {
		return UIImage(systemName: "person.crop.circle.badge.plus")!
	}()

	static var collaborating: UIImage = {
		return UIImage(systemName: "person.crop.circle.badge.checkmark")!
	}()

	static var collapseAll: UIImage = {
		return UIImage(systemName: "arrow.down.right.and.arrow.up.left")!
	}()

	static var completeRow: UIImage = {
		return UIImage(systemName: "checkmark.square")!
	}()

	static var copy: UIImage = {
		return UIImage(systemName: "doc.on.doc")!
	}()

	static var createEntity: UIImage = {
		return UIImage(systemName: "square.and.pencil")!
	}()
	
	static var cut: UIImage = {
		return UIImage(systemName: "scissors")!
	}()

	static var delete: UIImage = {
		return UIImage(systemName: "trash")!
	}()

	static var disclosure: UIImage = {
		#if targetEnvironment(macCatalyst)
		return UIImage(systemName: "chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 9, weight: .heavy))!
		#else
		return UIImage(systemName: "chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 14, weight: .medium))!
		#endif
	}()
	
	static var duplicate: UIImage = {
		return UIImage(systemName: "plus.square.on.square")!
	}()

	static var ellipsis: UIImage = {
		return UIImage(systemName: "ellipsis.circle")!
	}()

	static var expandAll: UIImage = {
		return UIImage(systemName: "arrow.up.left.and.arrow.down.right")!
	}()

	static var export: UIImage = {
		return UIImage(systemName: "arrow.up.doc")!
	}()

	static var favoriteSelected: UIImage = {
		return UIImage(systemName: "star.fill")!
	}()

	static var favoriteUnselected: UIImage = {
		return UIImage(systemName: "star")!
	}()

	static var filterActive: UIImage = {
		return UIImage(systemName: "line.horizontal.3.decrease.circle.fill")!
	}()

	static var filterInactive: UIImage = {
		return UIImage(systemName: "line.horizontal.3.decrease.circle")!
	}()

	static var find: UIImage = {
		return UIImage(systemName: "magnifyingglass")!
	}()
	
	static var fullScreenBackgroundColor: UIColor = {
		return UIColor(named: "FullScreenBackgroundColor")!
	}()

	static var getInfo: UIImage = {
		return UIImage(systemName: "info.circle")!
	}()
	
	static var goBackward: UIImage = {
		return UIImage(systemName: "chevron.left")!
	}()
	
	static var goForward: UIImage = {
		return UIImage(systemName: "chevron.right")!
	}()

	static var helpURL = "https://zavala.vincode.io/help/Zavala_Help.md/"
	
	static var importDocument: UIImage = {
		return UIImage(systemName: "square.and.arrow.down")!
	}()

	static var italic: UIImage = {
		return UIImage(systemName: "italic")!
	}()

	static var hideNotesActive: UIImage = {
		return UIImage(systemName: "doc.text.fill")!
	}()

	static var hideNotesInactive: UIImage = {
		return UIImage(systemName: "doc.text")!
	}()

	static var insertImage: UIImage = {
		return UIImage(systemName: "photo")!
	}()

	static var link: UIImage = {
		return UIImage(systemName: "link")!
	}()

	static var moveDown: UIImage = {
		return UIImage(systemName: "arrow.down.to.line")!
	}()

	static var moveLeft: UIImage = {
		return UIImage(systemName: "arrow.left.to.line")!
	}()

	static var moveRight: UIImage = {
		return UIImage(systemName: "arrow.right.to.line")!
	}()
	
	static var moveUp: UIImage = {
		return UIImage(systemName: "arrow.up.to.line")!
	}()

	static var note: UIImage = {
		return UIImage(systemName: "doc.text")!
	}()

	static var noteFont: UIImage = {
		return UIImage(systemName: "textformat.size.smaller")!
	}()

	static var paste: UIImage = {
		return UIImage(systemName: "doc.on.clipboard")!
	}()

	static var printDoc: UIImage = {
		return UIImage(systemName: "printer")!
	}()

	static var printList: UIImage = {
		return UIImage(systemName: "printer.dotmatrix")!
	}()

	static var rename: UIImage = {
		return UIImage(systemName: "pencil")!
	}()

	static var restore: UIImage = {
		return UIImage(systemName: "gobackward")!
	}()

	static var share: UIImage = {
		return UIImage(systemName: "square.and.arrow.up")!
	}()

	static var statelessCollaborate: UIImage = {
		return UIImage(systemName: "person.crop.circle")!
	}()

	static var sync: UIImage = {
		return UIImage(systemName: "arrow.clockwise")!
	}()

	static var topicFont: UIImage = {
		return UIImage(systemName: "textformat.size.larger")!
	}()

	static var reportAnIssueURL = URL(string: "mailto:mo@vincode.io")!
	
	static var uncompleteRow: UIImage = {
		return UIImage(systemName: "square")!
	}()

	static var verticalBar: UIColor = {
		return .quaternaryLabel
	}()
	
	static var websiteURL = URL(string: "https://zavala.vincode.io")!
	
}
