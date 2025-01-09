//
//  MovieService.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import Foundation
import CoreLocation

final class MovieService {
    
    /// 🎬 더미 영화 데이터 생성
    func getDummyMovies(around coordinate: CLLocationCoordinate2D) -> [Movie] {
        return [
            Movie(title: "Action Movie", genre: .action, location: randomCoordinate(around: coordinate)),
            Movie(title: "Drama Movie", genre: .drama, location: randomCoordinate(around: coordinate)),
            Movie(title: "Sci-Fi Movie", genre: .sciFi, location: randomCoordinate(around: coordinate)),
            Movie(title: "Romance Movie", genre: .romance, location: randomCoordinate(around: coordinate)),
            Movie(title: "Horror Movie", genre: .horror, location: randomCoordinate(around: coordinate)),
            Movie(title: "Comedy Movie", genre: .comedy, location: randomCoordinate(around: coordinate)),
            Movie(title: "Western Movie", genre: .western, location: randomCoordinate(around: coordinate)),
            Movie(title: "Family Movie", genre: .family, location: randomCoordinate(around: coordinate))
        ]
    }
    
    /// 📍 랜덤 좌표 생성 (사용자 주변 반경)
    private func randomCoordinate(around center: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat = center.latitude + Double.random(in: -0.001...0.001)
        let lon = center.longitude + Double.random(in: -0.001...0.001)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

