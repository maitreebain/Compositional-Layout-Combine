//
//  ViewController.swift
//  Compositional-Layout-Combine
//
//  Created by Maitree Bain on 8/25/20.
//  Copyright © 2020 Maitree Bain. All rights reserved.
//

import UIKit
import Combine
import Kingfisher

class PhotoSearchViewController: UIViewController {
    
    enum SectionKind: Int, CaseIterable {
        case main
    }
    
    private var collectionView: UICollectionView!
    
    typealias DataSource = UICollectionViewDiffableDataSource<SectionKind, Photo>
    private var datasource: DataSource!
    
    private var searchController: UISearchController!
    
    //declare searchText property that listens for changes from the search bar (use @Publisher)
    //@Publisher is a property wrapper
    //to subscribe to the searchText's "Publisher" there needs to be a "$" prefixed
    //to searchText => $searchText
    
    @Published private var searchText = ""
    
    private var subscriptions: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Photo Search"
        configureCollectionView()
        configureDatasource()
        initSearchController()
        
       $searchText
         .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
         .removeDuplicates()
         .sink { [weak self] (text) in // .assign
           self?.searchPhotos(for: text)
           // call the api client for the photo search queue
         }
         .store(in: &subscriptions)
    }
    
    private func searchPhotos(for query: String) {
      // searchPhotos is a `Publisher`
      APIClient().searchPhotos(for: query)
        .sink(receiveCompletion: { (completion) in
          print(completion)
        }) { [weak self] (photos) in
          self?.updateSnapshot(with: photos)
        }
        .store(in: &subscriptions)
    }
    
    private func updateSnapshot(with photos: [Photo]) {
      var snapshot = datasource.snapshot()
      snapshot.deleteAllItems()
      snapshot.appendSections([.main])
      snapshot.appendItems(photos)
      datasource.apply(snapshot, animatingDifferences: false)
    }
    
    private func initSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        //same controller so nil
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.obscuresBackgroundDuringPresentation = false
    }
    
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: configureLayout())
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        collectionView.backgroundColor = .darkGray
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
    }
    
    private func configureLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let itemSpacing: CGFloat = 5
            item.contentInsets = NSDirectionalEdgeInsets(top: itemSpacing, leading: itemSpacing, bottom: itemSpacing, trailing: itemSpacing)
            let innerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.50), heightDimension: .fractionalHeight(1.0))
            let leadingGroup = NSCollectionLayoutGroup.vertical(layoutSize: innerGroupSize, subitem: item, count: 2)
            let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: innerGroupSize, subitem: item, count: 3)
            let nestedGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1000.0))
            let nestedGroup = NSCollectionLayoutGroup.horizontal(layoutSize: nestedGroupSize, subitems: [leadingGroup, trailingGroup])
            //order matters
            let section = NSCollectionLayoutSection(group: nestedGroup)
            return section
        }
        
        return layout
    }
    
    private func configureDatasource() {
        
        datasource = DataSource(collectionView: collectionView, cellProvider: { (collectionView, indexPath, photo) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath) as? ImageCell else {
                fatalError("could not dequeue ImageCell")
            }
            
            cell.imageView.kf.indicatorType = .activity
            cell.imageView.kf.setImage(with: URL(string: photo.webformatURL))
            cell.imageView.contentMode = .scaleAspectFill
            return cell
        })
        
        //setup initial snapshot
        
        var snapshot = datasource.snapshot()
        snapshot.appendSections([.main])
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
}

extension PhotoSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty else {
            return
        }
        
        searchText = text
    }
    
    
    
    
}
