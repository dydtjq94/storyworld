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
    }
    
    /// 🎬 영화 데이터를 불러와 지도에 표시
    func loadMovies(around coordinate: CLLocationCoordinate2D) {
        // 영화 데이터를 생성
        let movies = movieService.getDummyMovies(around: coordinate)

        // ✅ 디버깅 로그
        print("🎥 영화 데이터 로드 확인: \(movies.count)개의 영화가 로드되었습니다.")
        for movie in movies {
            print("🎬 영화 제목: \(movie.title), 위치: \(movie.location.latitude), \(movie.location.longitude)")
        }

        // 기존 레이어 및 소스가 있다면 제거
        removeExistingMovieLayers()

        // 영화 데이터를 지도에 추가
        addMoviesToMap(movies: movies)
    }
    
    /// 기존 영화 관련 레이어 및 소스 제거
    private func removeExistingMovieLayers() {
        let sourceId = "movies-source"
        let layerId = "movies-layer"

        if mapView.mapboxMap.style.sourceExists(withId: sourceId) {
            try? mapView.mapboxMap.style.removeSource(withId: sourceId)
            print("✅ 기존 영화 소스 제거됨")
        }

        if mapView.mapboxMap.style.layerExists(withId: layerId) {
            try? mapView.mapboxMap.style.removeLayer(withId: layerId)
            print("✅ 기존 영화 레이어 제거됨")
        }
    }
    
    /// 🗺️ 영화 데이터를 지도에 추가
    private func addMoviesToMap(movies: [Movie]) {
        do {
            var geoJSONFeatures: [Feature] = []
            
            for movie in movies {
                var feature = Feature(geometry: .point(Point(movie.location)))
                feature.properties = [
                    "title": .string(movie.title),
                    "genre": .string(movie.genre.rawValue)
                ]
                geoJSONFeatures.append(feature)
            }
            
            let moviesourceId = "movies-source"
            var geoJSONSource = GeoJSONSource(id: moviesourceId)
            geoJSONSource.data = .featureCollection(FeatureCollection(features: geoJSONFeatures))
            
            // Source 추가
            if !mapView.mapboxMap.style.sourceExists(withId: moviesourceId) {
                try? mapView.mapboxMap.style.addSource(geoJSONSource)
                print("✅ 영화 소스가 성공적으로 추가되었습니다.")
            }
            
            // ✅ CircleLayer 추가
            let layerId = "movies-layer"
            if !mapView.mapboxMap.style.layerExists(withId: layerId) {
                var circleLayer = CircleLayer(id: layerId, source: moviesourceId)
                circleLayer.circleRadius = .constant(10.0) // 반지름을 적절히 줄임
                circleLayer.circleColor = .constant(StyleColor(UIColor.red)) // 빨간색으로 설정
                circleLayer.circleOpacity = .constant(1.0) // 불투명도 100%
                circleLayer.circleStrokeColor = .constant(StyleColor(UIColor.white))
                circleLayer.circleStrokeWidth = .constant(2.0)
                
                // Layer 추가
                try mapView.mapboxMap.style.addLayer(circleLayer)
                print("✅ 초기 영화 위치 추가됨")
            } 

            print("✅ 영화 데이터가 지도에 성공적으로 추가되었습니다.")
            
        } catch {
            print("❌ 영화 데이터 추가 실패: \(error.localizedDescription)")
        }
        
        // 현재 소스 및 레이어 목록 확인
        let sources = mapView.mapboxMap.style.allSourceIdentifiers

        let layers = mapView.mapboxMap.style.allLayerIdentifiers
    }
}
