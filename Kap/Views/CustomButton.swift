//
//  CustomButton.swift
//  Kap
//
//  Created by Desmond Fitch on 7/15/23.
//

import SwiftUI

struct CustomButton: View {
    var betOption: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Color.yellow
                Text(betOption)
                    .font(.caption2.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(height: 40)
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}
