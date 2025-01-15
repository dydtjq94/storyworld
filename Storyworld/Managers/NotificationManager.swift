//
//  NotificationManager.swift
//  Storyworld
//
//  Created by peter on 1/15/25.
//

import UIKit

final class NotificationManager: NSObject {
    // MARK: - Properties
    private var handleScanButton: (() -> Void)?
    private var handleClearCache: (() -> Void)?
    private var handleAppForeground: (() -> Void)?
    private var handleAppBackground: (() -> Void)?

    // MARK: - Initializer
    init(
        onScanButtonTapped: @escaping () -> Void,
        onClearCacheTapped: @escaping () -> Void,
        onAppWillEnterForeground: @escaping () -> Void,
        onAppDidEnterBackground: @escaping () -> Void
    ) {
        self.handleScanButton = onScanButtonTapped
        self.handleClearCache = onClearCacheTapped
        self.handleAppForeground = onAppWillEnterForeground
        self.handleAppBackground = onAppDidEnterBackground
    }

    // MARK: - Setup Notifications
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScanButtonTapped),
            name: .scanButtonTapped,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClearCacheTapped),
            name: .clearCacheTapped,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    // MARK: - Notification Handlers
    @objc private func handleScanButtonTapped() {
        print("🔄 Scan 버튼이 눌렸습니다.")
        handleScanButton?()
    }

    @objc private func handleClearCacheTapped() {
        print("🗑️ 캐시 삭제 버튼이 눌렸습니다.")
        handleClearCache?()
    }

    @objc private func handleAppWillEnterForeground() {
        print("🔄 앱이 포그라운드로 돌아왔습니다.")
        handleAppForeground?()
    }

    @objc private func handleAppDidEnterBackground() {
        print("🔄 앱이 백그라운드로 전환되었습니다.")
        handleAppBackground?()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
