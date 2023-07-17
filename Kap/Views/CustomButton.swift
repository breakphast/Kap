//
//  CustomButton.swift
//  Kap
//
//  Created by Desmond Fitch on 7/15/23.
//

import SwiftUI

struct CustomButton: View {
    var betOption: BetOption
    var buttonText: String
    @Environment(\.viewModel) private var viewModel
    @State var confirmBet = false
    @Binding var parlayMode: Bool
    @Environment(\.dismiss) var dismiss
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation {
                
                if parlayMode {
                    self.action()
                }
                
                if confirmBet {
                    self.action()
                    self.confirmBet.toggle()
                    viewModel.activeButtons.removeAll(where: { $0.uuidString == betOption.id.uuidString })
                    
                } else {
                    self.confirmBet.toggle()
                    viewModel.activeButtons.append(betOption.id)
                }
            }
        }) {
            ZStack {
                confirmBet ? Color("onyxLight") : Color.yellow
                if confirmBet {
                    Text(buttonText)
                        .font(.caption2.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.yellow)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                } else {
                    Text(buttonText)
                        .font(.caption2.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(Color("onyx"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .frame(height: 40)
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}
