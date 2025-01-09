//
//  TMDbService.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

//
//  TMDbService.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import Foundation

final class TMDbService {
    private let apiKey: String
    private let baseURL = "https://api.themoviedb.org/3"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// 🎬 특정 장르의 영화 가져오기
    func fetchMoviesByGenres(genreIds: [Int], completion: @escaping (Result<[TMDbNamespace.TMDbMovieModel], Error>) -> Void) {
        let genreIdString = genreIds.map { "\($0)" }.joined(separator: ",")
        let endpoint = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=\(genreIdString)"

        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }

            do {
                let result = try JSONDecoder().decode(TMDbNamespace.PopularMoviesResponse.self, from: data)
                completion(.success(result.results))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// 네임스페이스로 정의된 모델
struct TMDbNamespace {
    struct PopularMoviesResponse: Codable {
        let results: [TMDbMovieModel]
    }

    struct TMDbMovieModel: Codable {
        let id: Int
        let title: String
        let overview: String
        let genreIds: [Int]
        let posterPath: String?

        enum CodingKeys: String, CodingKey {
            case id, title, overview
            case genreIds = "genre_ids"
            case posterPath = "poster_path"
        }
    }
}
