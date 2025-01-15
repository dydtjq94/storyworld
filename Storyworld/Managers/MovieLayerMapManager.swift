//
//  MovieLayerMapManager.swift
//  Storyworld
//
//  Created by peter on 1/15/25.
//

import MapboxMaps
import UIKit

final class MovieLayerMapManager {
    private let mapView: MapView
    private let tileManager = TileManager()
    private let tileService = TileService()

    init(mapView: MapView) {
        self.mapView = mapView
    }

    func addGenreCircles(data: [MovieService.CircleData], userLocation: CLLocationCoordinate2D, isScan: Bool = false) {
        for (index, item) in data.enumerated() {
            let location = item.location

            // 타일 정보 기반 고유 ID 생성
            let tile = tileManager.calculateTile(for: location, zoomLevel: Int(Constants.Numbers.searchFixedZoomLevel))
            let tileKey = tile.toKey()
            
            let prefix = isScan ? "scan-\(UUID().uuidString)-" : ""
            let sourceId = "\(prefix)source-\(tileKey)"
            let glowLayerId = "\(prefix)glow-layer-\(tileKey)"
            let circleLayerId = "\(prefix)circle-layer-\(tileKey)"
            let symbolLayerId = "\(prefix)symbol-layer-\(tileKey)"

            do {
                // GeoJSONSource 생성
                var feature = Feature(geometry: .point(Point(location)))
                feature.properties = [
                    "genre": .string(item.genre.rawValue),
                    "rarity": .string(item.rarity.rawValue),
                    "id": .string("\(index)")
                ]
                var geoJSONSource = GeoJSONSource(id: sourceId)
                geoJSONSource.data = .feature(feature)

                // Source 추가
                try mapView.mapboxMap.addSource(geoJSONSource)

                // Glow Layer 설정
                var glowLayer = CircleLayer(id: glowLayerId, source: sourceId)
                glowLayer.circleColor = .expression(
                    Exp(.match,
                        Exp(.get, "genre"),
                        MovieGenre.actionAdventure.rawValue, StyleColor(MovieGenre.actionAdventure.uiColor).rawValue,
                        MovieGenre.animation.rawValue, StyleColor(MovieGenre.animation.uiColor).rawValue,
                        MovieGenre.comedy.rawValue, StyleColor(MovieGenre.comedy.uiColor).rawValue,
                        MovieGenre.horrorThriller.rawValue, StyleColor(MovieGenre.horrorThriller.uiColor).rawValue,
                        MovieGenre.documentaryWar.rawValue, StyleColor(MovieGenre.documentaryWar.uiColor).rawValue,
                        MovieGenre.sciFiFantasy.rawValue, StyleColor(MovieGenre.sciFiFantasy.uiColor).rawValue,
                        MovieGenre.drama.rawValue, StyleColor(MovieGenre.drama.uiColor).rawValue,
                        MovieGenre.romance.rawValue, StyleColor(MovieGenre.romance.uiColor).rawValue,
                        StyleColor(UIColor.gray).rawValue // 기본값
                    )
                )
                glowLayer.circleRadius = .expression(
                    Exp(.match,
                        Exp(.get, "rarity"),
                        Rarity.rare.rawValue, 30.0,
                        Rarity.epic.rawValue, 50.0,
                        0.0 // 기본값
                    )
                )
                glowLayer.circleBlur = .constant(1.0)
                glowLayer.circleOpacity = .constant(1.0)

                // Circle Layer 설정
                var circleLayer = CircleLayer(id: circleLayerId, source: sourceId)
                circleLayer.circleColor = .expression(
                    Exp(.match,
                        Exp(.get, "genre"),
                        MovieGenre.actionAdventure.rawValue, StyleColor(MovieGenre.actionAdventure.uiColor).rawValue,
                        MovieGenre.animation.rawValue, StyleColor(MovieGenre.animation.uiColor).rawValue,
                        MovieGenre.comedy.rawValue, StyleColor(MovieGenre.comedy.uiColor).rawValue,
                        MovieGenre.horrorThriller.rawValue, StyleColor(MovieGenre.horrorThriller.uiColor).rawValue,
                        MovieGenre.documentaryWar.rawValue, StyleColor(MovieGenre.documentaryWar.uiColor).rawValue,
                        MovieGenre.sciFiFantasy.rawValue, StyleColor(MovieGenre.sciFiFantasy.uiColor).rawValue,
                        MovieGenre.drama.rawValue, StyleColor(MovieGenre.drama.uiColor).rawValue,
                        MovieGenre.romance.rawValue, StyleColor(MovieGenre.romance.uiColor).rawValue,
                        StyleColor(UIColor.gray).rawValue // 기본값
                    )
                )
                circleLayer.circleRadius = .constant(16.0)
                circleLayer.circleOpacity = .constant(1.0)

                // Symbol Layer 설정
                let iconName = "chim-icon"
                if let iconImage = UIImage(named: iconName) {
                    registerIconImage(iconName: iconName, image: iconImage)
                }
                var symbolLayer = SymbolLayer(id: symbolLayerId, source: sourceId)
                symbolLayer.iconImage = .constant(.name(iconName))
                symbolLayer.iconSize = .constant(1.2)
                symbolLayer.iconAnchor = .constant(.center)
                symbolLayer.iconAllowOverlap = .constant(true)
                symbolLayer.iconIgnorePlacement = .constant(true)

                // Mapbox 지도에 레이어 추가
                try mapView.mapboxMap.addLayer(glowLayer)
                try mapView.mapboxMap.addLayer(circleLayer, layerPosition: .above(glowLayer.id))
                try mapView.mapboxMap.addLayer(symbolLayer, layerPosition: .above(circleLayer.id))

            } catch {
                print("❌ 레이어 추가 실패: \(error.localizedDescription)")
            }
        }
    }

    func removeAllCircles() {
        let allSourceIds = mapView.mapboxMap.allSourceIdentifiers.map { $0.id }
        let allLayerIds = mapView.mapboxMap.allLayerIdentifiers.map { $0.id }

        for sourceId in allSourceIds {
            try? mapView.mapboxMap.removeSource(withId: sourceId)
            print("✅ 소스 제거됨: \(sourceId)")
        }

        for layerId in allLayerIds {
            try? mapView.mapboxMap.removeLayer(withId: layerId)
            print("✅ 레이어 제거됨: \(layerId)")
        }
    }

    private func registerIconImage(iconName: String, image: UIImage) {
        do {
            try mapView.mapboxMap.addImage(image, id: iconName)
        } catch {
            print("❌ 아이콘 이미지를 등록하는 데 실패했습니다: \(error.localizedDescription)")
        }
    }
}
