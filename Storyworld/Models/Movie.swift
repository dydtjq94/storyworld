//
//  Movie.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import CoreLocation

enum MovieGenre: String {
    case drama = "Drama"
    case comedy = "Comedy"
    case horror = "Horror"
    case western = "Western"
    case action = "Action"
    case sciFi = "Sci-Fi"
    case romance = "Romance"
    case family = "Family"
}

struct Movie {
    let title: String
    let genre: MovieGenre
    let location: CLLocationCoordinate2D
}
