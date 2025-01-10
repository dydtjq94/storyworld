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
    
    func removeMovie(byId id: Int) {
        var movies = loadMovies() ?? []
        movies.removeAll { $0.id == id }
        saveMovies(movies)
    }

    func clearMovies() {
        removeObject(forKey: Keys.movies)
        removeObject(forKey: Keys.lastUpdated)
    }
    
    func getObject<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }

    func setObject<T: Encodable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(object) {
            set(data, forKey: key)
        }
    }
}
