//
//  TMDbResponse.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import Foundation
import CoreLocation

// 네임스페이스로 정의된 모델
struct TMDbNamespace {
    struct PopularMoviesResponse: Codable {
        let results: [TMDbMovieModel]
        let totalPages: Int

        enum CodingKeys: String, CodingKey {
            case results
            case totalPages = "total_pages"
        }
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

        // Movie 모델로 변환
        func toMovie(location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)) -> Movie {
            let genres = genreIds.compactMap { TMDbResponse.mapGenreIdToMergedGenre($0) }
            return Movie(
                id: id,
                title: title,
                genre: genres.first ?? .drama, // 기본값 설정
                rarity: .common, // 기본 희귀도
                location: location,
                posterPath: posterPath
            )
        }
    }
}

struct TMDbResponse {
    static let mergedGenres: [MovieGenre: [Int]] = [
        .actionAdventure: [28, 12], // 액션, 모험
        .animation: [16], // 애니메이션
        .comedy: [35], // 코미디
        .horrorThriller: [80, 27, 53, 9648], // 범죄, 공포, 스릴러, 미스터리
        .documentaryWar: [99, 36, 10752], // 다큐멘터리, 역사, 전쟁
        .sciFiFantasy: [14, 878], // 판타지, SF
        .drama: [18, 10770, 10402, 10751], // 드라마, TV 영화, 음악, 가족
        .romance: [10749] // 로맨스
    ]

    /// TMDb 장르 ID를 내부 MovieGenre로 매핑
    static func mapGenreIdToMergedGenre(_ genreId: Int) -> MovieGenre {
        for (genre, genreIds) in mergedGenres {
            if genreIds.contains(genreId) {
                return genre
            }
        }
        return .drama // 기본값
    }
}

