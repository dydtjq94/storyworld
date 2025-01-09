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
        case .actionAdventure: return "#FFA500" // 주황색
        case .animation: return "#008000"       // 초록색
        case .comedy: return "#FFFF00"          // 노란색
        case .horrorThriller: return "#000000"  // 검은색
        case .documentaryWar: return "#8B4513"  // 갈색
        case .sciFiFantasy: return "#00FFFF"    // 시안
        case .drama: return "#FF0000"           // 빨간색
        case .romance: return "#FFC0CB"         // 분홍색
        }
    }

    var uiColor: UIColor {
        return UIColor(hex: colorHex)
    }
}

struct Movie: Codable {
    let title: String
    let genre: MovieGenre
    let rarity: Rarity
    let location: CLLocationCoordinate2D

    private enum CodingKeys: String, CodingKey {
        case title, genre, rarity, latitude, longitude
    }

    init(title: String, genre: MovieGenre, rarity: Rarity, location: CLLocationCoordinate2D) {
        self.title = title
        self.genre = genre
        self.rarity = rarity
        self.location = location
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        genre = try container.decode(MovieGenre.self, forKey: .genre)
        rarity = try container.decode(Rarity.self, forKey: .rarity)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(genre, forKey: .genre)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
    }
}
