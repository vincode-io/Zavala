//
//  AppAssets.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/12/20.
//

import UIKit

struct AppAssets {
	
	static var accent: UIColor = {
		return UIColor(named: "AccentColor")!
	}()
	
	static var add: UIImage = {
		return UIImage(systemName: "plus")!
	}()
	
	static var bullet: UIImage = {
		return UIImage(systemName: "circle.fill")!.applyingSymbolConfiguration(.init(pointSize: 4, weight: .heavy))!
	}()

	static var completeHeadline: UIImage = {
		return UIImage(systemName: "checkmark.square")!
	}()

	static var createEntity: UIImage = {
		return UIImage(systemName: "square.and.pencil")!
	}()

	static var delete: UIImage = {
		return UIImage(systemName: "trash")!
	}()

	static var disclosure: UIImage = {
		#if targetEnvironment(macCatalyst)
		return UIImage(systemName: "chevron.right")!.applyingSymbolConfiguration(.init(pointSize: 9, weight: .heavy))!
		#else
		return UIImage(systemName: "chevron.right")!.applyingSymbolConfiguration(.init(pointSize: 14, weight: .medium))!
		#endif
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

	static var outdent: UIImage = {
		return UIImage(systemName: "arrow.left.to.line")!
	}()

	static var removeEntity: UIImage = {
		return UIImage(systemName: "trash")!
	}()

	static var uncompleteHeadline: UIImage = {
		return UIImage(systemName: "square")!
	}()


}
