//
//  VivaCard.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

// Base Card View
struct VivaCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(VivaDesign.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: VivaDesign.Sizing.cornerRadius)
                    .fill(VivaDesign.Colors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: VivaDesign.Sizing.cornerRadius)
                            .stroke(VivaDesign.Colors.divider, lineWidth: VivaDesign.Sizing.borderWidth)
                    )
            )
    }
}
