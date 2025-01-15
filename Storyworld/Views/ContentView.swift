//
//  ContentView.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // MapboxMapView 추가
                MapboxMapView()
                    .edgesIgnoringSafeArea(.all)

                // 버튼 그룹
                VStack {
                    Spacer() // 상단 공간 확보
                    
                    HStack {
                        // Clear Cache 버튼
                        Button(action: {
                            NotificationCenter.default.post(name: .clearCacheTapped, object: nil)
                        }) {
                            Text("Clear")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        // Collection 이동 버튼
                        NavigationLink(destination: CollectionViewWrapper()) {
                            Text("Collection")
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        // Scan 버튼
                        Button(action: {
                            NotificationCenter.default.post(name: .scanButtonTapped, object: nil)
                        }) {
                            Text("Scan")
                                .padding()
                                .background(Color.green.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// UIKit CollectionViewController를 SwiftUI로 Wrapping
struct CollectionViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CollectionViewController {
        return CollectionViewController()
    }

    func updateUIViewController(_ uiViewController: CollectionViewController, context: Context) {}
}

// Notification 이름 확장
extension Notification.Name {
    static let scanButtonTapped = Notification.Name("scanButtonTapped")
    static let clearCacheTapped = Notification.Name("clearCacheTapped")
}
