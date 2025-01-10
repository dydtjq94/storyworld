//
//  CollectionViewController.swift
//  Storyworld
//
//  Created by peter on 1/10/25.
//

import UIKit

final class CollectionViewController: UIViewController {
    private var movies: [Movie] = []
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 120, height: 200)
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadMovies()
    }

    private func setupView() {
           title = "My Collection"
           view.backgroundColor = .white

           collectionView.backgroundColor = .white
           collectionView.register(CollectionCellView.self, forCellWithReuseIdentifier: CollectionCellView.reuseIdentifier)
           collectionView.dataSource = self
           collectionView.delegate = self
           collectionView.translatesAutoresizingMaskIntoConstraints = false

           view.addSubview(collectionView)
           NSLayoutConstraint.activate([
               collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
               collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
               collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
               collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
           ])
       }

    private func loadMovies() {
        // UserDefaults에서 영화 데이터 로드
        if let loadedMovies = UserDefaults.standard.loadMovies() {
            movies = loadedMovies
            collectionView.reloadData()
        }
    }
}

extension CollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionCellView.reuseIdentifier, for: indexPath) as? CollectionCellView else {
            return UICollectionViewCell()
        }
        let movie = movies[indexPath.item]
        cell.configure(with: movie)
        return cell
    }
}
