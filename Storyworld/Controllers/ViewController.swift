//
//  ViewController.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import UIKit
import MapboxMaps
import CoreLocation
import Turf

final class ViewController: UIViewController, CLLocationManagerDelegate {
    private var mapView: MapView!
       private let locationManager = CLLocationManager()
       
       private var sourceId = "circle-source"
       private var smallCircleLayerId = "small-circle-layer"
       private var largeCircleLayerId = "large-circle-layer"
       
       private var movieController: MovieController?
       private var isMovieDataLoaded = false // 영화 데이터 로드 여부 추가
       
       override func viewDidLoad() {
           super.viewDidLoad()
           setupLocationManager()
           setupMapView()
       }
    
    // MARK: - MapView 설정
    private func setupMapView() {
        // ✅ Info.plist에서 AccessToken 가져오기
        guard Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") is String else {
            fatalError("❌ Mapbox Access Token이 Info.plist에 설정되지 않았습니다.")
        }
        
        // ✅ MapInitOptions 초기화
        let mapInitOptions = MapInitOptions(
            cameraOptions: CameraOptions(zoom: 15.0),
            styleURI: .dark // 🌙 다크 모드 적용
        )
        
        // ✅ MapView 설정
        mapView = MapView(frame: view.bounds, mapInitOptions: mapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // ✅ MovieController 초기화
        movieController = MovieController(mapView: mapView)
        
        // ✅ 사용자 위치 표시 (화살표 포함)
        mapView.location.options.puckType = .puck2D(Puck2DConfiguration.makeDefault(showBearing: true))
        mapView.location.options.puckBearingEnabled = true
        mapView.location.options.puckBearing = .heading
        
        mapView.mapboxMap.onNext(event: .styleLoaded) { [weak self] _ in
            guard let self = self else { return }

            do {
                // 사용자 위치 가져오기
                let coordinate = self.mapView.location.latestLocation?.coordinate
                    ?? CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 기본 위치: 서울

                // 초기 카메라 설정
                self.setInitialCamera(to: coordinate)
                print("🛠️ 스타일 로드 완료, 초기 카메라 설정 - \(coordinate.latitude), \(coordinate.longitude)")

                // 원 추가
                try self.addCircleLayers(at: coordinate)

                // 영화 데이터 로드 및 지도에 추가
                if let movieController = self.movieController {
                    movieController.loadMovies(around: coordinate) // 🎬 영화 데이터 로드
                } else {
                    print("⚠️ MovieController가 초기화되지 않았습니다.")
                }
            } catch {
                print("❌ 예외 발생: \(error.localizedDescription)")
            }
        }
        
        
        // ✅ MapView를 뷰에 추가
        view.addSubview(mapView)
    }
    
    private func removeUnwantedLayers() {
        let unwantedLayers = [
            "poi-label",        // POI 라벨 제거
            "poi",              // POI 아이콘 제거
            "road-label",       // 도로 라벨 제거
            "transit-label"     // 교통 라벨 제거
        ]
        
        for layerId in unwantedLayers {
            if mapView.mapboxMap.style.layerExists(withId: layerId) {
                try? mapView.mapboxMap.style.removeLayer(withId: layerId)
                print("✅ 레이어 제거됨: \(layerId)")
            } else {
                print("⚠️ 제거할 레이어를 찾을 수 없음: \(layerId)")
            }
        }
        
        print("✅ 불필요한 레이어가 성공적으로 제거되었습니다.")
    }
    
    // MARK: - 다크 모드 스타일 적용
    private func applyDarkStyle() {
        mapView.mapboxMap.loadStyleURI(.dark) { error in
            if let error = error {
                print("❌ 다크 모드 스타일 적용 실패: \(error.localizedDescription)")
            } else {
                print("✅ 다크 모드 스타일이 성공적으로 적용되었습니다.")
                self.removeUnwantedLayers()
            }
        }
    }
    
//    private func setInitialCamera(to coordinate: CLLocationCoordinate2D) {
//        let cameraOptions = CameraOptions(center: coordinate, zoom: 15.0)
//        mapView.mapboxMap.setCamera(to: cameraOptions)
//        print("📍 초기 카메라가 사용자 위치로 설정되었습니다.")
//    }
    
    private func setInitialCamera(to coordinate: CLLocationCoordinate2D) {
        let cameraOptions = CameraOptions(center: coordinate, zoom: 15.0)
        mapView.camera.fly(to: cameraOptions, duration: 1.0) // 2초 동안 부드럽게 이동
        print("📍 초기 카메라가 사용자 위치로 설정되었습니다.")
    }

    
    // MARK: - 사용자 위치 업데이트
    private var isInitialCameraSet = false
    
