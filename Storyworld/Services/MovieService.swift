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
    private let maxCircleCount = 30 // 지도에 표시할 최대 Circle 개수
    
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
        if let cachedCircles = getCachedCircleData(), !isCacheExpired() {
            print("✅ 캐싱된 Circle 데이터를 반환합니다.")
            completion(cachedCircles)
            return
        }

        print("🆕 새로운 Circle 데이터를 생성합니다.")
        let genres: [MovieGenre] = [
            .actionAdventure, .animation, .comedy,
            .horrorThriller, .documentaryWar,
            .sciFiFantasy, .drama, .romance
        ]
        let rarities: [Rarity] = [.common, .uncommon, .rare, .epic]

        var circleData: [CircleData] = []

        for genre in genres {
            for rarity in rarities {
                guard let randomLocation = randomCoordinate(around: userLocation, radius: 500) else {
                    continue
                }
                circleData.append(CircleData(genre: genre, rarity: rarity, location: randomLocation))
            }
        }

        let finalCircles = Array(circleData.shuffled().prefix(maxCircleCount))
        cacheCircleData(finalCircles)
        completion(finalCircles)
    }
    
    /// TMDb에서 특정 장르와 Rarity에 따른 영화 데이터 가져오기
    func fetchMovies(for genre: MovieGenre, rarity: Rarity, completion: @escaping (Result<[Movie], Error>) -> Void) {
       let genreIds = mapGenreToGenreIds(genre)
       tmdbService.fetchMoviesByGenres(genreIds: genreIds) { result in
           switch result {
           case .success(let tmdbMovies):
               let movies = tmdbMovies.compactMap { tmdbMovie -> Movie? in
                   guard let randomLocation = self.randomCoordinate(
                       around: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 서울 중심
                       radius: 500
                   ) else {
                       return nil
                   }

                   return Movie(
                       title: tmdbMovie.title,
                       genre: genre,
                       rarity: rarity,
                       location: randomLocation
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
    
    /// 📍 랜덤 좌표 생성 (중심 좌표에서 특정 반경 내)
    func randomCoordinate(around center: CLLocationCoordinate2D, radius: Double) -> CLLocationCoordinate2D? {
        let earthRadius = 6371000.0 // 지구 반경 (미터 단위)

        // 반경 내 거리와 각도를 랜덤으로 생성
        let randomDistance = sqrt(Double.random(in: 0...1)) * radius // 제곱근으로 균등 분포
        let randomAngle = Double.random(in: 0..<(2 * .pi))

        // 위도와 경도 계산
        let deltaLatitude = randomDistance * cos(randomAngle) / earthRadius * (180 / .pi)
        let deltaLongitude = randomDistance * sin(randomAngle) / (earthRadius * cos(center.latitude * .pi / 180)) * (180 / .pi)

        return CLLocationCoordinate2D(
            latitude: center.latitude + deltaLatitude,
            longitude: center.longitude + deltaLongitude
        )
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
