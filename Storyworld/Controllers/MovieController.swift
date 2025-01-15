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
    let layerManager: MovieLayerMapManager
    private var gestureManager: GestureManager!
    private var selectedMovie: Movie?
    private let uiManager: MovieUIManager

    init(mapView: MapView, movie: Movie? = nil) {
       self.mapView = mapView
       self.selectedMovie = movie
       self.layerManager = MovieLayerMapManager(mapView: mapView)
       self.uiManager = MovieUIManager(mapView: mapView)
       self.gestureManager = GestureManager(
           mapView: mapView,
           onFeatureSelected: { [weak self] feature in
               self?.handleFeatureSelection(feature)
           }
       )
    }
    
    func updateUIWithMovieData() {
        guard let movie = selectedMovie else { return }
        uiManager.displayMovieDetails(movie: movie)
    }
    
    // Feature 선택 처리
    private func handleFeatureSelection(_ feature: Feature) {
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

        guard let userLocation = mapView.location.latestLocation?.coordinate else {
            print("⚠️ 사용자 위치를 가져올 수 없습니다.")
            return
        }

        let circleLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let userLocationCL = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distance = userLocationCL.distance(from: circleLocation)

        if distance <= Constants.Numbers.smallCircleRadius {
            handleDropWithin50m(movieGenre: movieGenre, rarity: rarity, selectedGenreId: selectedGenreId)
        } else if distance <= Constants.Numbers.largeCircleRadius {
            uiManager.showProSubscriptionMessage()
        } else {
            uiManager.showAdMessage()
        }
    }

    private func handleDropWithin50m(movieGenre: MovieGenre, rarity: String, selectedGenreId: Int) {
        print("🎯 클릭된 Circle - Genre: \(movieGenre.rawValue), Rarity: \(rarity)")
        print("🎬 정해진 장르 ID: \(selectedGenreId)")

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String else {
            print("❌ TMDB API Key를 가져올 수 없습니다.")
            return
        }

        let tmdbService = TMDbService(apiKey: apiKey)
        uiManager.presentDropController(genre: movieGenre, selectedGenreId: selectedGenreId, rarity: rarity, tmdbService: tmdbService)
    }
}
