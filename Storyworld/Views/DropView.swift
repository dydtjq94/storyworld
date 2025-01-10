//
//  DropView.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import UIKit

final class DropView: UIView {
    public let openButton = UIButton(type: .system)
    private let dropImageView = UIImageView()
    private let titleLabel = UILabel()
    private let tagsStackView = UIStackView()
    
    private var genre: MovieGenre?
    private var rarity: Rarity?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.backgroundColor = .black
        self.layer.cornerRadius = 20
        self.clipsToBounds = true

        // Drop Image View
        dropImageView.contentMode = .scaleAspectFit
        dropImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dropImageView)

        // Title Label
        titleLabel.text = "What’s in this drop?"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Tags StackView
        tagsStackView.axis = .horizontal
        tagsStackView.distribution = .equalSpacing
        tagsStackView.spacing = 8
        tagsStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tagsStackView)

        // Open Button
        openButton.setTitle("Open drop", for: .normal)
        openButton.setTitleColor(.black, for: .normal)
        openButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        openButton.backgroundColor = .systemGreen
        openButton.layer.cornerRadius = 10
        openButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(openButton)

        // Constraints
        NSLayoutConstraint.activate([
            dropImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            dropImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            dropImageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.6),
            dropImageView.heightAnchor.constraint(equalTo: dropImageView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: dropImageView.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            tagsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tagsStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            openButton.topAnchor.constraint(equalTo: tagsStackView.bottomAnchor, constant: 20),
            openButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            openButton.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8),
            openButton.heightAnchor.constraint(equalToConstant: 50),
            openButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20)
        ])
    }

    private func createTagLabel(text: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.backgroundColor = color
        label.layer.cornerRadius = 5
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 24).isActive = true
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        return label
    }

    func updateView(genre: String, rarity: String) {
        // 태그 업데이트
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() } // 기존 태그 제거
        
        // 장르별 색상 찾기
        let genreColor: UIColor
        if let movieGenre = MovieGenre(rawValue: genre) {
            genreColor = movieGenre.uiColor
        } else {
            genreColor = .gray // 기본값
        }
        
        // 희귀도별 색상 찾기
        let rarityColor: UIColor
        if let rarityEnum = Rarity(rawValue: rarity) {
            rarityColor = rarityEnum.uiColor
        } else {
            rarityColor = .gray // 기본값
        }
        
        // 장르 및 희귀도 태그 추가
        let genreTag = createTagLabel(text: genre, color: genreColor)
        let rarityTag = createTagLabel(text: rarity, color: rarityColor)
        tagsStackView.addArrangedSubview(genreTag)
        tagsStackView.addArrangedSubview(rarityTag)

        // 기본 이미지 설정 (추후 업데이트 가능)
        dropImageView.image = UIImage(named: "default-drop-image")
    }
    
    func updateWithMovie(_ movie: TMDbNamespace.TMDbMovieModel) {
        // 영화 제목 설정
        titleLabel.text = movie.title
        
        // 이전 Drop 정보를 저장 (장르와 rarity)
        if let currentGenre = genre, let currentRarity = rarity {
            // 이전 Drop 정보를 유지하고 태그 스택 뷰 초기화
            tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            // 장르 태그 추가
            let genreTag = createTagLabel(text: currentGenre.rawValue, color: currentGenre.uiColor)
            tagsStackView.addArrangedSubview(genreTag)
            
            // 희귀도 태그 추가
            let rarityTag = createTagLabel(text: currentRarity.rawValue, color: UIColor.gray) // 희귀도는 회색으로 표시
            tagsStackView.addArrangedSubview(rarityTag)
        }

 
        // 영화 포스터 이미지 설정
        if let posterPath = movie.posterPath {
            let posterURL = "https://image.tmdb.org/t/p/w500\(posterPath)"
            // 간단한 이미지 로드 (비동기 작업)
            if let url = URL(string: posterURL) {
                // 비동기 URLSession 요청
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        // 메인 스레드에서 UI 업데이트
                        DispatchQueue.main.async {
                            self.dropImageView.image = image
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.dropImageView.image = UIImage(named: "default-drop-image")
                        }
                    }
                }.resume()
            } else {
                dropImageView.image = UIImage(named: "default-drop-image")
            }
        } else {
            dropImageView.image = UIImage(named: "default-drop-image")
        }

        // "Open drop" 버튼 비활성화
        openButton.setTitle("Dropped!", for: .normal)
        openButton.isEnabled = false
        openButton.backgroundColor = .gray
    }
}
