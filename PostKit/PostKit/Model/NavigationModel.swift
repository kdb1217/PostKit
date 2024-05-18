//
//  NavigationModel.swift
//  PostKit
//
//  Created by 김다빈 on 10/11/23.
//

import Foundation


public enum StackViewType {
    case Restaurant
    case Cafe
    case NailSalon
    case BrowShop
    case Hair
    case Gym
    case Fashion
    case Cosmetics
    case Flower
    case Studio
    case SettingHome
    case SettingStore
    case SettingTone
    case SettingCS
    case Loading
    case CaptionResult
    case HashtagResult
    case ErrorNetwork
    case ErrorResultFailed
    case Hashtag
}

class PathManager: ObservableObject {
    @Published var path: [StackViewType] = []
}
