//
//  AppAssets.swift
//  Zavala
//
//  Created by Maurice Parker on 11/12/20.
//

import UIKit
import SwiftUI

struct ZavalaImageAssets {
	
	static var aboutBackgroundColor = Color("AboutBackgroundColor")
	static var accentColor = UIColor(named: "AccentColor")!
	static var accessoryColor = UIColor.tertiaryLabel
	static var add = UIImage(systemName: "plus")!
	
	static var barBackgroundColor = UIColor(named: "BarBackgroundColor")!
	static var bold = UIImage(systemName: "bold")!
	static var bullet = UIImage(systemName: "circle.fill")!.applyingSymbolConfiguration(.init(pointSize: 4, weight: .heavy))!

	static var collaborate = UIImage(systemName: "person.crop.circle.badge.plus")!
	static var collaborating = UIImage(systemName: "person.crop.circle.badge.checkmark")!
	static var collapseAll = UIImage(systemName: "arrow.down.right.and.arrow.up.left")!
	static var completeRow = UIImage(systemName: "checkmark.square")!
	static var copy = UIImage(systemName: "doc.on.doc")!
	static var createEntity = UIImage(systemName: "square.and.pencil")!
	static var cut = UIImage(systemName: "scissors")!

	static var delete = UIImage(systemName: "trash")!
	static var disclosure = {
		#if targetEnvironment(macCatalyst)
				return UIImage(systemName: "chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 9, weight: .heavy))!
		#else
				return UIImage(systemName: "chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 14, weight: .medium))!
		#endif
	}()
	static var documentLink = UIImage(named: "DocumentLink")!.applyingSymbolConfiguration(.init(pointSize: 24, weight: .medium))!
	static var duplicate = UIImage(systemName: "plus.square.on.square")!

	static var ellipsis = UIImage(systemName: "ellipsis.circle")!
	static var expandAll = UIImage(systemName: "arrow.up.left.and.arrow.down.right")!
	static var export = UIImage(systemName: "arrow.up.doc")!

	static var favoriteSelected = UIImage(systemName: "star.fill")!
	static var favoriteUnselected = UIImage(systemName: "star")!
	static var filterActive = UIImage(systemName: "line.horizontal.3.decrease.circle.fill")!
	static var filterInactive = UIImage(systemName: "line.horizontal.3.decrease.circle")!
	static var find = UIImage(systemName: "magnifyingglass")!
	static var format = UIImage(systemName: "textformat")!
	static var fullScreenBackgroundColor: UIColor = UIColor(named: "FullScreenBackgroundColor")!

	static var getInfo = UIImage(systemName: "info.circle")!
	static var goBackward = UIImage(systemName: "chevron.left")!
	static var goForward = UIImage(systemName: "chevron.right")!

	static var importDocument = UIImage(systemName: "square.and.arrow.down")!
	static var italic = UIImage(systemName: "italic")!

	static var hideKeyboard = UIImage(systemName: "keyboard.chevron.compact.down")!
	static var hideNotesActive = UIImage(systemName: "doc.text.fill")!
	static var hideNotesInactive = UIImage(systemName: "doc.text")!

	static var insertImage = UIImage(systemName: "photo")!

	static var link = UIImage(systemName: "link")!

	static var moveDown = UIImage(systemName: "arrow.down.to.line")!
	static var moveLeft = UIImage(systemName: "arrow.left.to.line")!
	static var moveRight = UIImage(systemName: "arrow.right.to.line")!
	static var moveUp = UIImage(systemName: "arrow.up.to.line")!

	static var newline = UIImage(systemName: "return")!
	static var noteAdd = UIImage(systemName: "doc.text")!
	static var noteDelete = UIImage(systemName: "doc.text.fill")!
	static var noteFont = UIImage(systemName: "textformat.size.smaller")!

	static var outline = UIImage(named: "Outline")!

	static var paste = UIImage(systemName: "doc.on.clipboard")!
	static var printDoc = UIImage(systemName: "printer")!
	static var printList = UIImage(systemName: "printer.dotmatrix")!
	
	static var redo = UIImage(systemName: "arrow.uturn.forward")!
	static var rename = UIImage(systemName: "pencil")!
	static var restore = UIImage(systemName: "gobackward")!

	static var share = UIImage(systemName: "square.and.arrow.up")!
	static var statelessCollaborate = UIImage(systemName: "person.crop.circle")!
	static var sync = UIImage(systemName: "arrow.clockwise")!

	static var topicFont = UIImage(systemName: "textformat.size.larger")!
	
	static var uncompleteRow = UIImage(systemName: "square")!
	static var undo = UIImage(systemName: "arrow.uturn.backward")!
	static var undoMenu = UIImage(systemName: "arrow.uturn.backward.circle.badge.ellipsis")!

	static var verticalBarColor: UIColor = .quaternaryLabel
	
}
