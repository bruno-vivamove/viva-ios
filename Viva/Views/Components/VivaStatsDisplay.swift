//
//  VivaStatsDisplay.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

struct VivaStatsDisplay: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: VivaDesign.Spacing.xsmall) {
            Text(value)
                .font(VivaDesign.Typography.title3)
                .foregroundColor(VivaDesign.Colors.primaryText)
            Text(label)
                .font(VivaDesign.Typography.caption)
                .foregroundColor(VivaDesign.Colors.vivaGreen)
        }
    }
}
