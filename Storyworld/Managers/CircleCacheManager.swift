//
//  CircleCasheManager.swift
//  Storyworld
//
//  Created by peter on 1/13/25.
//

import Foundation
import CoreLocation

final class CircleCacheManager {
    private let userDefaults = UserDefaults.standard
    private let expirationInterval: TimeInterval = 6 * 60 * 60 // 6시간
    private var scannedCenters: [CLLocationCoordinate2D] = [] // 스캔된 중심 좌표 저장
    private var scannedGridKeys: Set<String> = [] // 스캔된 그리드 키 저장
    private let earthRadius: Double = 6371000.0 // 지구 반지름 (단위: m)
    private let gridSize: Double = 100.0 // 그리드 크기 (단위: m)
    private var scannedGridData: [String: [CLLocationCoordinate2D]] = [:] // 그리드별 Circle 위치 저장

    
    // 중심 좌표 추가
    func addScannedCenter(_ center: CLLocationCoordinate2D) {
        scannedCenters.append(center)
    }

    // Haversine Formula를 사용한 거리 계산
        func distance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
            let dLat = (coord2.latitude - coord1.latitude) * .pi / 180
            let dLon = (coord2.longitude - coord1.longitude) * .pi / 180

            let lat1 = coord1.latitude * .pi / 180
            let lat2 = coord2.latitude * .pi / 180

            let a = sin(dLat / 2) * sin(dLat / 2) +
                    cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
            let c = 2 * atan2(sqrt(a), sqrt(1 - a))

            return earthRadius * c // 두 좌표 간의 거리 반환 (단위: m)
        }

        // 100m 단위로 그리드 키 생성
        func gridKey(for coordinate: CLLocationCoordinate2D) -> String {
            let metersPerDegreeLat = 111_000.0 // 위도 1도는 약 111km
            let metersPerDegreeLon = 111_000.0 * cos(coordinate.latitude * .pi / 180) // 경도는 위도에 따라 달라짐

            let x = Int((coordinate.latitude * metersPerDegreeLat) / gridSize)
            let y = Int((coordinate.longitude * metersPerDegreeLon) / gridSize)

            return "\(x)-\(y)" // 그리드 키 생성
        }

        // 같은 그리드 내에서 최소 거리 조건 확인
        func isFarEnoughInGrid(key: String, location: CLLocationCoordinate2D, minDistance: Double) -> Bool {
            guard let gridCircles = scannedGridData[key] else {
                print("✅ 그리드 데이터 없음, 거리 조건 만족")
                return true // 그리드에 데이터가 없으면 거리 조건 만족
            }

            for existingLocation in gridCircles {
                let distance = self.distance(from: location, to: existingLocation)
                print("🔍 거리 비교 - 기존: (\(existingLocation.latitude), \(existingLocation.longitude)), 거리: \(distance)")
                if distance < minDistance {
                    print("❌ 거리 조건 불만족, 기존 Circle과 너무 가까움")
                    return false // 최소 거리 조건을 만족하지 못함
                }
            }

            return true // 모든 Circle과 최소 거리 조건 만족
        }

        // 새로운 Circle 추가
        func addCircleToGrid(key: String, location: CLLocationCoordinate2D) {
            if scannedGridData[key] == nil {
                scannedGridData[key] = []
            }
            scannedGridData[key]?.append(location)
            print("✅ 새로운 Circle 저장 - 그리드 키: \(key), 위치: (\(location.latitude), \(location.longitude))")
        }

    // 그리드 스캔 여부 확인
    func isGridScanned(key: String) -> Bool {
        return scannedGridKeys.contains(key)
    }

    // 그리드 키 추가
    func markGridAsScanned(key: String) {
        scannedGridKeys.insert(key)
    }
    
    
    // 🗂️ Circle 데이터를 캐시에 추가 저장
    func appendToCache(_ circleData: [MovieService.CircleData]) {
        var allData = getAllCachedCircleData() ?? []
        allData.append(contentsOf: circleData)
        cacheCircleData(allData)
    }

    // 기존 데이터 전체 캐시 저장
    private func cacheCircleData(_ circleData: [MovieService.CircleData]) {
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

    // 캐시된 Circle 데이터 전체 가져오기
    func getAllCachedCircleData() -> [MovieService.CircleData]? {
        guard let data = userDefaults.data(forKey: "cachedCircleData") else {
            print("❌ 캐시에 저장된 Circle 데이터가 없습니다.")
            return nil
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([MovieService.CircleData].self, from: data)
        } catch {
            print("❌ 캐시 데이터를 불러오는 데 실패했습니다: \(error.localizedDescription)")
            return nil
        }
    }

    // 특정 위치 근처 데이터 필터링
    func getFilteredCircleData(near location: CLLocationCoordinate2D, radius: CLLocationDistance) -> [MovieService.CircleData] {
        let allData = getAllCachedCircleData() ?? []
        return allData.filter { circle in
            let circleLocation = CLLocation(latitude: circle.location.latitude, longitude: circle.location.longitude)
            let targetLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            return circleLocation.distance(from: targetLocation) <= radius
        }
    }

    /// ⏳ 캐시 만료 여부 확인
    func isCacheExpired() -> Bool {
        guard let timestamp = userDefaults.object(forKey: "circleCacheTimestamp") as? Date else { return true }
        let elapsedTime = Date().timeIntervalSince(timestamp)
        print("⏱️ 캐시 경과 시간: \(elapsedTime)초")
        return elapsedTime > expirationInterval
    }

    /// 캐시 삭제
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
