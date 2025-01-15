//
//  MovieService.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import Foundation
import CoreLocation

final class MovieService {
    let circleCacheManager = CircleCacheManager()
    private let expirationInterval: TimeInterval = 6 * 60 * 60 // 6시간
    private let tmdbService = TMDbService(apiKey: Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as! String)
    private let maxCircleCount = 10 // 지도에 표시할 최대 Circle 개수
    private let sideLength = 1000 // 지도에 표시할 최대 반경
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
    
    func getCircleData(userLocation: CLLocationCoordinate2D, forceUpdate: Bool = false, completion: @escaping ([CircleData]) -> Void) {
        let radius = CLLocationDistance(sideLength)
        let cachedCircles = circleCacheManager.getFilteredCircleData(near: userLocation, radius: radius)
        if !forceUpdate, !cachedCircles.isEmpty {
            print("✅ 현재 위치 기준 캐싱된 Circle 데이터를 반환합니다.")
            completion(cachedCircles)
            return
        }

        print("🆕 새로운 Circle 데이터를 생성합니다.")
        let newCircles = createCircleData(around: userLocation)
        circleCacheManager.appendToCache(newCircles)
        completion(newCircles)
    }
    
    
    func createCircleData(around userLocation: CLLocationCoordinate2D) -> [CircleData] {
        let genres: [MovieGenre] = [ .actionAdventure, .animation, .comedy, .horrorThriller, .documentaryWar, .sciFiFantasy, .drama, .romance ]
        let rarityProbabilities: [(Rarity, Double)] = [ (.common, 0.6), (.uncommon, 0.3), (.rare, 0.099), (.epic, 0.001) ]
        var circleData: [CircleData] = []

        for _ in 0..<maxCircleCount {
            guard let randomGenre = genres.randomElement(),
                  let randomLocation = randomCoordinateInSquare(around: userLocation, sideLength: Double(sideLength)) else { continue }
            let randomRarity = randomRarityBasedOnProbability(rarityProbabilities)
            circleData.append(CircleData(genre: randomGenre, rarity: randomRarity, location: randomLocation))
        }
        return circleData
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
    
    /// TMDb에서 특정 장르와 Rarity에 따른 영화 데이터 가져오기
    func fetchMovies(for genre: MovieGenre, rarity: Rarity, userLocation: CLLocationCoordinate2D, completion: @escaping (Result<[Movie], Error>) -> Void) {
       let genreIds = mapGenreToGenreIds(genre)
        tmdbService.fetchMoviesByGenres(genreIds: genreIds, page: Int.random(in: 1...500)) { result in
           switch result {
           case .success(let (tmdbMovies, _)):
               let movies = tmdbMovies.compactMap { tmdbMovie -> Movie? in
                   guard let randomLocation = self.randomCoordinateInSquare(
                       around: userLocation, // 현재 위치를 기반으로 랜덤 좌표 생성
                       sideLength: 500
                   ) else {
                       return nil
                   }

                   return Movie(
                       id: tmdbMovie.id, // TMDb 영화 ID
                       title: tmdbMovie.title, // 영화 제목
                       genre: genre, // 장르
                       rarity: rarity, // 희귀도
                       location: randomLocation, // 랜덤 생성된 위치
                       posterPath: tmdbMovie.posterPath // 포스터 경로
                   )
               }
               completion(.success(movies))
           case .failure(let error):
               completion(.failure(error))
           }
       }
    }
    
    /// 장르를 TMDb API의 Genre IDs로 매핑
    private func mapGenreToGenreIds(_ genre: MovieGenre) -> [Int] {
        switch genre {
        case .actionAdventure:
            return [28, 12, 37] // 액션, 모험, 서부
        case .animation:
            return [16] // 애니메이션
        case .comedy:
            return [35] // 코미디
        case .horrorThriller:
            return [80, 27, 53, 9648] // 범죄, 공포, 스릴러, 미스터리
        case .documentaryWar:
            return [99, 36, 10752] // 다큐멘터리, 역사, 전쟁
        case .sciFiFantasy:
            return [14, 878] // 판타지, SF
        case .drama:
            return [18, 10770, 10402, 10751] // 드라마, TV 영화, 음악, 가족
        case .romance:
            return [10749] // 로맨스
        }
    }
    
    /// 📍 랜덤 좌표 생성 (중심 좌표에서 특정 네모난 영역 내)
    func randomCoordinateInSquare(around center: CLLocationCoordinate2D, sideLength: Double) -> CLLocationCoordinate2D? {
        let earthRadius = 6371000.0 // 지구 반경 (미터 단위)
        let halfSideLength = sideLength / 2.0 // 상하좌우 각각 절반 거리 (500m)

        // 위도 및 경도 범위 계산
        let deltaLatitude = (halfSideLength / earthRadius) * (180 / .pi)
        let deltaLongitude = (halfSideLength / (earthRadius * cos(center.latitude * .pi / 180))) * (180 / .pi)

        // 중심으로부터 랜덤한 범위 내에서 좌표 생성
        let randomLatitude = center.latitude + Double.random(in: -deltaLatitude...deltaLatitude)
        let randomLongitude = center.longitude + Double.random(in: -deltaLongitude...deltaLongitude)

        return CLLocationCoordinate2D(latitude: randomLatitude, longitude: randomLongitude)
    }

    /// 캐시 초기화
    func clearCache() {
        circleCacheManager.clearCache()
    }
    
    func createFilteredCircleData(visibleTiles: [Tile], zoomLevel: Int, tileManager: TileManager) -> [MovieService.CircleData] {
        var filteredCircles: [MovieService.CircleData] = []
        let genres: [MovieGenre] = [.actionAdventure, .animation, .comedy, .horrorThriller, .documentaryWar, .sciFiFantasy, .drama, .romance]
        let rarityProbabilities: [(Rarity, Double)] = [(.common, 0.6), (.uncommon, 0.3), (.rare, 0.099), (.epic, 0.001)]

        for tile in visibleTiles {
            if let cachedCircles = tileManager.tileCircleData[tile.toKey()] {
                print("📂 기존 Circle 데이터 사용 - Tile: \(tile), Circle 수: \(cachedCircles.count)")
                filteredCircles.append(contentsOf: cachedCircles)
                continue
            }

            print("🆕 새로운 Circle 데이터 생성 중 - Tile: \(tile)")

            let tileCenter = tileManager.centerOfTile(x: tile.x, y: tile.y, zoomLevel: zoomLevel)
            guard let randomGenre = genres.randomElement() else {
                print("❌ 랜덤 장르 생성 실패")
                continue
            }

            let randomRarity = randomRarityBasedOnProbability(rarityProbabilities)
            let circle = MovieService.CircleData(genre: randomGenre, rarity: randomRarity, location: tileCenter)

            tileManager.markTileAsProcessed(tile, circles: [circle])
            filteredCircles.append(circle)
        }

        print("✅ 총 \(filteredCircles.count)개의 Circle 데이터 생성 완료")
        return filteredCircles
    }
}
