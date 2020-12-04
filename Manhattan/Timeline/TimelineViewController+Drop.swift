//
//  TimelineViewController+Drop.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit

extension TimelineViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		return false
	}
		
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		
	}
	
}
