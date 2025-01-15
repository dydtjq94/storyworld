//
//  MovieViewController.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import UIKit
import MapboxMaps
import Turf

final class MovieController {
    private let mapView: MapView
    private let movieService = MovieService()
    private let tileManager = TileManager() // TileManager 인스턴스 추가
    private var selectedMovie: Movie? // Movie 타입으로 변경
    
    
    init(mapView: MapView, movie: Movie? = nil) {
        self.mapView = mapView
        self.selectedMovie = movie
        setupTapGestureRecognizer()
    }
    
    func updateUIWithMovieData() {
        guard let movie = selectedMovie else { return }
        
        print("🎥 Selected Movie: \(movie.title)")
        print("🎬 Genre: \(movie.genre.rawValue)")
        print("🌟 Rarity: \(movie.rarity.rawValue)")
        // 여기에 포스터, 제목, 즐겨찾기 등을 표시하는 로직 추가
    }
    
    func setupTapGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleMapTap(_ sender: UITapGestureRecognizer) {
        let tapLocation: CGPoint = sender.location(in: mapView)

        mapView.mapboxMap.queryRenderedFeatures(
            with: tapLocation,
            options: RenderedQueryOptions(layerIds: nil, filter: nil) // 모든 레이어에서 탐지
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let queriedFeatures):
                guard let queriedFeature = queriedFeatures.first else {
                    print("⚠️ 클릭된 위치에서 Feature를 찾을 수 없습니다.")
                    return
                }
                
                let feature = queriedFeature.queriedFeature.feature
                
                guard case let .point(pointGeometry) = feature.geometry else {
                    print("⚠️ Feature의 좌표를 가져올 수 없습니다.")
                    return
                }

                let coordinates = pointGeometry.coordinates


                guard let genreValue = feature.properties?["genre"],
                      case let .string(genre) = genreValue,
                      let rarityValue = feature.properties?["rarity"],
                      case let .string(rarity) = rarityValue else {
                    print("⚠️ Feature 속성에서 데이터를 추출할 수 없습니다.")
                    return
                }
                
                guard let movieGenre = MovieGenre(rawValue: genre),
                      let genreIds = TMDbResponse.mergedGenres[movieGenre],
                      let selectedGenreId = genreIds.randomElement() else {
                    print("⚠️ 잘못된 장르 데이터입니다.")
                    return
                }
                
                // 현재 위치 가져오기
                guard let userLocation = self.mapView.location.latestLocation?.coordinate else {
                    print("⚠️ 사용자 위치를 가져올 수 없습니다.")
                    return
                }
                
                // 거리 계산
                let circleLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                let userLocationCL = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                let distance = userLocationCL.distance(from: circleLocation)
                
                // 반경에 따른 처리
                if distance <= 200 {
                    // 50m 이내의 클릭
                    print("✅ 50m 이내의 Circle 클릭, 현재 거리: \(distance)m")
                    self.handleDropWithin50m(movieGenre: movieGenre, rarity: rarity, selectedGenreId: selectedGenreId)
                } else if distance <= 500 {
                    // 50m ~ 200m 클릭
                    print("⚠️ 50m ~ 200m Circle 클릭 - PRO 구독 필요, 현재 거리: \(distance)m")
                    self.showProSubscriptionMessage()
                } else {
                    // 200m 초과 클릭
                    print("⚠️ 200m 초과 Circle 클릭 - 광고 보기 필요, 현재 거리: \(distance)m")
                    self.showAdMessage()
                }

            case .failure(let error):
                print("❌ Circle 클릭 처리 중 오류 발생: \(error.localizedDescription)")
            }
        }
    }
    
    // 50m 이내 Circle 클릭 처리
    private func handleDropWithin50m(movieGenre: MovieGenre, rarity: String, selectedGenreId: Int) {
        print("🎯 클릭된 Circle - Genre: \(movieGenre.rawValue), Rarity: \(rarity)")
        print("🎬 정해진 장르 ID: \(selectedGenreId)")
        
        // Haptic Feedback 추가
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare() // 미리 준비
        feedbackGenerator.impactOccurred() // Haptic 발생
        
        // Info.plist에서 API Key 가져오기
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String else {
            print("❌ TMDB API Key를 가져올 수 없습니다.")
            return
        }
        
        let tmdbService = TMDbService(apiKey: apiKey)

        let dropController = DropController(
            genre: movieGenre,
            selectedGenreId: selectedGenreId, // 고정된 장르 ID 전달
            rarity: rarity,
            tmdbService: tmdbService
        )
        dropController.modalPresentationStyle = .overFullScreen
        dropController.modalTransitionStyle = .coverVertical
        mapView.window?.rootViewController?.present(dropController, animated: true, completion: nil)
    }
    
    // 50m ~ 200m 클릭 처리 - PRO 구독 필요 메시지
    private func showProSubscriptionMessage() {
        // Haptic Feedback 추가
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare() // 미리 준비
        feedbackGenerator.impactOccurred() // Haptic 발생
        print("🔒 PRO 구독이 필요합니다.")
        // PRO 구독 안내 화면을 추가로 구현 가능
    }

    // 200m 초과 클릭 처리 - 광고 보기 필요 메시지
    private func showAdMessage() {
        // Haptic Feedback 추가
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare() // 미리 준비
        feedbackGenerator.impactOccurred() // Haptic 발생
        print("📢 광고 보기가 필요합니다.")
        // 광고 보기 화면을 추가로 구현 가능
    }
    
    func addCirclesForTiles(_ visibleTiles: [Tile], zoomLevel: Int, isScan: Bool = false) {
        for tile in visibleTiles {
            let tileKey = tile.toKey()

            // 이미 처리된 타일인지 확인
            if tileManager.hasProcessedTile(tile) {
                print("⚠️ 이미 처리된 타일: \(tileKey)")
                continue
            }

            // Circle 데이터 생성 또는 불러오기
            let tileCenter = tileManager.centerOfTile(x: tile.x, y: tile.y, zoomLevel: zoomLevel)
            let circleData = movieService.createCircleData(around: tileCenter)

            // 레이어는 초기 위치 기반 또는 스캔 시에만 생성
            if isScan || visibleTiles.contains(tile) {
                print("✅ 레이어 추가 작업 - TileKey: \(tileKey)")
                addGenreCircles(data: circleData, userLocation: tileCenter, isScan: isScan)
            }

            // 타일을 처리된 상태로 저장
            tileManager.markTileAsProcessed(tile, circles: circleData)
        }
    }
    
    /// 🎨 장르와 Rarity 기반 Circle 및 Symbol 추가
    func addGenreCircles(data: [MovieService.CircleData], userLocation: CLLocationCoordinate2D, isScan: Bool = false) {
        for (index, item) in data.enumerated() {
            let location = item.location
            let tile = tileManager.calculateTile(for: location, zoomLevel: 16)

            if tileManager.isLayerAdded(for: tile) {
                print("⚠️ 이미 추가된 레이어: \(tile.toKey())")
                continue
            }
            
            // ID 생성: Scan 데이터와 기존 데이터 구분
            let prefix = isScan ? "scan-\(UUID().uuidString)-" : ""
            let sourceId = "\(prefix)source-\(index)"
            let glowLayerId = "\(prefix)glow-layer-\(index)"
            let circleLayerId = "\(prefix)circle-layer-\(index)"
            let symbolLayerId = "\(prefix)symbol-layer-\(index)"

            // 기존 소스와 레이어 확인
            if mapView.mapboxMap.sourceExists(withId: sourceId) || mapView.mapboxMap.layerExists(withId: circleLayerId) {
                print("⚠️ 이미 존재하는 소스 또는 레이어: \(sourceId), \(circleLayerId)")
                continue
            }

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
                print("✅ 소스 추가 완료: \(sourceId)")

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
                circleLayer.circleRadius = .constant(14.0)
                circleLayer.circleOpacity = .constant(1.0)

                // Symbol Layer 설정
                let iconName = "chim-icon"
                if let iconImage = UIImage(named: iconName) {
                    registerIconImage(iconName: iconName, image: iconImage)
                }
                var symbolLayer = SymbolLayer(id: symbolLayerId, source: sourceId)
                symbolLayer.iconImage = .constant(.name(iconName))
                symbolLayer.iconSize = .constant(1.0)
                symbolLayer.iconAnchor = .constant(.center)
                symbolLayer.iconAllowOverlap = .constant(true)
                symbolLayer.iconIgnorePlacement = .constant(true)

                // Mapbox 지도에 레이어 추가
                try mapView.mapboxMap.addLayer(glowLayer)
                try mapView.mapboxMap.addLayer(circleLayer, layerPosition: .above(glowLayer.id))
                try mapView.mapboxMap.addLayer(symbolLayer, layerPosition: .above(circleLayer.id))

                print("✅ 레이어 추가 완료: \(circleLayerId), \(symbolLayerId)")

                // 레이어 상태를 TileManager에 저장
                tileManager.markLayerAsAdded(for: tile)
                print("✅ TileManager에 레이어 상태 저장 완료: \(tile.toKey())")
            } catch {
                print("❌ 레이어 추가 실패: \(error.localizedDescription)")
            }
        }
    }

    // 아이콘 이미지를 등록하는 함수
    private func registerIconImage(iconName: String, image: UIImage) {
        do {
            try mapView.mapboxMap.addImage(image, id: iconName)
        } catch {
            print("❌ 아이콘 이미지를 등록하는 데 실패했습니다: \(error.localizedDescription)")
        }
    }
}

extension MovieController {
    func removeAllCircles() {
        // 모든 소스 및 레이어 제거
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
}
