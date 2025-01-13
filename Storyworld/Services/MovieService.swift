//
//  MovieService.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import Foundation
import CoreLocation

final class MovieService {
    private let userDefaults = UserDefaults.standard
    private let expirationInterval: TimeInterval = 6 * 60 * 60 // 6시간
    private let tmdbService = TMDbService(apiKey: Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as! String)
    private let maxCircleCount = 100 // 지도에 표시할 최대 Circle 개수
    private let maxRadiusMap = 1500 // 지도에 표시할 최대 반경

    
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
    
    /// 장르와 Rarity 조합을 반환 (캐싱 포함)
    func getCircleData(userLocation: CLLocationCoordinate2D, completion: @escaping ([CircleData]) -> Void) {
        // 캐시 확인 및 반환
        if let cachedCircles = getCachedCircleData(), !isCacheExpired() {
            print("✅ 캐싱된 Circle 데이터를 반환합니다.")
            completion(cachedCircles)
            return
        }

        print("🆕 새로운 Circle 데이터를 생성합니다.")

        // 장르 리스트
        let genres: [MovieGenre] = [
            .actionAdventure, .animation, .comedy,
            .horrorThriller, .documentaryWar,
            .sciFiFantasy, .drama, .romance
        ]
        
        // 희귀도 확률 설정
        let rarityProbabilities: [(Rarity, Double)] = [
            (.common, 0.6),
            (.uncommon, 0.3),
            (.rare, 0.099),
            (.epic, 0.001)
        ]

        var circleData: [CircleData] = []

        // 최대 Circle 개수 기반으로 데이터 생성
        for _ in 0..<maxCircleCount {
            // 랜덤 장르 선택
            guard let randomGenre = genres.randomElement() else { continue }

            // 랜덤 희귀도 선택 (확률 기반)
            let randomRarity = randomRarityBasedOnProbability(rarityProbabilities)

            // 랜덤 좌표 생성
            guard let randomLocation = randomCoordinateInSquare(around: userLocation, sideLength: Double(maxRadiusMap)) else { continue }

            // CircleData 생성
            circleData.append(CircleData(genre: randomGenre, rarity: randomRarity, location: randomLocation))
        }

        // 생성된 데이터를 캐시에 저장
        cacheCircleData(circleData)

        // 결과 반환
        completion(circleData)
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
    func fetchMovies(for genre: MovieGenre, rarity: Rarity, completion: @escaping (Result<[Movie], Error>) -> Void) {
       let genreIds = mapGenreToGenreIds(genre)
        tmdbService.fetchMoviesByGenres(genreIds: genreIds, page: Int.random(in: 1...500)) { result in
           switch result {
           case .success(let (tmdbMovies, _)):
               let movies = tmdbMovies.compactMap { tmdbMovie -> Movie? in
                   guard let randomLocation = self.randomCoordinateInSquare(
                       around: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 서울 중심
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
        let halfSide = sideLength / 2.0 // 반쪽 길이 (미터)

        // 위도 및 경도 범위 계산
        let deltaLatitude = (halfSide / earthRadius) * (180 / .pi)
        let deltaLongitude = (halfSide / (earthRadius * cos(center.latitude * .pi / 180))) * (180 / .pi)

        // 중심으로부터 랜덤한 범위 내에서 좌표 생성
        let randomLatitude = center.latitude + Double.random(in: -deltaLatitude...deltaLatitude)
        let randomLongitude = center.longitude + Double.random(in: -deltaLongitude...deltaLongitude)

        return CLLocationCoordinate2D(latitude: randomLatitude, longitude: randomLongitude)
    }

    
    /// 🗂️ Circle 데이터를 캐시에 저장
    private func cacheCircleData(_ circleData: [CircleData]) {
      do {
          let encoder = JSONEncoder()
          let data = try encoder.encode(circleData)
          userDefaults.set(data, forKey: "cachedCircleData")
          userDefaults.set(Date(), forKey: "circleCacheTimestamp")
          print("✅ Circle 데이터가 캐시에 저장되었습니다.")
      } catch {
          print("❌ Circle 데이터를 캐시에 저장하는 데 실패했습니다: \(error.localizedDescription)")
      }
    }

    /// 캐시된 Circle 데이터 가져오기
    private func getCachedCircleData() -> [CircleData]? {
        guard let data = userDefaults.data(forKey: "cachedCircleData") else {
            print("❌ 캐시에 저장된 Circle 데이터가 없습니다.")
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let circleData = try decoder.decode([CircleData].self, from: data)
            print("✅ 캐시된 Circle 데이터를 불러왔습니다") // 불러온 데이터 출력
            return circleData
        } catch {
            print("❌ 캐시된 Circle 데이터를 불러오는 데 실패했습니다: \(error.localizedDescription)")
            return nil
        }
    }


    /// ⏳ 캐시 만료 여부 확인
    private func isCacheExpired() -> Bool {
      guard let timestamp = userDefaults.object(forKey: "circleCacheTimestamp") as? Date else { return true }
      let elapsedTime = Date().timeIntervalSince(timestamp)
      print("⏱️ 캐시 경과 시간: \(elapsedTime)초")
      return elapsedTime > expirationInterval
    }

    
    func clearCache() {
        userDefaults.removeObject(forKey: "cachedCircleData")
        userDefaults.removeObject(forKey: "circleCacheTimestamp")
        print("✅ 캐시가 성공적으로 삭제되었습니다.")

        // 디버깅: 캐시 확인
        if userDefaults.data(forKey: "cachedCircleData") == nil,
           userDefaults.object(forKey: "circleCacheTimestamp") == nil {
            print("✅ 모든 캐시 데이터가 삭제되었습니다.")
        } else {
            print("❌ 캐시 데이터 삭제 실패. 여전히 데이터가 존재합니다.")
        }
    }
}
