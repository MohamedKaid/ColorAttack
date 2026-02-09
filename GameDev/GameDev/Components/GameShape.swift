//
//  GameShape.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/2/26.
//

enum GameShape: String, CaseIterable, Identifiable, Equatable {

    case circle
    case square
    case triangle
    case star
   // case diamond
   // case hexagon
    case heart
    case bolt

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .circle:
            return "circle.fill"
        case .square:
            return "square.fill"
        case .triangle:
            return "triangle.fill"
        case .star:
            return "star.fill"
//        case .diamond:
//            return "diamond.fill"
//        case .hexagon:
//            return "hexagon.fill"
        case .heart:
            return "heart.fill"
        case .bolt:
            return "bolt.fill"
        }
    }
}
