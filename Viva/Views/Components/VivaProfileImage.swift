//
//  VivaProfileImage.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

struct VivaProfileImage: View {
    let imageId: String
    let size: VivaDesign.Sizing.ProfileImage
    
    var body: some View {
        Image(imageId)
            .resizable()
            .frame(width: size.rawValue, height: size.rawValue)
            .clipShape(Circle())
    }
}
