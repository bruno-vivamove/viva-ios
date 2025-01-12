//
//  VivaDesign.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

enum VivaDesign {
    enum Colors {
        static let vivaGreen = Color(red: 4/255, green: 255/255, blue: 191/255)
        static let background = Color.black
        static let primaryText = Color.white
        static let secondaryText = Color.gray
        static let divider = Color.white.opacity(0.6)
    }
    
    enum Spacing {
        static let large: CGFloat = 32
        static let medium: CGFloat = 20
        static let small: CGFloat = 12
        static let minimal: CGFloat = 8
    }
    
    enum Sizing {
        static let cornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 1
        static let buttonCornerRadius: CGFloat = 10
        static let buttonBorderWidth: CGFloat = 2
        
        enum ProfileImage {
            static let large: CGFloat = 80
            static let medium: CGFloat = 60
            static let small: CGFloat = 40
        }
    }
    
    enum Typography {
        static func displayText(_ size: CGFloat = 70) -> Font {
            .system(size: size, weight: .bold)
        }
        
        static let title = Font.system(size: 60, weight: .bold)
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let body = Font.body
        static let subheadline = Font.subheadline
        static let caption = Font.caption
    }
}
