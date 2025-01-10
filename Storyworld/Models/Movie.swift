//
//  Movie.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import CoreLocation
import UIKit

enum MovieGenre: String, Codable {
    case actionAdventure = "Action/Adventure" // 액션/모험
    case animation = "Animation"             // 애니메이션
    case comedy = "Comedy"                   // 코미디
    case horrorThriller = "Horror/Thriller"  // 공포/스릴러
    case documentaryWar = "Documentary/War"  // 다큐멘터리/전쟁
    case sciFiFantasy = "Sci-Fi/Fantasy"     // SF/판타지
    case drama = "Drama"                     // 드라마
    case romance = "Romance"                 // 로맨스

    var colorHex: String {
        switch self {
        case .actionAdventure: return "#CC8400" // 주황색 (어두움)
        case .animation: return "#006400"       // 초록색 (어두움)
        case .comedy: return "#CCCC00"          // 노란색 (어두움)
        case .horrorThriller: return "#1A1A1A"  // 검은색 (약간 밝음)
        case .documentaryWar: return "#5E3210"  // 갈색 (어두움)
        case .sciFiFantasy: return "#008B8B"    // 시안 (어두움)
        case .drama: return "#B20000"           // 빨간색 (어두움)
        case .romance: return "#FF9EBB"         // 분홍색 (어두움)
        }
    }

    var uiColor: UIColor {
        return UIColor(hex: colorHex)
    }
}

struct Movie: Codable, Equatable {
    let id: Int            // 영화 ID
    let title: String      // 영화 제목
    let genre: MovieGenre  // 영화 장르
    let rarity: Rarity     // 희귀도
    let location: CLLocationCoordinate2D // 위치
    let posterPath: String? // 포스터 경로 추가

    private enum CodingKeys: String, CodingKey {
        case id, title, genre, rarity, latitude, longitude, posterPath
    }

    init(id: Int, title: String, genre: MovieGenre, rarity: Rarity, location: CLLocationCoordinate2D, posterPath: String?) {
        self.id = id
        self.title = title
        self.genre = genre
        self.rarity = rarity
        self.location = location
        self.posterPath = posterPath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        genre = try container.decode(MovieGenre.self, forKey: .genre)
        rarity = try container.decode(Rarity.self, forKey: .rarity)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(genre, forKey: .genre)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
        try container.encode(posterPath, forKey: .posterPath)
    }
}
