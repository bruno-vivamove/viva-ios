//
//  VivaSecondaryButton.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

struct VivaSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(VivaDesign.Typography.body.bold())
                .foregroundColor(VivaDesign.Colors.primaryText)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: VivaDesign.Sizing.buttonCornerRadius)
                        .stroke(VivaDesign.Colors.vivaGreen, lineWidth: VivaDesign.Sizing.buttonBorderWidth)
                )
        }
    }
}
