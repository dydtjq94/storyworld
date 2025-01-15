//
//  GestureManager.swift
//  Storyworld
//
//  Created by peter on 1/15/25.
//

import UIKit
import MapboxMaps

final class GestureManager {
    private let mapView: MapView
    private let onFeatureSelected: (Feature) -> Void

    init(mapView: MapView, onFeatureSelected: @escaping (Feature) -> Void) {
        self.mapView = mapView
        self.onFeatureSelected = onFeatureSelected
        setupTapGestureRecognizer()
    }

    private func setupTapGestureRecognizer() {
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
                guard let queriedFeature = queriedFeatures.first?.queriedFeature.feature else {
                    print("⚠️ 클릭된 위치에서 Feature를 찾을 수 없습니다.")
                    return
                }
                self.onFeatureSelected(queriedFeature)
            case .failure(let error):
                print("❌ Gesture 처리 중 오류 발생: \(error.localizedDescription)")
            }
        }
    }
}
