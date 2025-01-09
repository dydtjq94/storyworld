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
    
    init(mapView: MapView) {
        self.mapView = mapView
        setupTapGestureRecognizer()
    }
    
    func setupTapGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleMapTap(_ sender: UITapGestureRecognizer) {
        let tapLocation: CGPoint = sender.location(in: mapView)

        mapView.mapboxMap.queryRenderedFeatures(
            with: tapLocation,
            options: RenderedQueryOptions(layerIds: ["genre-circle-layer"], filter: nil)
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let queriedFeatures):
                // 첫 번째 QueriedRenderedFeature 가져오기
                guard let queriedFeature = queriedFeatures.first else {
                    print("⚠️ 클릭된 위치에서 Feature를 찾을 수 없습니다.")
                    return
                }

                // Feature와 속성 접근
                let feature = queriedFeature.queriedFeature.feature
                guard let genreValue = feature.properties?["genre"],
                      case let .string(genre) = genreValue,
                      let rarityValue = feature.properties?["rarity"],
                      case let .string(rarity) = rarityValue else {
                    print("⚠️ Feature 속성에서 데이터를 추출할 수 없습니다.")
                    return
                }

                print("🎯 클릭된 Circle - Genre: \(genre), Rarity: \(rarity)")
                
                // 햅틱 피드백 추가
                let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy) // 스타일은 .light, .medium, .heavy 선택 가능
                feedbackGenerator.impactOccurred()
                
                // DropController를 모달로 표시
                let dropController = DropController(genre: genre, rarity: rarity)
                dropController.modalPresentationStyle = .overFullScreen // 화면을 꽉 채우도록 설정
                dropController.modalTransitionStyle = .coverVertical // 위에서 아래로 내려오는 애니메이션
                self.mapView.window?.rootViewController?.present(dropController, animated: true, completion: nil)

            case .failure(let error):
                print("❌ Circle 클릭 처리 중 오류 발생: \(error.localizedDescription)")
            }
        }
    }

    
    private func showDropView(genre: String, rarity: String, at location: CGPoint) {
        // 임시로 Print
        print("🎥 DropView - Genre: \(genre), Rarity: \(rarity), Location: \(location)")
    }

    /// 🎨 장르와 Rarity 기반 Circle 및 Symbol 추가sumbo
    func addGenreCircles(data: [MovieService.CircleData], userLocation: CLLocationCoordinate2D) {
        let circleSourceId = "genre-circle-source"
        let symbolSourceId = "genre-symbol-source"
        let circleLayerId = "genre-circle-layer"
        let symbolLayerId = "genre-symbol-layer"

        var circleFeatures: [Feature] = []
        var symbolFeatures: [Feature] = []

        for item in data {
            // ❌ randomLocation 호출 제거
            let location = item.location

            // Circle Feature 생성
            var circleFeature = Feature(geometry: .point(Point(location)))
            circleFeature.properties = [
                "genre": .string(item.genre.rawValue),
                "rarity": .string(item.rarity.rawValue)
            ]
            circleFeatures.append(circleFeature)

            // Symbol Feature 생성
            var symbolFeature = Feature(geometry: .point(Point(location)))
            symbolFeature.properties = [
                "genre": .string(item.genre.rawValue),
                "rarity": .string(item.rarity.rawValue)
            ]
            symbolFeatures.append(symbolFeature)
            
            // Console 출력
            print("🎯 Circle 추가 - Genre: \(item.genre.rawValue), Rarity: \(item.rarity.rawValue), Location: \(location.latitude), \(location.longitude)")
        }

        do {
            // Circle Source 추가
            var circleSource = GeoJSONSource(id: circleSourceId)
            circleSource.data = .featureCollection(FeatureCollection(features: circleFeatures))

            if !mapView.mapboxMap.sourceExists(withId: circleSourceId) {
                try mapView.mapboxMap.addSource(circleSource)
            }

            // Symbol Source 추가
            var symbolSource = GeoJSONSource(id: symbolSourceId)
            symbolSource.data = .featureCollection(FeatureCollection(features: symbolFeatures))

            if !mapView.mapboxMap.sourceExists(withId: symbolSourceId) {
                try mapView.mapboxMap.addSource(symbolSource)
            }

            // Circle Layer 추가 (첫 번째 레이어부터 시작)
            if !mapView.mapboxMap.layerExists(withId: circleLayerId) {
                var circleLayer = CircleLayer(id: circleLayerId, source: circleSourceId)
                // 장르별 색상
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
                // Rarity에 따른 효과
                circleLayer.circleRadius = .constant(14)
                circleLayer.circleOpacity = .constant(0.9)

                // 레이어 순서 설정 (기본적으로 SymbolLayer 아래에 두기)
                circleLayer.sourceLayer = circleLayerId
                try mapView.mapboxMap.addLayer(circleLayer)
            }

            // 아이콘 이미지 등록
            let iconName = "movie-icon"
            if let iconImage = UIImage(named: iconName) {
                registerIconImage(iconName: iconName, image: iconImage)
            }

            // SymbolLayer 추가 (두 번째 레이어부터 시작)
            if !mapView.mapboxMap.layerExists(withId: symbolLayerId) {
                var symbolLayer = SymbolLayer(id: symbolLayerId, source: symbolSourceId)
                symbolLayer.iconImage = .constant(.name(iconName)) // 등록된 이미지 사용
                symbolLayer.iconSize = .constant(0.4) // 아이콘 크기
                symbolLayer.iconAnchor = .constant(.center) // 아이콘 중심 정렬
                symbolLayer.iconAllowOverlap = .constant(true)
                symbolLayer.iconIgnorePlacement = .constant(true)

                do {
                    try mapView.mapboxMap.addLayer(symbolLayer)
                    print("✅ SymbolLayer가 성공적으로 추가되었습니다.")
                } catch {
                    print("❌ SymbolLayer 추가 실패: \(error.localizedDescription)")
                }
            }

            print("✅ 장르 Circle과 Symbol이 성공적으로 추가되었습니다.")
        } catch {
            print("❌ Circle 및 Symbol 추가 실패: \(error.localizedDescription)")
        }
    }


    // 아이콘 이미지를 등록하는 함수
    private func registerIconImage(iconName: String, image: UIImage) {
        do {
            try mapView.mapboxMap.addImage(image, id: iconName)
            print("✅ 아이콘 \(iconName) 이미지가 성공적으로 등록되었습니다.")
        } catch {
            print("❌ 아이콘 이미지를 등록하는 데 실패했습니다: \(error.localizedDescription)")
        }
    }
}
