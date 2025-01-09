//
//  ContentView.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import SwiftUI

struct ContentView: View {
    let movieService = MovieService() // MovieService 인스턴스 생성

    var body: some View {
        ZStack {
            // 지도 뷰 추가
            MapboxMapView()
                .edgesIgnoringSafeArea(.all)

            // Clear Cache 버튼
            VStack {
                Spacer() // 상단 공간 확보
                Button(action: {
                    movieService.clearCache()
                }) {
                    Text("Clear Cache")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}
