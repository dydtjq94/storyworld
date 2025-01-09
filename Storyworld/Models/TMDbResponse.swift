//
//  TMDbResponse.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import Foundation

// TMDb 응답 모델
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

struct TMDbResponse {
    static let mergedGenres: [MovieGenre: [Int]] = [
        .actionAdventure: [28, 12, 37], // 액션, 모험, 서부
        .animation: [16], // 애니메이션
        .comedy: [35], // 코미디
        .horrorThriller: [80, 27, 53, 9648], // 범죄, 공포, 스릴러, 미스터리
        .documentaryWar: [99, 36, 10752], // 다큐멘터리, 역사, 전쟁
        .sciFiFantasy: [14, 878], // 판타지, SF
        .drama: [18, 10770, 10402, 10751], // 드라마, TV 영화, 음악, 가족
        .romance: [10749] // 로맨스
    ]

    static func mapGenreIdToMergedGenre(_ genreId: Int) -> MovieGenre {
        for (genre, genreIds) in mergedGenres {
            if genreIds.contains(genreId) {
                return genre
            }
        }
        return .drama // 기본값
    }
}
