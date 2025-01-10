//
//  DropController.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import UIKit
import MapboxMaps

final class DropController: UIViewController {
    private let dropView = DropView()
    private let genre: MovieGenre
    private let selectedGenreId: Int // 고정된 장르 ID 추가
    private let rarity: String
    private let tmdbService: TMDbService
    private var movies: [TMDbNamespace.TMDbMovieModel] = []

    init(genre: MovieGenre, selectedGenreId: Int, rarity: String, tmdbService: TMDbService) {
        self.genre = genre
        self.selectedGenreId = selectedGenreId
        self.rarity = rarity
        self.tmdbService = tmdbService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    
        // Open 버튼 동작 추가
        dropView.openButton.addTarget(self, action: #selector(handleDrop), for: .touchUpInside)
    }

    private func setupView() {
        view.backgroundColor = .black
        dropView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dropView)

        // 아래 화살표 버튼 추가
        let dismissButton = UIButton(type: .system)
        dismissButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        dismissButton.tintColor = .white
        dismissButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            dropView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dropView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dropView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            dropView.heightAnchor.constraint(equalToConstant: 400),

            // 화살표 버튼 위치
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dismissButton.widthAnchor.constraint(equalToConstant: 30),
            dismissButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        // DropView에 데이터 업데이트
        dropView.updateView(genre: genre.rawValue, rarity: rarity)
    }

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleDrop() {
        // 최대 페이지 가져오기
        tmdbService.fetchMoviesByGenres(genreIds: [selectedGenreId], page: 1) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success((_, let totalPages)):
                guard totalPages > 0 else {
                    print("⚠️ 총 페이지 수가 0입니다.")
                    return
                }

                let validPageRange = min(totalPages, 500) // 최대 500페이지 제한
                let randomPage = Int.random(in: 1...validPageRange)
                print("🎥 Fetching movies for random page: \(randomPage) of \(validPageRange) (Genre ID: \(self.selectedGenreId)).")

                // 🎬 영화 데이터 가져오기
                self.fetchMovies(page: randomPage) {
                    guard !self.movies.isEmpty else {
                        print("⚠️ 영화 데이터가 비어있습니다.")
                        return
                    }

                    // 🎲 랜덤으로 영화 선택
                    guard let randomMovieModel = self.movies.randomElement() else {
                        print("⚠️ 영화 데이터를 랜덤 선택하는 데 실패했습니다.")
                        return
                    }

                    // DropView에 영화 데이터 업데이트
                    self.dropView.updateWithMovie(randomMovieModel)

                    // 사용자 컬렉션에 영화 저장
                    var currentMovies = UserDefaults.standard.loadMovies() ?? []
                    let movieToSave = randomMovieModel.toMovie()
                    if !currentMovies.contains(where: { $0.id == movieToSave.id }) {
                        currentMovies.append(movieToSave)
                        UserDefaults.standard.saveMovies(currentMovies)
                        print("✅ 영화가 컬렉션에 저장되었습니다: \(movieToSave.title)")
                    } else {
                        print("⚠️ 이미 컬렉션에 존재하는 영화입니다: \(movieToSave.title)")
                    }

                    print("🎬 Drop 완료: \(randomMovieModel.title), \(randomMovieModel.id)")
                }

            case .failure(let error):
                print("❌ 최대 페이지 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }

    private func fetchMovies(page: Int, completion: @escaping () -> Void) {
        tmdbService.fetchMoviesByGenres(genreIds: [selectedGenreId], page: page) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let (movies, _)):
                DispatchQueue.main.async {
                    self.movies = movies
                    print("✅ Movies fetched: \(movies.map { $0.title })")
                    completion()
                }
            case .failure(let error):
                print("❌ 영화 데이터 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }

    
}
