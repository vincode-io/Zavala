//
//  UICollectionView+.swift
//  Zavala
//
//  Created by Maurice Parker on 1/12/21.
//

import UIKit

extension UICollectionView {

    func deselectAll(animated: Bool = true) {
		indexPathsForSelectedItems?.forEach { indexPath in
			deselectItem(at: indexPath, animated: animated)
		}
	}

}
