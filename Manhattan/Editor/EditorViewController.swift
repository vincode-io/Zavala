//
//  DetailViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import RSCore
import Templeton

class EditorViewController: UICollectionViewController {

	public var isToggleFavoriteUnavailable: Bool {
		return outline == nil
	}
	
	var outline: Outline? {
		didSet {
			guard isViewLoaded else { return }
			if oldValue != outline {
				loadOutline()
				updateUI()
				applySnapshot(animated: false)
			}
		}
	}
	
	private func loadOutline() {
		guard let outline = outline else { return }
		
		var headlines = [Headline]()
		
		let headline1 = Headline(plainText: "Headline 1")
		headlines.append(headline1)
		
		let headline11 = Headline(plainText: "Headline 1.1")
		headline1.headlines?.append(headline11)
		let headline111 = Headline(plainText: "Headline 1.1.1")
		headline11.headlines?.append(headline111)

		headline111.headlines?.append(Headline(plainText: "Headline 1.1.1.1"))
		headline111.headlines?.append(Headline(plainText: "Headline 1.1.1.2"))
		headline111.headlines?.append(Headline(plainText: "Headline 1.1.1.3"))

		headline11.headlines?.append(Headline(plainText: "Headline 1.1.2"))
		headline11.headlines?.append(Headline(plainText: "Headline 1.1.3"))

		headline1.headlines?.append(Headline(plainText: "Headline 1.2"))
		headline1.headlines?.append(Headline(plainText: "Headline 1.3"))
		
		let headline2 = Headline(plainText: "Headline 2")
		headlines.append(headline2)
		headline2.headlines?.append(Headline(plainText: "Headline 2.1"))
		headline2.headlines?.append(Headline(plainText: "Headline 2.2"))
		headline2.headlines?.append(Headline(plainText: "Headline 2.3"))
		
		let headline3 = Headline(plainText: "Headline 3")
		headlines.append(headline3)
		headline3.headlines?.append(Headline(plainText: "Headline 3.1"))
		headline3.headlines?.append(Headline(plainText: "Headline 3.2"))
		headline3.headlines?.append(Headline(plainText: "Headline 3.3"))
		
		outline.headlines = headlines
	}
	
	private var favoriteBarButtonItem: UIBarButtonItem?
	
	private var dataSource: UICollectionViewDiffableDataSource<Int, EditorItem>!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			favoriteBarButtonItem = UIBarButtonItem(image: AppAssets.favoriteUnselected, style: .plain, target: self, action: #selector(toggleOutlineIsFavorite(_:)))
			navigationItem.rightBarButtonItem = favoriteBarButtonItem
		}
		
		loadOutline()
		
		collectionView.allowsSelection = false
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applySnapshot(animated: false)

		updateUI()
	}

	// MARK: Actions
	@objc func toggleOutlineIsFavorite(_ sender: Any?) {
		outline?.toggleFavorite(completion: { result in
			if case .failure(let error) = result {
				self.presentError(error)
			}
			self.updateUI()
		})
	}
	
}

// MARK: Collection View

extension EditorViewController {
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
			configuration.showsSeparators = false
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	private func configureDataSource() {
		let groupRegistration = UICollectionView.CellRegistration<EditorCollectionViewCell, EditorItem> { (cell, indexPath, item) in
			cell.accessories = [.outlineDisclosure(options: .init(style: .cell))]
			cell.editableText = item.plainText
		}

		let individualRegistration = UICollectionView.CellRegistration<EditorCollectionViewCell, EditorItem> { (cell, indexPath, item) in
			cell.editableText = item.plainText
		}

		dataSource = UICollectionViewDiffableDataSource<Int, EditorItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			if item.children.isEmpty {
				return collectionView.dequeueConfiguredReusableCell(using: individualRegistration, for: indexPath, item: item)
			} else {
				return collectionView.dequeueConfiguredReusableCell(using: groupRegistration, for: indexPath, item: item)
			}
		}
	}
	
	private func applySnapshot(animated: Bool) {
		var snapshot = NSDiffableDataSourceSectionSnapshot<EditorItem>()
		
		if let items = outline?.headlines?.map({ EditorItem.editorItem($0) }) {
			snapshot.append(items)
			applySnapshot(&snapshot, items: items)
		}
		
		dataSource.apply(snapshot, to: 0, animatingDifferences: animated)
	}
	
	private func applySnapshot( _ snapshot: inout NSDiffableDataSourceSectionSnapshot<EditorItem>, items: [EditorItem]) {
		for item in items {
			snapshot.append(item.children, to: item)
			if !item.children.isEmpty {
				applySnapshot(&snapshot, items: item.children)
			}
		}
	}
	
}

// MARK: Helpers

private extension EditorViewController {
	
	private func updateUI() {
		navigationItem.title = outline?.name
		navigationItem.largeTitleDisplayMode = .never
		
		if outline?.isFavorite ?? false {
			favoriteBarButtonItem?.image = AppAssets.favoriteSelected
		} else {
			favoriteBarButtonItem?.image = AppAssets.favoriteUnselected
		}
	}
	
}
