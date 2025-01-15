//
//  CollectionManager.swift
//  Storyworld
//
//  Created by peter on 1/10/25.
//

import Foundation

final class CollectionManager {
    static let shared = CollectionManager()
    private let collectionKey = "UserMovieCollection"

    private init() {}

    /// 저장된 영화 컬렉션을 가져오기
    func loadCollection() -> [TMDbNamespace.TMDbMovieModel] {
        return UserDefaults.standard.getObject(forKey: collectionKey, as: [TMDbNamespace.TMDbMovieModel].self) ?? []
    }

    /// 영화 컬렉션에 영화 추가
    func addMovieToCollection(_ movie: TMDbNamespace.TMDbMovieModel) {
        var currentCollection = loadCollection()
        if !currentCollection.contains(where: { $0.id == movie.id }) {
            currentCollection.append(movie)
            saveCollection(currentCollection)
        }
    }

    /// 영화 컬렉션 저장
    private func saveCollection(_ collection: [TMDbNamespace.TMDbMovieModel]) {
        UserDefaults.standard.setObject(collection, forKey: collectionKey)
    }
}
