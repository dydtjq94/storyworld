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

    /// 특정 줌 레벨에서 중심 좌표 기준으로 가로 세로 1,000m 범위 내 타일 계산
    func tilesInRange(center: CLLocationCoordinate2D) -> [Tile] {
        let fixedZoomLevel = 18 // 고정된 줌 레벨
        let fixedSideLength = 1240.0 // 고정된 길이 (m)

        let tileSize = metersPerTile(at: Double(fixedZoomLevel)) // 타일 크기 계산
        let halfSideLength = fixedSideLength / 2.0
        let delta = Int(ceil(halfSideLength / tileSize)) // 타일 크기 기준으로 델타 계산

        print("📏 타일 크기: \(tileSize)m, 탐색 델타: \(delta)칸")

        // 중심 타일 계산
        let centerTile = calculateTile(for: center, zoomLevel: fixedZoomLevel)

        // 타일 탐색 범위 계산
        var tilesInRange: [Tile] = []
        let n = Int(pow(2.0, Double(fixedZoomLevel))) // 줌 레벨에 따른 타일 개수

        for x in max(0, centerTile.x - delta)...min(n - 1, centerTile.x + delta) {
            for y in max(0, centerTile.y - delta)...min(n - 1, centerTile.y + delta) {
                tilesInRange.append(Tile(x: x, y: y, z: fixedZoomLevel))
            }
        }

        print("📍 타일 범위 계산 완료: \(tilesInRange.count)개 타일 (Zoom: \(fixedZoomLevel), Side Length: \(fixedSideLength)m)")
        return tilesInRange
    }
    
    /// 줌 레벨에 따른 타일 크기 계산 (미터 단위)
    private func metersPerTile(at zoomLevel: Double) -> Double {
        let adjustedZoomLevel = zoomLevel // 줌 레벨 보정
        let earthCircumference = 40075016.686 // 지구 둘레 (미터)
        return earthCircumference / pow(2.0, adjustedZoomLevel) // 타일 크기 계산
    }

    func calculateTile(for coordinate: CLLocationCoordinate2D, zoomLevel: Int) -> Tile {
        let n = pow(2.0, Double(zoomLevel)) // 줌 레벨에 따른 타일 개수
        let x = Int((coordinate.longitude + 180.0) / 360.0 * n)
        let y = Int((1.0 - log(tan(coordinate.latitude * .pi / 180.0) + 1.0 / cos(coordinate.latitude * .pi / 180.0)) / .pi) / 2.0 * n)
        return Tile(x: x, y: y, z: zoomLevel)
    }
}

