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
//    @Environment(\.viewModel) private var viewModel
    @EnvironmentObject var homeViewModel: AppDataViewModel
    @Environment(\.dismiss) var dismiss
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation {
                self.action()
            }
        }) {
            ZStack {
                homeViewModel.selectedBets.contains(where: { $0.id == bet.id }) ? Color.lion : Color.oW
                Text(buttonText)
                    .font(.caption2.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(homeViewModel.selectedBets.contains(where: { $0.id == bet.id }) ? .oW : .onyx)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(height: 44)
        .cornerRadius(10)
    }
}
