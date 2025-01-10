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
    func fetchMoviesByGenres(genreIds: [Int], page: Int, completion: @escaping (Result<([TMDbNamespace.TMDbMovieModel], Int), Error>) -> Void) {
        let genreIdString = genreIds.map { "\($0)" }.joined(separator: ",")
        let endpoint = "\(baseURL)/discover/movie?api_key=\(apiKey)&with_genres=\(genreIdString)&page=\(page)&with_original_language=ko&language=ko-KR"

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
                let totalPages = result.totalPages
                let movies = result.results

                if movies.isEmpty {
                    print("⚠️ Page \(page) is empty. Retrying with a new page.")
                    // 페이지가 비어 있을 경우, 새로운 페이지로 재시도
                    let newPage = Int.random(in: 1...totalPages)
                    self.fetchMoviesByGenres(genreIds: genreIds, page: newPage, completion: completion)
                } else {
                    let filteredMovies = result.results.filter { $0.posterPath != nil }
                    completion(.success((filteredMovies, totalPages)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

