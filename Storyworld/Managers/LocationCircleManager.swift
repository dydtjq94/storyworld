//
//  LocationCircleManager.swift
//  Storyworld
//
//  Created by peter on 1/15/25.
//

import MapboxMaps
import Turf
import CoreLocation
import UIKit

final class LocationCircleManager {
    private let smallCircleLayerId = "small-circle-layer"
    private let largeCircleLayerId = "large-circle-layer"
    private let smallCircleSourceId = "small-circle-source"
    private let largeCircleSourceId = "large-circle-source"

    // MARK: - Circle Polygon 생성
    func createCirclePolygon(center: CLLocationCoordinate2D, radius: Double) -> Feature {
        let numberOfSteps = 120 // 원의 정밀도(세그먼트 수)
        let distance = Measurement(value: radius, unit: UnitLength.meters).converted(to: .meters).value
        var coordinates: [CLLocationCoordinate2D] = []

        for i in 0...numberOfSteps {
            let angle = Double(i) * (360.0 / Double(numberOfSteps))
            let radians = angle * .pi / 180
            let latitude = center.latitude + (distance / 111000.0) * cos(radians)
            let longitude = center.longitude + (distance / (111000.0 * cos(center.latitude * .pi / 180))) * sin(radians)
            coordinates.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }
        coordinates.append(coordinates.first!) // 마지막 좌표는 첫 좌표로 닫음

        let polygon = Polygon([coordinates])
        return Feature(geometry: .polygon(polygon))
    }

    // MARK: - Circle Layer 추가
    func addCircleLayers(to mapView: MapView, at coordinate: CLLocationCoordinate2D) {
        do {
            // 작은 원 (50m)
            var smallCircleSource = GeoJSONSource(id: smallCircleSourceId)
            smallCircleSource.data = .feature(createCirclePolygon(center: coordinate, radius: Constants.Numbers.smallCircleRadius))
            
            if !mapView.mapboxMap.sourceExists(withId: smallCircleSourceId) {
                try mapView.mapboxMap.addSource(smallCircleSource)
            }
            
            var smallCircleLayer = FillLayer(id: smallCircleLayerId, source: smallCircleSourceId)
            smallCircleLayer.fillColor = .constant(StyleColor(UIColor.systemRed.withAlphaComponent(0.5)))

            if !mapView.mapboxMap.layerExists(withId: smallCircleLayerId) {
                try mapView.mapboxMap.addLayer(smallCircleLayer)
            }

            // 큰 원 (200m)
            var largeCircleSource = GeoJSONSource(id: largeCircleSourceId)
            largeCircleSource.data = .feature(createCirclePolygon(center: coordinate, radius: Constants.Numbers.largeCircleRadius))

            if !mapView.mapboxMap.sourceExists(withId: largeCircleSourceId) {
                try mapView.mapboxMap.addSource(largeCircleSource)
            }

            var largeCircleLayer = FillLayer(id: largeCircleLayerId, source: largeCircleSourceId)
            largeCircleLayer.fillColor = .constant(StyleColor(UIColor.systemOrange.withAlphaComponent(0.4)))

            if !mapView.mapboxMap.layerExists(withId: largeCircleLayerId) {
                try mapView.mapboxMap.addLayer(largeCircleLayer)
            }
            
            print("✅ Circle Layers successfully added.")
        } catch {
            print("❌ Failed to add Circle Layers: \(error.localizedDescription)")
        }
    }

    // MARK: - Circle Layer 업데이트
    func updateCircleLayers(for mapView: MapView, at coordinate: CLLocationCoordinate2D) {
        let smallCircleFeature = createCirclePolygon(center: coordinate, radius: Constants.Numbers.smallCircleRadius)
        mapView.mapboxMap.updateGeoJSONSource(
            withId: smallCircleSourceId,
            geoJSON: .feature(smallCircleFeature)
        )

        let largeCircleFeature = createCirclePolygon(center: coordinate, radius: Constants.Numbers.largeCircleRadius)
        mapView.mapboxMap.updateGeoJSONSource(
            withId: largeCircleSourceId,
            geoJSON: .feature(largeCircleFeature)
        )

        print("✅ Circle Layers successfully updated.")
    }
}
