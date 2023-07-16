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
    var action: () -> Void
    @State var confirmBet = false
    
    var body: some View {
        Button(action: {
            withAnimation {
                if confirmBet {
                    self.action()
                    self.confirmBet.toggle()
                } else {
                    self.confirmBet.toggle()
                }
            }
        }) {
            ZStack {
                confirmBet ? Color("onyxLight") : Color.yellow
                if confirmBet {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.yellow)
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
