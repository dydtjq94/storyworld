//
//  TileManager.swift
//  Storyworld
//
//  Created by peter on 1/13/25.
//

import Foundation
import CoreLocation

/// 타일 관련 데이터 구조체
struct Tile: Hashable {
    let x: Int
    let y: Int
    let z: Int // Zoom Level
}

extension Tile {
    // Tile -> String 변환
    func toKey() -> String {
        let key = "\(x)-\(y)-\(z)"
        print("🔑 Tile Key 생성: \(key)")
        return key
    }

    // String -> Tile 변환
    static func fromKey(_ key: String) -> Tile? {
        let components = key.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        return Tile(x: components[0], y: components[1], z: components[2])
    }
}

/// 타일 경계 정보
struct TileBounds {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double
}

/// 타일 매니저
final class TileManager {
    // 타일 별 Circle 데이터 저장
    private(set) var tileCircleData: [String: [MovieService.CircleData]] = [:]
    
    // 타일 별 Layer 상태 저장 (true: 레이어가 Map에 그려짐, false: 안 그려짐)
    private var tileLayerStates: [String: Bool] = [:]

    // MARK: - Circle 데이터 관리

    // 타일에 Circle 데이터를 저장
    func saveCircleData(for tile: Tile, circles: [MovieService.CircleData]) {
        let tileKey = tile.toKey()
        tileCircleData[tileKey] = circles
    }

    // 타일에 저장된 Circle 데이터 반환
    func getCircleData(for tile: Tile) -> [MovieService.CircleData]? {
        return tileCircleData[tile.toKey()]
    }

    // 저장된 Circle 데이터를 UserDefaults에 저장
    func persistCircleData() {
        let encodedData = tileCircleData.mapValues { circles in
            circles.map { circle in
                [
                    "genre": circle.genre.rawValue,
                    "rarity": circle.rarity.rawValue,
                    "latitude": circle.location.latitude,
                    "longitude": circle.location.longitude
                ]
            }
        }
        UserDefaults.standard.set(encodedData, forKey: "TileCircleData")
        print("✅ Circle 데이터가 UserDefaults에 저장되었습니다.")
    }

    // 저장된 Circle 데이터를 UserDefaults에서 불러오기
    func loadCircleData() {
        guard let savedData = UserDefaults.standard.dictionary(forKey: "TileCircleData") as? [String: [[String: Any]]] else {
            print("⚠️ 저장된 Circle 데이터 없음")
            tileCircleData = [:]
            return
        }
        
        tileCircleData = savedData.reduce(into: [:]) { result, item in
            let (key, value) = item
            let circles = value.compactMap { dict -> MovieService.CircleData? in
                guard let genreRaw = dict["genre"] as? String,
                      let genre = MovieGenre(rawValue: genreRaw),
                      let rarityRaw = dict["rarity"] as? String,
                      let rarity = Rarity(rawValue: rarityRaw),
                      let latitude = dict["latitude"] as? Double,
                      let longitude = dict["longitude"] as? Double else {
                    print("⚠️ Circle 데이터 복원 실패: \(dict)")
                    return nil
                }
                return MovieService.CircleData(
                    genre: genre,
                    rarity: rarity,
                    location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                )
            }
            result[key] = circles
        }
        print("✅ 저장된 Circle 데이터가 복원되었습니다.")
    }

    // MARK: - Layer 상태 관리

    // 특정 타일의 레이어 상태 확인
    func isLayerAdded(for tile: Tile) -> Bool {
        return tileLayerStates[tile.toKey()] ?? false
    }

    // 특정 타일의 레이어 상태를 추가
    func markLayerAsAdded(for tile: Tile) {
        tileLayerStates[tile.toKey()] = true
        print("✅ 레이어 상태 저장: \(tile.toKey())")
    }

    // 특정 타일의 레이어 상태를 제거
    func markLayerAsRemoved(for tile: Tile) {
        tileLayerStates[tile.toKey()] = false
    }

    // 모든 레이어 상태 초기화
    func resetLayerStates() {
        tileLayerStates.removeAll()
        print("🗑️ 모든 레이어 상태가 초기화되었습니다.")
    }

    // MARK: - 타일 관련 계산

    // 특정 줌 레벨에서 중심 좌표 기준으로 타일 목록 계산
    func tilesInRange(center: CLLocationCoordinate2D, sideLength: Double, zoomLevel: Int) -> [Tile] {
        let tileSize = metersPerTile(at: Double(zoomLevel))
        let halfSideLength = sideLength / 2.0
        let delta = Int(ceil(halfSideLength / tileSize))

        let centerTile = calculateTile(for: center, zoomLevel: zoomLevel)

        var tilesInRange: [Tile] = []
        let n = Int(pow(2.0, Double(zoomLevel)))

        for x in max(0, centerTile.x - delta)...min(n - 1, centerTile.x + delta) {
            for y in max(0, centerTile.y - delta)...min(n - 1, centerTile.y + delta) {
                tilesInRange.append(Tile(x: x, y: y, z: zoomLevel))
            }
        }

        return tilesInRange
    }

    func calculateTile(for coordinate: CLLocationCoordinate2D, zoomLevel: Int) -> Tile {
        let n = pow(2.0, Double(zoomLevel))
        let x = Int((coordinate.longitude + 180.0) / 360.0 * n)
        let y = Int((1.0 - log(tan(coordinate.latitude * .pi / 180.0) + 1.0 / cos(coordinate.latitude * .pi / 180.0)) / .pi) / 2.0 * n)
        return Tile(x: x, y: y, z: zoomLevel)
    }

    private func metersPerTile(at zoomLevel: Double) -> Double {
        let earthCircumference = 40075016.686
        return earthCircumference / pow(2.0, zoomLevel)
    }
    
    func centerOfTile(x: Int, y: Int, zoomLevel: Int) -> CLLocationCoordinate2D {
        let n = pow(2.0, Double(zoomLevel)) // 줌 레벨에 따른 타일 개수
        let lon = Double(x) / n * 360.0 - 180.0
        let lat = atan(sinh(.pi * (1.0 - 2.0 * Double(y) / n))) * 180.0 / .pi
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    // 타일 처리 여부 확인
    func hasProcessedTile(_ tile: Tile) -> Bool {
        return tileCircleData[tile.toKey()] != nil
    }
    
    // 타일과 관련된 데이터를 저장
    func markTileAsProcessed(_ tile: Tile, circles: [MovieService.CircleData]) {
        let tileKey = tile.toKey()
        tileCircleData[tileKey] = circles
        saveTileCircleData() // 저장
    }
    
    private func saveTileCircleData() {
        let encodedData = tileCircleData.mapValues { circles in
            circles.map { circle in
                [
                    "genre": circle.genre.rawValue,
                    "rarity": circle.rarity.rawValue,
                    "latitude": circle.location.latitude,
                    "longitude": circle.location.longitude
                ]
            }
        }
        UserDefaults.standard.set(encodedData, forKey: "TileCircleData")
        print("✅ TileCircleData 저장 완료")
    }
}
