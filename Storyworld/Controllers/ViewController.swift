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
    private let initialZoom: Double = 15.0 // 지도에 표시할 최대 반경

    private var sourceId = "circle-source"
    private var smallCircleLayerId = "small-circle-layer"
    private var largeCircleLayerId = "large-circle-layer"
    private let movieService = MovieService() // 추가
    private var movieController: MovieController?
    private let tileManager = TileManager()
    private var isLocationPermissionHandled = false // 권한 처리 여부 확인 변수
    private var isMovieDataLoaded = false // 영화 데이터 로드 여부 추가
    
    private var lastBackgroundTime: Date? // 마지막 백그라운드 전환 시각

    override func viewDidLoad() {
        super.viewDidLoad()
        tileManager.resetLayerStates() // 모든 레이어 상태 초기화
        setupMapView()
        setupLocationManager()
        setupNotifications()

        // 내 위치 중심으로 레이어 다시 그림
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.renderInitialLayers()
        }
    }
    
    private func renderInitialLayers() {
        guard let latestLocation = mapView.location.latestLocation else {
            print("⚠️ 사용자 위치를 가져올 수 없습니다.")
            return
        }

        let userLocation = latestLocation.coordinate
        print("📍 초기 사용자 위치: \(userLocation.latitude), \(userLocation.longitude)")
        fetchCircleData(centerCoordinate: userLocation, zoomLevel: 16)
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
        
        // ✅사용자 위치 표시 설정
        configureUserLocationDisplay()
        
        // ✅ MovieController 초기화
        movieController = MovieController(mapView: mapView)
        
        
        handleStyleLoadedEvent()

        // ✅ MapView를 뷰에 추가
        view.addSubview(mapView)
    }
    
    // MARK: - Notification 설정
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScanButtonTapped),
            name: .scanButtonTapped,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClearCacheTapped),
            name: .clearCacheTapped,
            object: nil
        )
    }

    @objc private func handleClearCacheTapped() {
        movieService.clearCache()
        print("✅ 캐시가 성공적으로 삭제되었습니다.")
    }
    
    // MARK: - 앱이 포그라운드로 돌아왔을 때
    @objc private func handleAppWillEnterForeground() {
        guard let lastBackgroundTime = lastBackgroundTime else { return }
        let timeInBackground = Date().timeIntervalSince(lastBackgroundTime)

        // 30초 이상 백그라운드에 있었다면 현재 위치로 이동
        if timeInBackground > 60 {
            print("🔄 앱이 60초 이상 백그라운드에 있었습니다. 현재 위치로 화면 이동.")
            moveCameraToCurrentLocation()
        }
    }

    // MARK: - 앱이 백그라운드로 전환될 때
    @objc private func handleAppDidEnterBackground() {
        lastBackgroundTime = Date() // 백그라운드 전환 시각 저장
        print("🔄 앱이 백그라운드로 전환되었습니다.")
    }

    // MARK: - 현재 위치로 화면 이동
    private func moveCameraToCurrentLocation() {
        guard let userLocation = mapView.location.latestLocation else {
            print("⚠️ 현재 위치 정보를 가져올 수 없습니다.")
            return
        }

        setInitialCamera(to: userLocation.coordinate)
        print("📍 현재 위치로 화면을 이동했습니다: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
    }

    // 기존 코드는 변경하지 않음
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func configureUserLocationDisplay() {
        // ✅ 사용자 위치 표시 (화살표 포함)
        mapView.location.options.puckType = .puck2D(Puck2DConfiguration.makeDefault(showBearing: true))
        mapView.location.options.puckBearingEnabled = true
        mapView.location.options.puckBearing = .heading
        print("✅ 사용자 위치 표시 설정 완료")
    }
    
    
    // Handle Scan Button Tapped
    @objc private func handleScanButtonTapped() {
        performZoom(to: 16.0) { [weak self] in
            guard let self = self else { return }

            let centerCoordinate = self.mapView.mapboxMap.cameraState.center
            self.fetchCircleData(centerCoordinate: centerCoordinate, zoomLevel: 16)

            self.performZoom(to: 15.0) {
                print("✅ Zoom 레벨이 15.0으로 복구되었습니다.")
            }
        }
    }
    
    // Zoom 설정 및 복구를 함께 처리
    private func performZoom(to zoomLevel: Double, completion: @escaping () -> Void) {
        // Zoom 설정 (애니메이션 포함)
        mapView.camera.ease(
            to: CameraOptions(zoom: zoomLevel),
            duration: 1.0, // 애니메이션 시간
            curve: .easeInOut
        ) { _ in
            print("✅ Zoom 레벨이 \(zoomLevel)으로 설정되었습니다.")
            completion() // 줌 레벨 변경이 완료된 후 작업 수행
        }
    }


    private var styleLoadedCancelable: AnyCancelable? // Cancelable 객체 저장용 변수

    private func handleStyleLoadedEvent() {
        styleLoadedCancelable = mapView.mapboxMap.onStyleLoaded.observe { [weak self] _ in
            guard let self = self else { return }

            // 사용자 위치 가져오기 (초기 위치)
            let userLocation = self.mapView.location.latestLocation?.coordinate
                ?? CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 기본 위치: 서울

            // 초기 카메라 설정
            self.setInitialCamera(to: userLocation)
            print("🛠️ 스타일 로드 완료, 초기 카메라 설정 - \(userLocation.latitude), \(userLocation.longitude)")

            // 원 추가
            self.addCircleLayers(at: userLocation)

            // 초기 데이터를 현재 위치 중심으로 가져오기
            self.fetchCircleData(centerCoordinate: userLocation, zoomLevel: 16)
            
            // Puck 재배치
            self.reloadLocationPuck()
        }
    }
    
    private func fetchCircleData(centerCoordinate: CLLocationCoordinate2D, zoomLevel: Int) {
        let sideLength = 1000.0 // 1,000m 범위
        let visibleTiles = tileManager.tilesInRange(center: centerCoordinate, sideLength: sideLength, zoomLevel: zoomLevel)

        print("📍 현재 보이는 타일: \(visibleTiles.count)")
        print("📍 타일 리스트: \(visibleTiles)")

        visibleTiles.forEach { tile in
            if let circles = tileManager.getCircleData(for: tile) {
                // 저장된 Circle 데이터가 있으면 레이어 추가
                if !tileManager.isLayerAdded(for: tile) {
                    movieController?.addGenreCircles(data: circles, userLocation: centerCoordinate, isScan: true)
                    tileManager.markLayerAsAdded(for: tile)
                    print("✅ 기존 데이터를 기반으로 레이어 추가 완료 - Tile: \(tile.toKey())")
                }
            } else {
                // Circle 데이터가 없으면 새로 생성
                let newCircles = movieService.createCircleData(
                    around: tileManager.centerOfTile(x: tile.x, y: tile.y, zoomLevel: tile.z)
                )
                tileManager.saveCircleData(for: tile, circles: newCircles)
                movieController?.addGenreCircles(data: newCircles, userLocation: centerCoordinate, isScan: true)
                tileManager.markLayerAsAdded(for: tile)
                print("🆕 새 데이터를 생성하고 레이어 추가 완료 - Tile: \(tile.toKey())")
            }
        }

        print("✅ Circle 데이터 처리가 완료되었습니다.")
    }
    private func reloadLocationPuck() {
        // 현재 Puck을 비활성화
        mapView.location.options.puckType = nil
        print("✅ Puck 비활성화 완료")

        // Puck 다시 활성화 (레이어 재배치)
        mapView.location.options.puckType = .puck2D(Puck2DConfiguration.makeDefault(showBearing: true))
        mapView.location.options.puckBearingEnabled = true
        mapView.location.options.puckBearing = .heading
        print("✅ Puck 다시 활성화 완료")
    }

    private func removeUnwantedLayers() {
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
    
    // MARK: - 다크 모드 스타일 적용
    private func applyDarkStyle() {
        mapView.mapboxMap.loadStyle(.dark) { error in
            if let error = error {
                print("❌ 다크 모드 스타일 적용 실패: \(error.localizedDescription)")
            } else {
                print("✅ 다크 모드 스타일이 성공적으로 적용되었습니다.")
                self.removeUnwantedLayers()
            }
        }
    }
    
    private func setInitialCamera(to coordinate: CLLocationCoordinate2D) {
        let cameraOptions = CameraOptions(center: coordinate, zoom: initialZoom) // 초기 zoom 단계
        mapView.mapboxMap.setCamera(to: cameraOptions)
        print("📍 초기 카메라가 사용자 위치로 설정되었습니다.")
    }

    
    // MARK: - 사용자 위치 업데이트
    private var isInitialCameraSet = false
    
    private var lastUpdatedLocation: CLLocation?
    private let minimumDistanceThreshold: CLLocationDistance = 5 // 10m 이상 이동 시 업데이트

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // 하드웨어 필터링 (5m)
        locationManager.startUpdatingLocation()
    }
    
    // 위치 권한 변경 시 호출
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
       guard !isLocationPermissionHandled else { return }
       isLocationPermissionHandled = true

       let status = manager.authorizationStatus
       switch status {
       case .authorizedWhenInUse, .authorizedAlways:
           print("✅ 위치 권한 허용됨.")
           locationManager.startUpdatingLocation() // 위치 업데이트 시작
           loadCachedCirclesOrFetch()
       case .denied, .restricted:
           print("❌ 위치 권한 거부됨.")
           showDefaultMovieCircles() // 기본 위치에 Circle 추가
       case .notDetermined:
           print("❓ 위치 권한 결정되지 않음.")
       @unknown default:
           print("⚠️ 알 수 없는 위치 권한 상태.")
       }
    }
    
    private func loadCachedCirclesOrFetch() {
        guard let userLocation = locationManager.location?.coordinate else {
            print("⚠️ 사용자 위치를 가져올 수 없습니다.")
            return
        }

        movieService.getCircleData(userLocation: userLocation) { [weak self] circleData in
            guard let self = self else { return }

            // 초기 데이터를 생성하면서 그리드 관리 적용
            for circle in circleData {
                let gridKey = self.movieService.circleCacheManager.gridKey(for: circle.location)
                self.movieService.circleCacheManager.markGridAsScanned(key: gridKey)
            }

            self.movieController?.addGenreCircles(data: circleData, userLocation: userLocation)
        }
    }
    
    private func showDefaultMovieCircles() {
        let defaultLocation = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 서울 중심
        movieService.getCircleData(userLocation: defaultLocation) { [weak self] circleData in
            guard let self = self, let movieController = self.movieController else { return }
            movieController.addGenreCircles(data: circleData, userLocation: defaultLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
//        
//        if !isInitialCameraSet {
//            // 초기 카메라 설정 및 원 추가
//            setInitialCamera(to: userLocation.coordinate)
//            isInitialCameraSet = true
//            lastUpdatedLocation = userLocation
//            print("🛠️ 초기 카메라 위치 설정 완료 - 중심: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
//            return
//        }
        
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
    
    private func createCirclePolygon(center: CLLocationCoordinate2D, radius: Double) -> Feature {
        _ = Turf.Point(center)
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
    
    private func addCircleLayers(at coordinate: CLLocationCoordinate2D) {
        do {
            // 작은 원 (50m)
            let smallCircleSourceId = "small-circle-source"
            var smallCircleSource = GeoJSONSource(id: smallCircleSourceId)
            smallCircleSource.data = .feature(createCirclePolygon(center: coordinate, radius: 40))
            
            if !mapView.mapboxMap.sourceExists(withId: smallCircleSourceId) {
                try mapView.mapboxMap.addSource(smallCircleSource)
            }
        
            var smallCircleLayer = FillLayer(id: "small-circle-layer", source: smallCircleSourceId)
            smallCircleLayer.fillColor = .constant(StyleColor(UIColor.systemRed.withAlphaComponent(0.5)))
//            smallCircleLayer.fillOutlineColor = .constant(StyleColor(UIColor.systemBlue))
            
            if !mapView.mapboxMap.layerExists(withId: "small-circle-layer") {
                try mapView.mapboxMap.addLayer(smallCircleLayer)
            }
       
            // 큰 원 (200m)
            let largeCircleSourceId = "large-circle-source"
            var largeCircleSource = GeoJSONSource(id: largeCircleSourceId)
            largeCircleSource.data = .feature(createCirclePolygon(center: coordinate, radius: 160))
            
            if !mapView.mapboxMap.sourceExists(withId: largeCircleSourceId) {
                try mapView.mapboxMap.addSource(largeCircleSource)
            }
        
            var largeCircleLayer = FillLayer(id: "large-circle-layer", source: largeCircleSourceId)
            largeCircleLayer.fillColor = .constant(StyleColor(UIColor.systemOrange.withAlphaComponent(0.4)))
//            largeCircleLayer.fillOutlineColor = .constant(StyleColor(UIColor.systemGreen))
            
            if !mapView.mapboxMap.layerExists(withId: "large-circle-layer") {
                try mapView.mapboxMap.addLayer(largeCircleLayer)
            }
            
            print("✅ 원이 성공적으로 추가되었습니다.")
            
        } catch {
            print("❌ 원 추가 실패: \(error.localizedDescription)")
        }
    }
    
    func updateCircleLayers(with coordinate: CLLocationCoordinate2D) {
        let smallCircleSourceId = "small-circle-source"
        let largeCircleSourceId = "large-circle-source"
        
        // 작은 원 업데이트
        let smallCircleFeature = createCirclePolygon(center: coordinate, radius: 50)
        mapView.mapboxMap.updateGeoJSONSource(
        withId: smallCircleSourceId,
        geoJSON: .feature(smallCircleFeature)
        )
        
        // 큰 원 업데이트
        let largeCircleFeature = createCirclePolygon(center: coordinate, radius: 200)
        mapView.mapboxMap.updateGeoJSONSource(
        withId: largeCircleSourceId,
        geoJSON: .feature(largeCircleFeature)
        )
        
        print("✅ 원 위치가 성공적으로 업데이트되었습니다.")

    }
    
}
