//
//  CustomButton.swift
//  Kap
//
//  Created by Desmond Fitch on 7/15/23.
//

import SwiftUI

struct CustomButton: View {
    var bet: Bet
    var buttonText: String
    @Environment(\.viewModel) private var viewModel
    @Environment(\.dismiss) var dismiss
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation {
                self.action()
            }
        }) {
            ZStack {
                viewModel.selectedBets.contains(where: { $0.id == bet.id }) ? Color.onyxLightish : Color.lion
                Text(buttonText)
                    .font(.caption2.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(viewModel.selectedBets.contains(where: { $0.id == bet.id }) ? .lion : .onyx)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(height: 44)
        .cornerRadius(10)
        .shadow(color: .onyxLightish, radius: 10)
    }
}
