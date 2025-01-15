//
//  Rank.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import Foundation
import UIKit

enum Rarity: String, Codable, CaseIterable  {
    case common = "Common"        // 일반
    case uncommon = "Uncommon"    // 희귀
    case rare = "Rare"            // 희귀한
    case epic = "Epic"            // 매우 희귀

    /// 등급에 따른 설명 반환
    var description: String {
        switch self {
        case .common:
            return "Common rarity level. Frequently encountered."
        case .uncommon:
            return "Uncommon rarity level. Less frequent but not rare."
        case .rare:
            return "Rare rarity level. Special and hard to find."
        case .epic:
            return "Epic rarity level. Extremely unique and valuable."
        }
    }

    /// 등급에 따른 색상 반환 (추후 UI에서 사용 가능)
    var colorHex: String {
        switch self {
        case .common:
            return "#A0A0A0" // 회색
        case .uncommon:
            return "#00FF00" // 초록색
        case .rare:
            return "#0000FF" // 파란색
        case .epic:
            return "#FFD700" // 금색
        }
    }
    
    var uiColor: UIColor {
        return UIColor(hex: colorHex)
    }

    /// 확률 값 추가
    var probability: Double {
        switch self {
        case .common:
            return 0.6
        case .uncommon:
            return 0.3
        case .rare:
            return 0.099
        case .epic:
            return 0.001
        }
    }
}
