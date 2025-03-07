//
//  VivaDivider.swift
//  Viva
//
//  Created by Bruno Souto on 1/12/25.
//

import SwiftUI

struct VivaDivider: View {
    var body: some View {
        Rectangle()
            .fill(VivaDesign.Colors.divider.opacity(0.5))
            .frame(height: 1.5)
    }
}
