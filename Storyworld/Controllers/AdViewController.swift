//
//  AdViewController.swift
//  Storyworld
//
//  Created by peter on 1/10/25.
//

import UIKit

final class AdViewController: UIViewController {
    var movie: Movie? // 영화 정보 전달

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = .white

        let label = UILabel()
        label.text = "광고를 보고 이 작품을 수집하세요!"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false

        let genreLabel = UILabel()
        genreLabel.text = "장르: \(movie?.genre.rawValue ?? "알 수 없음")"
        genreLabel.textAlignment = .center
        genreLabel.translatesAutoresizingMaskIntoConstraints = false

        let rarityLabel = UILabel()
        rarityLabel.text = "희귀도: \(movie?.rarity.rawValue ?? "알 수 없음")"
        rarityLabel.textAlignment = .center
        rarityLabel.translatesAutoresizingMaskIntoConstraints = false

        let adButton = UIButton(type: .system)
        adButton.setTitle("광고 보기", for: .normal)
        adButton.addTarget(self, action: #selector(handleAd), for: .touchUpInside)
        adButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        view.addSubview(genreLabel)
        view.addSubview(rarityLabel)
        view.addSubview(adButton)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            genreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            genreLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            rarityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rarityLabel.topAnchor.constraint(equalTo: genreLabel.bottomAnchor, constant: 20),
            adButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            adButton.topAnchor.constraint(equalTo: rarityLabel.bottomAnchor, constant: 40)
        ])
    }

    @objc private func handleAd() {
        print("🔔 광고 재생 후 Drop 가능")
        dismiss(animated: true)
    }
}
