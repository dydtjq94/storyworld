//
//  DropController.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import UIKit

final class DropController: UIViewController {
    private let dropView = DropView()
    private let genre: String
    private let rarity: String

    init(genre: String, rarity: String) {
        self.genre = genre
        self.rarity = rarity
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
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
        dropView.updateView(genre: genre, rarity: rarity)
    }

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}
