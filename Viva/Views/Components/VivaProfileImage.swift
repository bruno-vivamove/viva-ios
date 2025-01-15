//
//  VivaProfileImage.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

struct VivaProfileImage: View {
    let imageURL: String
    let size: VivaDesign.Sizing.ProfileImage
    
    var body: some View {
        Image(imageURL)
            .resizable()
            .frame(width: size.rawValue, height: size.rawValue)
            .clipShape(Circle())
    }
}
