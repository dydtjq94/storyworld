//
//  ProSubscribeViewController.swift
//  Storyworld
//
//  Created by peter on 1/10/25.
//

import UIKit

final class ProSubscribeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = .white
        
        let label = UILabel()
        label.text = "PRO 구독으로 이 작품을 수집하세요!"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false

        let subscribeButton = UIButton(type: .system)
        subscribeButton.setTitle("구독하기", for: .normal)
        subscribeButton.addTarget(self, action: #selector(handleSubscribe), for: .touchUpInside)
        subscribeButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        view.addSubview(subscribeButton)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            subscribeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subscribeButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20)
        ])
    }

    @objc private func handleSubscribe() {
        // App Store 구독 화면으로 이동
        print("🔔 PRO 구독 화면으로 이동")
    }
}
