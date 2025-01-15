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
    private var processedTiles: Set<Tile> = [] // 이미 처리된 타일 저장
    private var tileLayerStates: Set<String> = [] // 타일의 레이어 상태 저장 (String 키 사용)

    var tileCircleData: [String: [MovieService.CircleData]] = [:] // 키를 String으로 변경
    private let processedTilesKey = "ProcessedTiles"

    init() {
        loadProcessedTiles()
    }


    // 타일 처리 여부 확인
    func hasProcessedTile(_ tile: Tile) -> Bool {
        return processedTiles.contains(tile)
    }
    
    // 타일에 Circle 데이터 저장
    func saveCircleData(for tile: Tile, circles: [MovieService.CircleData]) {
        let tileKey = tile.toKey() // Tile -> String 변환
        tileCircleData[tileKey] = circles
    }

    // 캐시 저장 전 유효성 검사
    func markTileAsProcessed(_ tile: Tile, circles: [MovieService.CircleData]) {
        processedTiles.insert(tile) // Tile 객체를 직접 저장
        saveCircleData(for: tile, circles: circles) // Circle 데이터 저장
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
    }

    func clearProcessedTiles() {
        processedTiles.removeAll()
        saveProcessedTiles()
    }
    
    // 캐시 데이터를 UserDefaults에 저장
    private func saveProcessedTiles() {
        let tilesArray = processedTiles.map { ["x": $0.x, "y": $0.y, "z": $0.z] }
        UserDefaults.standard.set(tilesArray, forKey: "ProcessedTiles")
    }
    
    private func loadProcessedTiles() {
        guard let tilesArray = UserDefaults.standard.array(forKey: "ProcessedTiles") as? [[String: Int]] else { return }
        processedTiles = Set(tilesArray.compactMap { dict in
            guard let x = dict["x"], let y = dict["y"], let z = dict["z"] else { return nil }
            return Tile(x: x, y: y, z: z)
        })
    }
    
    // 로드 함수에서 비정상 데이터 초기화
    func loadTileCircleData() {
        guard let savedData = UserDefaults.standard.dictionary(forKey: "TileCircleData") as? [String: [[String: Any]]] else {
            print("⚠️ 저장된 TileCircleData 없음 또는 비정상적")
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
                    print("⚠️ Circle 데이터 디코드 실패: \(dict)")
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
    }
    
    /// 줌 레벨에 따른 타일 크기 계산 (미터 단위)
    private func metersPerTile(at zoomLevel: Double) -> Double {
        let adjustedZoomLevel = zoomLevel // 줌 레벨 보정
        let earthCircumference = 40075016.686 // 지구 둘레 (미터)
        return earthCircumference / pow(2.0, adjustedZoomLevel) // 타일 크기 계산
    }

    /// TileJSON 정보를 기반으로 타일 경계값을 반환
    func getTileBounds(tile: Tile) -> TileBounds {
        let n = pow(2.0, Double(tile.z)) // 줌 레벨에 따른 타일 개수
        let lonPerTile = 360.0 / n
        let minLon = Double(tile.x) * lonPerTile - 180.0
        let maxLon = minLon + lonPerTile

        let minLat = 180.0 / .pi * atan(sinh(.pi - Double(tile.y + 1) * 2.0 * .pi / n))
        let maxLat = 180.0 / .pi * atan(sinh(.pi - Double(tile.y) * 2.0 * .pi / n))

        return TileBounds(minLatitude: minLat, maxLatitude: maxLat, minLongitude: minLon, maxLongitude: maxLon)
    }

    /// 특정 줌 레벨에서 중심 좌표 기준으로 가로 세로 1,000m 범위 내 타일 계산
    func tilesInRange(center: CLLocationCoordinate2D, sideLength: Double, zoomLevel: Int) -> [Tile] {
        let tileSize = metersPerTile(at: Double(zoomLevel)) // 타일 크기 계산
        let halfSideLength = sideLength / 2.0 // 1,000m 기준으로 상하좌우 각각 500m
        let delta = Int(ceil(halfSideLength / tileSize)) // 타일 크기 기준으로 델타 계산

        print("📏 타일 크기: \(tileSize)m, 탐색 델타: \(delta)칸")

        // 중심 타일 계산
        let centerTile = calculateTile(for: center, zoomLevel: zoomLevel)

        // 타일 탐색 범위 계산
        var tilesInRange: [Tile] = []
        let n = Int(pow(2.0, Double(zoomLevel))) // 줌 레벨에 따른 타일 개수

        for x in max(0, centerTile.x - delta)...min(n - 1, centerTile.x + delta) {
            for y in max(0, centerTile.y - delta)...min(n - 1, centerTile.y + delta) {
                tilesInRange.append(Tile(x: x, y: y, z: zoomLevel))
            }
        }

        print("📍 타일 범위 계산 완료: \(tilesInRange.count)개 타일 (Zoom: \(zoomLevel), Side Length: \(sideLength)m)")
        return tilesInRange
    }

    /// 타일 경계와 1,000m 범위 교차 여부 확인
    private func tileBoundsIntersects(bounds: TileBounds, minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) -> Bool {
        return !(bounds.maxLatitude < minLat || bounds.minLatitude > maxLat ||
                 bounds.maxLongitude < minLon || bounds.minLongitude > maxLon)
    }


    func centerOfTile(x: Int, y: Int, zoomLevel: Int) -> CLLocationCoordinate2D {
        let n = pow(2.0, Double(zoomLevel)) // 줌 레벨에 따른 타일 개수
        let lon = Double(x) / n * 360.0 - 180.0
        let lat = atan(sinh(.pi * (1.0 - 2.0 * Double(y) / n))) * 180.0 / .pi
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func calculateTile(for coordinate: CLLocationCoordinate2D, zoomLevel: Int) -> Tile {
        let n = pow(2.0, Double(zoomLevel)) // 줌 레벨에 따른 타일 개수
        let x = Int((coordinate.longitude + 180.0) / 360.0 * n)
        let y = Int((1.0 - log(tan(coordinate.latitude * .pi / 180.0) + 1.0 / cos(coordinate.latitude * .pi / 180.0)) / .pi) / 2.0 * n)
        return Tile(x: x, y: y, z: zoomLevel)
    }

    
    func randomCoordinateInTile(tile: Tile, zoomLevel: Double) -> CLLocationCoordinate2D? {
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
}

