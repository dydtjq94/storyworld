//
//  UIColor+Expression.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import UIKit
import MapboxMaps

extension UIColor {
    var expressionArgument: MapboxMaps.Exp.Argument {
        return .string(StyleColor(self).rawValue)
    }
}

extension StyleColor {
    static let red = StyleColor(UIColor.red)
    static let yellow = StyleColor(UIColor.yellow)
    static let black = StyleColor(UIColor.black)
    static let brown = StyleColor(UIColor.brown)
    static let orange = StyleColor(UIColor.orange)
    static let cyan = StyleColor(UIColor.cyan)
    static let systemPink = StyleColor(UIColor.systemPink)
    static let green = StyleColor(UIColor.green)
    static let gray = StyleColor(UIColor.gray)
}