    private var lastUpdatedLocation: CLLocation?
    private let minimumDistanceThreshold: CLLocationDistance = 10 // 10m 이상 이동 시 업데이트

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // 하드웨어 필터링 (5m)
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
        if !isInitialCameraSet {
            // 초기 카메라 설정 및 원 추가
            setInitialCamera(to: userLocation.coordinate)
            addCircleLayers(at: userLocation.coordinate)
            isInitialCameraSet = true
            lastUpdatedLocation = userLocation
            print("🛠️ 초기 카메라 위치 설정 완료 - 중심: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
            return
        }
        
        // 소프트웨어 수준 필터링
        if let lastLocation = lastUpdatedLocation {
            let distance = userLocation.distance(from: lastLocation)
            print("📏 이동 거리: \(String(format: "%.2f", distance))m")
            
            if distance < minimumDistanceThreshold {
                print("⚠️ 위치 변화가 미미함, 업데이트 생략")
                return
            }
        }
        
        // ✅ 업데이트 수행
        updateCircleLayers(with: userLocation.coordinate)
        lastUpdatedLocation = userLocation
        print("📍 사용자 위치 업데이트됨 - 원만 업데이트됨, 화면 유지")
    }

    // ✅ 거리 계산 함수
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    private func createCirclePolygon(center: CLLocationCoordinate2D, radius: Double) -> Feature {
        let centerPoint = Turf.Point(center)
        let numberOfSteps = 64 // 원의 정밀도(세그먼트 수)
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
    
    private func addCircleLayers(at coordinate: CLLocationCoordinate2D) {
        do {
            // 작은 원 (50m)
            let smallCircleSourceId = "small-circle-source"
            var smallCircleSource = GeoJSONSource(id: smallCircleSourceId)
            smallCircleSource.data = .feature(createCirclePolygon(center: coordinate, radius: 50))
            
            if !mapView.mapboxMap.style.sourceExists(withId: smallCircleSourceId) {
                try mapView.mapboxMap.style.addSource(smallCircleSource)
            }
        
            var smallCircleLayer = FillLayer(id: "small-circle-layer", source: smallCircleSourceId)
            smallCircleLayer.fillColor = .constant(StyleColor(UIColor.systemBlue.withAlphaComponent(0.2)))
            smallCircleLayer.fillOutlineColor = .constant(StyleColor(UIColor.systemBlue))
            
            if !mapView.mapboxMap.style.layerExists(withId: "small-circle-layer") {
                try mapView.mapboxMap.style.addLayer(smallCircleLayer)
            }
       
            // 큰 원 (200m)
            let largeCircleSourceId = "large-circle-source"
            var largeCircleSource = GeoJSONSource(id: largeCircleSourceId)
            largeCircleSource.data = .feature(createCirclePolygon(center: coordinate, radius: 200))
            
            if !mapView.mapboxMap.style.sourceExists(withId: largeCircleSourceId) {
                try mapView.mapboxMap.style.addSource(largeCircleSource)
            }
        
            var largeCircleLayer = FillLayer(id: "large-circle-layer", source: largeCircleSourceId)
            largeCircleLayer.fillColor = .constant(StyleColor(UIColor.systemGreen.withAlphaComponent(0.2)))
            largeCircleLayer.fillOutlineColor = .constant(StyleColor(UIColor.systemGreen))
            
            if !mapView.mapboxMap.style.layerExists(withId: "large-circle-layer") {
                try mapView.mapboxMap.style.addLayer(largeCircleLayer)
            }
            
            print("✅ 원이 성공적으로 추가되었습니다.")
            
        } catch {
            print("❌ 원 추가 실패: \(error.localizedDescription)")
        }
    }

    
    func updateCircleLayers(with coordinate: CLLocationCoordinate2D) {
        let smallCircleSourceId = "small-circle-source"
        let largeCircleSourceId = "large-circle-source"
        
        do {
            // 작은 원 업데이트
            let smallCircleFeature = createCirclePolygon(center: coordinate, radius: 50)
            try mapView.mapboxMap.style.updateGeoJSONSource(
                withId: smallCircleSourceId,
                geoJSON: .feature(smallCircleFeature)
            )
            
            // 큰 원 업데이트
            let largeCircleFeature = createCirclePolygon(center: coordinate, radius: 200)
            try mapView.mapboxMap.style.updateGeoJSONSource(
                withId: largeCircleSourceId,
                geoJSON: .feature(largeCircleFeature)
            )
            
            print("✅ 원 위치가 성공적으로 업데이트되었습니다.")
        } catch {
            print("❌ 원 위치 업데이트 실패: \(error.localizedDescription)")
        }
    }
    
    
    
}
