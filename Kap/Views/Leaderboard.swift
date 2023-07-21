//
//  ContentView.swift
//  kappers
//
//  Created by Desmond Fitch on 6/23/23.
//

import SwiftUI

struct Leaderboard: View {
    @Environment(\.viewModel) private var viewModel
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    var body: some View {
        ZStack(alignment: .top) {
            Color("onyx").ignoresSafeArea()
            Text("Leaderboard")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(viewModel.players.enumerated()), id: \.1.id) { index, player in
                        VStack(alignment: .leading) {
                            HStack {
                                Text("\(index + 1)")
                                    .frame(width: 24)
                                    .font(.title3.bold())
                                
                                ZStack(alignment: .leading) {
                                    if index == Int.random(in: 0 ..< viewModel.players.count) || index == 0 {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.clear)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .padding()
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(index == 0 ? Color("leader") : player.points[0] ?? 0 >= 0 ? Color.bean : Color.red, lineWidth: 3)
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 20).fill(Color("onyx").opacity(0.5))
                                    }
                                    
                                    HStack {
                                        Image("avatar\(index)")
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(Circle())
                                            .frame(width: 40)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(player.name)
                                                .fontWeight(.bold)
                                            HStack(spacing: 4) {
                                                Text("Total points: \((player.points[0] ?? 0) + 183)")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.secondary)
                                                Text("\(player.points[0] ?? 0 > 0 ? "+" : "")\(player.points[0] ?? 0)")
                                                    .font(.caption2)
                                                    .foregroundStyle(player.points[0]! < 0 ? .red : .bean)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: index == 0 ? "minus" : player.points[0]! >= 0 ? "chevron.up.circle" : "chevron.down.circle")
                                            .font(.title2.bold())
                                            .foregroundStyle(index == 0 ? .secondary : player.points[0]! >= 0 ? Color.bean : Color.red)
                                    }
                                    .padding(.horizontal)
                                    .padding(.trailing, index == 0 ? 1 : 0)
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
            }
            .padding(.top, 40)
        }
        .fontDesign(.rounded)
    }
}

#Preview {
    Leaderboard()
}
