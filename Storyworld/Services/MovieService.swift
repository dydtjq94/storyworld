//
//  MovieService.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import Foundation
import CoreLocation

final class MovieService {
    private let tileManager = TileManager()

    struct CircleData: Codable {
        let genre: MovieGenre
        let rarity: Rarity
        let location: CLLocationCoordinate2D
        
        private enum CodingKeys: String, CodingKey {
            case genre, rarity, latitude, longitude
        }

        init(genre: MovieGenre, rarity: Rarity, location: CLLocationCoordinate2D) {
            self.genre = genre
            self.rarity = rarity
            self.location = location
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            genre = try container.decode(MovieGenre.self, forKey: .genre)
            rarity = try container.decode(Rarity.self, forKey: .rarity)
            let latitude = try container.decode(Double.self, forKey: .latitude)
            let longitude = try container.decode(Double.self, forKey: .longitude)
            location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(genre, forKey: .genre)
            try container.encode(rarity, forKey: .rarity)
            try container.encode(location.latitude, forKey: .latitude)
            try container.encode(location.longitude, forKey: .longitude)
        }
    }
    
    func createFilteredCircleData(visibleTiles: [Tile], tileManager: TileManager) -> [MovieService.CircleData] {
        var filteredCircles: [MovieService.CircleData] = []
        let genres: [MovieGenre] = [.actionAdventure, .animation, .comedy, .horrorThriller, .documentaryWar, .sciFiFantasy, .drama, .romance]
        let rarityProbabilities: [(Rarity, Double)] = Rarity.allCases.map { ($0, $0.probability) }
        // 고정된 Zoom Level과 Length
        let fixedZoomLevel = Constants.Numbers.searchFixedZoomLevel

        for tile in visibleTiles {
            if let randomLocation = randomCoordinateInTile(tile: tile, zoomLevel: Double(fixedZoomLevel)) {
                guard let randomGenre = genres.randomElement() else {
                    print("❌ 랜덤 장르 생성 실패")
                    continue
                }

                let randomRarity = randomRarityBasedOnProbability(rarityProbabilities)
                let circle = MovieService.CircleData(genre: randomGenre, rarity: randomRarity, location: randomLocation)

                filteredCircles.append(circle)
            } else {
                print("❌ 랜덤 좌표 생성 실패 - Tile: \(tile)")
            }
        }

        print("✅ 총 \(filteredCircles.count)개의 Circle 데이터 생성 완료")
        return filteredCircles
    }
    
    /// 📍 랜덤 좌표 생성 (타일 내)
    func randomCoordinateInTile(tile: Tile, zoomLevel: Double) -> CLLocationCoordinate2D? {
        // 80% 확률로 좌표 생성
        let probability = Constants.Numbers.probability
        guard Double.random(in: 0...1) <= probability else {
            print("❌ 랜덤 좌표 생성 실패 (확률 조건 미충족)")
            return nil
        }

        let n = pow(2.0, zoomLevel) // 줌 레벨에 따른 타일 개수

        // 타일의 경도 범위 계산
        let lonPerTile = 360.0 / n
        let tileMinLon = Double(tile.x) * lonPerTile - 180.0
        let tileMaxLon = tileMinLon + lonPerTile

        // 타일의 위도 범위 계산
        let tileMaxLat = 180.0 / .pi * atan(sinh(.pi - Double(tile.y) * 2.0 * .pi / n))
        let tileMinLat = 180.0 / .pi * atan(sinh(.pi - Double(tile.y + 1) * 2.0 * .pi / n))

        // 랜덤 좌표 생성
        let randomLat = Double.random(in: tileMinLat...tileMaxLat)
        let randomLon = Double.random(in: tileMinLon...tileMaxLon)

        return CLLocationCoordinate2D(latitude: randomLat, longitude: randomLon)
    }

    // 확률 기반으로 희귀도 선택
    private func randomRarityBasedOnProbability(_ probabilities: [(Rarity, Double)]) -> Rarity {
        let totalProbability = probabilities.reduce(0) { $0 + $1.1 }
        let randomValue = Double.random(in: 0...totalProbability)
        
        var cumulativeProbability: Double = 0
        for (rarity, probability) in probabilities {
            cumulativeProbability += probability
            if randomValue <= cumulativeProbability {
                return rarity
            }
        }
        
        // 기본값 반환 (논리적으로 이곳에 도달하지 않음)
        return .common
    }
}
