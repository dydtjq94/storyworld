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
    private let movieService = MovieService()
    private var movieController: MovieController?
    private let tileManager = TileManager()
    private let locationCircleManager = LocationCircleManager()
    private var notificationManager: NotificationManager? // NotificationManager 추가
    private var cameraManager: CameraManager? // CameraManager 추가
    private var mapStyleManager: MapStyleManager? // StyleManager 추가
    private var lastBackgroundTime: Date? // 마지막 백그라운드 전환 시각

    private var isLocationPermissionHandled = false // 권한 처리 여부 확인 변수
    private var isMovieDataLoaded = false // 영화 데이터 로드 여부 추가

    override func viewDidLoad() {
            super.viewDidLoad()
            setupMapView()
            setupLocationManager()
            
            // NotificationManager 초기화
            notificationManager = NotificationManager(
                onScanButtonTapped: { [weak self] in
                    self?.handleScanButtonTapped()
                },
                onClearCacheTapped: { [weak self] in
                    self?.handleClearCacheTapped()
                },
                onAppWillEnterForeground: { [weak self] in
                    self?.handleAppWillEnterForeground()
                },
                onAppDidEnterBackground: { [weak self] in
                    self?.handleAppDidEnterBackground()
                }
            )
            notificationManager?.setupNotifications()
            
            // 스타일 설정 및 카메라 제스처 옵션 설정
            mapStyleManager?.applyDarkStyle {
                print("✅ 스타일 설정 후 카메라 제스처 옵션을 적용합니다.")
                self.cameraManager?.configureGestureOptions() // cameraManager에서 제스처 옵션 설정
            }
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
        
        // ✅ CameraManager와 StyleManager 초기화
        cameraManager = CameraManager(mapView: mapView)
        mapStyleManager = MapStyleManager(mapView: mapView)

        // ✅ MovieController 초기화
        movieController = MovieController(mapView: mapView)

        handleStyleLoadedEvent()

        // ✅ MapView를 뷰에 추가
        view.addSubview(mapView)
    }
    
    // Handle Scan Button Tapped
    @objc private func handleScanButtonTapped() {
        cameraManager?.setZoomLevel(to: 16.0) { [weak self] in
            guard let self = self else { return }
            let centerCoordinate = self.mapView.mapboxMap.cameraState.center

            // 타일 계산
            let visibleTiles = self.tileManager.tilesInRange(center: centerCoordinate)

            print("📍 현재 보이는 타일: \(visibleTiles.count)")
            print("📍 타일 리스트: \(visibleTiles)")

            // Circle 데이터 생성 및 필터링
            let filteredCircles = self.movieService.createFilteredCircleData(
              visibleTiles: visibleTiles,
              tileManager: self.tileManager
            )

            if filteredCircles.isEmpty {
                print("⚠️ 추가 생성된 Circle 데이터가 없습니다.")
            } else {
                // `layerManager`를 통해 호출
                self.movieController?.layerManager.addGenreCircles(
                    data: filteredCircles,
                    userLocation: centerCoordinate,
                    isScan: true
                )
            }
            
            reloadLocationPuck()

            // 작업 완료 후 줌 레벨 복구
            self.cameraManager?.setZoomLevel(to: 15.0) {
              print("✅ Zoom 레벨이 15.0으로 복구되었습니다.")
            }
        }
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
        if timeInBackground > 30 {
            print("🔄 앱이 30초 이상 백그라운드에 있었습니다. 현재 위치로 화면 이동.")
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
        let userLocation = mapView.location.latestLocation?.coordinate
        cameraManager?.moveCameraToCurrentLocation(location: userLocation)
    }
    
    private func configureUserLocationDisplay() {
        // ✅ 사용자 위치 표시 (화살표 포함)
        mapView.location.options.puckType = .puck2D(Puck2DConfiguration.makeDefault(showBearing: true))
        mapView.location.options.puckBearingEnabled = true
        mapView.location.options.puckBearing = .heading
        print("✅ 사용자 위치 표시 설정 완료")
    }

    private var styleLoadedCancelable: AnyCancelable? // Cancelable 객체 저장용 변수
    private func handleStyleLoadedEvent() {
        styleLoadedCancelable = mapView.mapboxMap.onStyleLoaded.observe { [weak self] _ in
            guard let self = self else { return }

            // 사용자 위치 가져오기
            let coordinate = self.mapView.location.latestLocation?.coordinate
                ?? CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 기본 위치: 서울

            // 초기 카메라 설정
            self.cameraManager?.setInitialCamera(to: coordinate)
            print("🛠️ 스타일 로드 완료, 초기 카메라 설정 - \(coordinate.latitude), \(coordinate.longitude)")

            // 원 추가
            self.locationCircleManager.addCircleLayers(to: self.mapView, at: coordinate)

            // 지도에 표시할 타일을 기반으로 필터링된 Circle 데이터를 생성하고 지도에 추가
            if let movieController = self.movieController {
                // 현재 보이는 타일 및 줌 레벨 정보
                let visibleTiles = tileManager.tilesInRange(center: coordinate) // 줌 레벨은 적절히 설정
                let filteredCircleData = movieService.createFilteredCircleData(visibleTiles: visibleTiles,  tileManager: tileManager)

                // 필터링된 Circle 데이터를 지도에 추가
                movieController.layerManager.addGenreCircles(data: filteredCircleData, userLocation: coordinate)
            } else {
                print("⚠️ MovieController가 초기화되지 않았습니다.")
            }

            // 스타일 및 불필요한 레이어 제거
            self.mapStyleManager?.applyDarkStyle()
            reloadLocationPuck()
        }
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
    
    // MARK: - 사용자 위치 업데이트
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
               locationManager.startUpdatingLocation()
           case .denied, .restricted:
               print("❌ 위치 권한 거부됨.")
               moveCameraToCurrentLocation()
           case .notDetermined:
               print("❓ 위치 권한 결정되지 않음.")
           @unknown default:
               print("⚠️ 알 수 없는 위치 권한 상태.")
           }
       }
       
       func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
           guard let userLocation = locations.last else { return }
           
           if let lastLocation = lastUpdatedLocation {
               let distance = userLocation.distance(from: lastLocation)
               print("📏 이동 거리: \(String(format: "%.2f", distance))m")
               
               if distance < minimumDistanceThreshold {
                   print("⚠️ 위치 변화가 미미함, 업데이트 생략")
                   return
               }
           }
           
           locationCircleManager.updateCircleLayers(for: mapView, at: userLocation.coordinate)
           lastUpdatedLocation = userLocation
           print("📍 사용자 위치 업데이트됨 - 원만 업데이트됨, 화면 유지")
       }
}
