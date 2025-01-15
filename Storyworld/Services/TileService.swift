//
//  TileService.swift
//  Storyworld
//
//  Created by peter on 1/13/25.
//

import Foundation
import CoreLocation

final class TileService {
    private let tileManager = TileManager()
    private let cacheManager = TileCacheManager()
    private var tileData: [String: TileManager.TileInfo] = [:]

    init() {
        self.tileData = cacheManager.loadTileData()
    }

    func tilesInRange(center: CLLocationCoordinate2D) -> [Tile] {
        return tileManager.tilesInRange(center: center)
    }

    func getTileInfo(for tile: Tile) -> TileManager.TileInfo? {
        return tileData[tile.toKey()]
    }

    func saveTileInfo(for tile: Tile, layerData: [MovieService.CircleData], isVisible: Bool) {
        let tileKey = tile.toKey()
        
        // 타일 데이터가 이미 존재하면 저장하지 않음
        if tileData[tileKey] != nil {
            print("🔄 타일 데이터 이미 존재, 저장 생략: \(tileKey)")
            return
        }
        
        // 새 타일 데이터 저장
        tileData[tileKey] = TileManager.TileInfo(layerData: layerData, isVisible: isVisible)
        cacheManager.saveTileData(tileData) // 캐시에 저장
        print("💾 타일 데이터 저장 완료: \(tileKey)")
    }
}
