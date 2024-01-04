//
//  UICollectionView+.swift
//  Zavala
//
//  Created by Maurice Parker on 1/12/21.
//

import UIKit

public extension UICollectionView {

    func deselectAll(animated: Bool = true) {
		indexPathsForSelectedItems?.forEach { indexPath in
			deselectItem(at: indexPath, animated: animated)
		}
	}

	func isVisible(indexPath: IndexPath) -> Bool {
		guard let cell = cellForItem(at: indexPath) else { return false }
		return bounds.contains(convert(cell.frame, to: self))
	}
}
