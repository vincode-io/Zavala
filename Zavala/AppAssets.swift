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
	
	static var acknowledgementsURL = "https://github.com/vincode-io/Zavala/wiki/Acknowledgements"

	static var add: UIImage = {
		return UIImage(systemName: "plus")!
	}()
	
	static var barBackgroundColor: UIColor = {
		return UIColor(named: "BarBackgroundColor")!
	}()

	static var bold: UIImage = {
		return UIImage(systemName: "bold")!
	}()
	
	static var bugTrackerURL = "https://github.com/vincode-io/Zavala/issues"

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

	static var getInfo: UIImage = {
		return UIImage(systemName: "info.circle")!
	}()
	
	static var githubRepositoryURL = "https://github.com/vincode-io/Zavala"

	static var importDocument: UIImage = {
		return UIImage(systemName: "square.and.arrow.down")!
	}()

	static var indent: UIImage = {
		return UIImage(systemName: "arrow.right.to.line")!
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

	static var moveUp: UIImage = {
		return UIImage(systemName: "arrow.up.to.line")!
	}()

	static var note: UIImage = {
		return UIImage(systemName: "doc.text")!
	}()

	static var noteFont: UIImage = {
		return UIImage(systemName: "textformat.size.smaller")!
	}()

	static var outdent: UIImage = {
		return UIImage(systemName: "arrow.left.to.line")!
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

	static var releaseNotesURL = "https://github.com/vincode-io/Zavala/releases/tag/\(Bundle.main.versionNumber)"
	
	static var removeEntity: UIImage = {
		return UIImage(systemName: "trash")!
	}()
	
	static var restore: UIImage = {
		return UIImage(systemName: "gobackward")!
	}()

	static var sendCopy: UIImage = {
		return UIImage(systemName: "square.and.arrow.up")!
	}()

	static var share: UIImage = {
		return UIImage(systemName: "person.crop.circle.badge.plus")!
	}()

	static var shared: UIImage = {
		return UIImage(systemName: "person.crop.circle.badge.checkmark")!
	}()

	static var statelessShare: UIImage = {
		return UIImage(systemName: "person.crop.circle")!
	}()

	static var sync: UIImage = {
		return UIImage(systemName: "arrow.clockwise")!
	}()

	static var topicFont: UIImage = {
		return UIImage(systemName: "textformat.size.larger")!
	}()

	static var uncompleteRow: UIImage = {
		return UIImage(systemName: "square")!
	}()

	static var verticalBar: UIColor = {
		return .quaternaryLabel
	}()
	
	static var websiteURL = "https://zavala.vincode.io"
	
}
