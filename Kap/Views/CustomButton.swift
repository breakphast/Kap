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
    @State var betSelected = false
    @Environment(\.dismiss) var dismiss
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation {
                print("Tapped button: ", bet.id)
                
                self.action()
                self.betSelected.toggle()
            }
        }) {
            ZStack {
                betSelected ? Color.onyxLight : .yellow
                Text(buttonText)
                    .font(.caption2.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(betSelected ? .yellow : Color.onyx)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(height: 40)
        .cornerRadius(10)
        .shadow(radius: 10)
        .onChange(of: viewModel.selectedBets.count, { oldValue, newValue in
            betSelected = viewModel.selectedBets.contains(where: { $0.id == bet.id })
        })
    }
}
