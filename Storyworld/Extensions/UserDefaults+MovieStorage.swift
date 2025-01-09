//
//  UserDefaults+MovieStorage.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import Foundation
import CoreLocation

extension UserDefaults {
    private enum Keys {
        static let movies = "movies"
        static let lastUpdated = "lastUpdated"
    }

    func saveMovies(_ movies: [Movie]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(movies) {
            set(encoded, forKey: Keys.movies)
        }
        set(Date(), forKey: Keys.lastUpdated)
    }

    func loadMovies() -> [Movie]? {
        guard let data = data(forKey: Keys.movies) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode([Movie].self, from: data)
    }

    func isDataExpired(expirationInterval: TimeInterval) -> Bool {
        guard let lastUpdated = object(forKey: Keys.lastUpdated) as? Date else {
            return true // 데이터를 저장한 적이 없는 경우
        }
        return Date().timeIntervalSince(lastUpdated) > expirationInterval
    }
}
