//
//  EditorViewController+Drag.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/1/20.
//

import UIKit

extension EditorViewController: UICollectionViewDragDelegate {
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		guard let headline = outline?.shadowTable?[indexPath.row] else { return [UIDragItem]() }
		
		session.localContext = headline
		
		let itemProvider = NSItemProvider()
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = headline
		return [dragItem]
	}
	
}
