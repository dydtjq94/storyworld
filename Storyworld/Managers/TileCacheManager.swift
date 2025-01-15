//
//  TileCacheManager.swift
//  Storyworld
//
//  Created by peter on 1/13/25.
//

import Foundation

/// 타일 데이터 구조체
struct TileInfo: Codable {
    let layerData: [MovieService.CircleData] // 해당 타일의 Movie-Circle 데이터
    var isVisible: Bool // 타일이 현재 표시되고 있는지 여부
}

final class TileCacheManager {
    private let storageKey = "tileDataCache"
    private let lastResetKey = "lastCacheResetTime"
    private let resetInterval: TimeInterval = 6 * 60 * 60 // 6시간
    private var timer: Timer?

    init() {
        checkCacheResetSchedule()
    }

    /// 타일 데이터 저장
    func saveTileData(_ tileData: [String: TileManager.TileInfo]) {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(tileData)
            UserDefaults.standard.set(encoded, forKey: storageKey)
            print("💾 타일 데이터 저장 완료")
        } catch {
            print("❌ 타일 데이터 저장 실패: \(error.localizedDescription)")
        }
    }

    /// 타일 데이터 로드
    func loadTileData() -> [String: TileManager.TileInfo] {
        let decoder = JSONDecoder()
        guard let savedData = UserDefaults.standard.data(forKey: storageKey) else {
            print("📂 저장된 타일 데이터가 없음")
            return [:]
        }
        do {
            let decoded = try decoder.decode([String: TileManager.TileInfo].self, from: savedData)
            print("📂 타일 데이터 로드 완료")
            return decoded
        } catch {
            print("❌ 타일 데이터 로드 실패: \(error.localizedDescription)")
            return [:]
        }
    }

    /// 캐시 초기화
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.set(Date(), forKey: lastResetKey)
        print("🗑️ 타일 데이터 캐시 초기화 완료")
    }

    /// 캐시 초기화 상태 확인 및 스케줄 설정
    private func checkCacheResetSchedule() {
        let currentTime = Date()
        let lastResetTime = UserDefaults.standard.object(forKey: lastResetKey) as? Date ?? .distantPast
        let elapsedTime = currentTime.timeIntervalSince(lastResetTime)

        if elapsedTime >= resetInterval {
            // 6시간이 이미 경과한 경우 바로 초기화
            clearCache()
            scheduleNextCacheReset(after: resetInterval)
        } else {
            // 6시간이 경과하지 않은 경우 남은 시간 계산
            let remainingTime = resetInterval - elapsedTime
            scheduleNextCacheReset(after: remainingTime)
        }
    }

    /// 다음 캐시 초기화 스케줄 설정
    private func scheduleNextCacheReset(after seconds: TimeInterval) {
        timer?.invalidate() // 기존 타이머 해제
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.clearCache()
            self?.scheduleNextCacheReset(after: self?.resetInterval ?? 0)
        }
        print("⏰ 캐시 초기화 스케줄 설정: \(seconds)초 후")
    }
}
