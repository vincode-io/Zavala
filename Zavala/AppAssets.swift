//
//  AppAssets.swift
//  Zavala
//
//  Created by Maurice Parker on 11/12/20.
//

import UIKit

struct AppAssets {
	
	static var accent: UIColor = {
		return UIColor(named: "AccentColor")!
	}()
	
	static var accessory: UIColor = {
		return .tertiaryLabel
	}()
	
	static var add: UIImage = {
		return UIImage(systemName: "plus")!
	}()
	
	static var bold: UIImage = {
		return UIImage(named: "Bold-Large")!
	}()
	
	static var bullet: UIImage = {
		return UIImage(systemName: "circle.fill")!.applyingSymbolConfiguration(.init(pointSize: 4, weight: .heavy))!
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
	
	static var expandAll: UIImage = {
		return UIImage(systemName: "arrow.up.left.and.arrow.down.right")!
	}()

	static var exportMarkdown: UIImage = {
		return UIImage(systemName: "doc.plaintext")!
	}()

	static var exportOPML: UIImage = {
		return UIImage(named: "OPML")!
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

	static var getInfoEntity: UIImage = {
		return UIImage(systemName: "info.circle")!
	}()

	static var importEntity: UIImage = {
		return UIImage(systemName: "square.and.arrow.down")!
	}()

	static var indent: UIImage = {
		return UIImage(systemName: "arrow.right.to.line")!
	}()
	
	static var italic: UIImage = {
		return UIImage(named: "Italic-Large")!
	}()

	static var hideNotesActive: UIImage = {
		return UIImage(systemName: "doc.text.fill")!
	}()

	static var hideNotesInactive: UIImage = {
		return UIImage(systemName: "doc.text")!
	}()

	static var link: UIImage = {
		return UIImage(named: "Link-Large")!
	}()

	static var note: UIImage = {
		return UIImage(systemName: "doc.text")!
	}()

	static var outdent: UIImage = {
		return UIImage(systemName: "arrow.left.to.line")!
	}()

	static var paste: UIImage = {
		return UIImage(systemName: "doc.on.clipboard")!
	}()

	static var removeEntity: UIImage = {
		return UIImage(systemName: "trash")!
	}()
	
	static var selectColor: UIColor = {
		return UIColor(named: "SelectColor")!
	}()

	static var sync: UIImage = {
		return UIImage(systemName: "arrow.clockwise")!
	}()

	static var uncompleteRow: UIImage = {
		return UIImage(systemName: "square")!
	}()


}
