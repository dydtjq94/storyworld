//
//  StyleManager.swift
//  Storyworld
//
//  Created by peter on 1/15/25.
//

import MapboxMaps

final class MapStyleManager {
    private let mapView: MapView

    // MARK: - Initializer
    init(mapView: MapView) {
        self.mapView = mapView
    }

    // MARK: - Methods

    /// 다크 모드 스타일 적용
    func applyDarkStyle(completion: (() -> Void)? = nil) {
        mapView.mapboxMap.loadStyle(.dark) { [weak self] error in
            if let error = error {
                print("❌ 다크 모드 스타일 적용 실패: \(error.localizedDescription)")
            } else {
                print("✅ 다크 모드 스타일이 성공적으로 적용되었습니다.")
                self?.removeUnwantedLayers()
                completion?()
            }
        }
    }

    /// 불필요한 Mapbox 레이어 제거
    func removeUnwantedLayers() {
        let unwantedLayers = [
            "poi-label",        // POI 라벨 제거
            "poi",              // POI 아이콘 제거
            "road-label",       // 도로 라벨 제거
            "transit-label"     // 교통 라벨 제거
        ]

        for layerId in unwantedLayers {
            if mapView.mapboxMap.layerExists(withId: layerId) {
                try? mapView.mapboxMap.removeLayer(withId: layerId)
                print("✅ 레이어 제거됨: \(layerId)")
            } else {
                print("⚠️ 제거할 레이어를 찾을 수 없음: \(layerId)")
            }
        }
        print("✅ 불필요한 레이어가 성공적으로 제거되었습니다.")
    }

    /// 사용자 정의 스타일 적용
    func applyCustomStyle(from styleURI: StyleURI, completion: (() -> Void)? = nil) {
        mapView.mapboxMap.loadStyleURI(styleURI) { error in
            if let error = error {
                print("❌ 스타일 적용 실패: \(error.localizedDescription)")
            } else {
                print("✅ 사용자 정의 스타일 적용 완료.")
                completion?()
            }
        }
    }
}
