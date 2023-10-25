//
//  ContestDetails.swift
//  Kap
//
//  Created by Desmond Fitch on 10/20/23.
//

import SwiftUI

struct ContestDetails: View {
    @State private var progress: Float = 0.15
    @Environment(\.dismiss) var dismiss
    let contest = Contest(title: "$86K NFL Week 8 (17.2K to 1st)", entries: 2441, totalEntries: 10382, fee: 10, prizes: 86000)
    
    let cards = [
        Card(title: "$86K NFL Week 8 ($17.2K to 1st)", totalEntries: 10382, entries: 2441, fee: 10, prizes: 86000, noImage: true),
        Card(title: "$1M NFL Super Week 8 ($200K to 1st)", totalEntries: 130489, entries: 43434, fee: 5, prizes: 1000000),
        Card(title: "$400K Thu NFL Sneak Play ($100K to 1st)", totalEntries: 8472, entries: 1002, fee: 55, prizes: 400000),
        Card(title: "$2.2M Mega Monster NFL ($1M to 1st)", totalEntries: 2000, entries: 24, fee: 555, prizes: 2200000),
        Card(title: "$75K Mini NFL Week 8 ($10K to 1st)", totalEntries: 29487, entries: 3431, fee: 1, prizes: 75000),
        Card(title: "$100K Apple Music Challenge", totalEntries: 500000, entries: 248343, fee: 0, prizes: 100000),
        Card(title: "$86K NFL Week 8 ($17.2K to 1st)", totalEntries: 10382, entries: 2441, fee: 10, prizes: 86000),
        Card(title: "$1M NFL Super Week 8 ($200K to 1st)", totalEntries: 130489, entries: 43434, fee: 5, prizes: 1000000),
        Card(title: "$400K Thu NFL Sneak Play ($100K to 1st)", totalEntries: 8472, entries: 1002, fee: 55, prizes: 400000),
        Card(title: "$2.2M Mega Monster NFL ($1M to 1st)", totalEntries: 2000, entries: 24, fee: 555, prizes: 2200000),
        Card(title: "$75K Mini NFL Week 8 ($10K to 1st)", totalEntries: 29487, entries: 3431, fee: 1, prizes: 75000),
        Card(title: "$100K Apple Music Challenge", totalEntries: 500000, entries: 248343, fee: 0, prizes: 100000)
    ]
    
    let prizes = [
        ["1st": "$17,000"],
        ["2nd": "$8,500"],
        ["3rd": "$4,000"],
        ["4th": "$2,000"],
        ["5th": "$1,500"],
        ["6th": "$1,300"],
        ["7th": "$1,200"],
        ["8th": "$1,000"],
        ["9th - 10th": "$750"],
        ["11th - 12th": "$500"],
        ["13th - 15th": "$250"],
        ["16th - 20th": "$125"],
        ["21st - 30th": "$100"],
        ["21st - 40th": "$75"],
        ["41st - 50th": "$50"],
        ["51st - 60th": "$25"],
        ["61st - 100th": "$10"]
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.lion.ignoresSafeArea()
                VStack {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(.oW)
                            .onTapGesture {
                                dismiss()
                            }
                        Spacer()
                        Text("Contest Details")
                            .foregroundColor(.oW)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .offset(x: -12)
                        Spacer()
                    }
                    .padding(.leading)

                    VStack(alignment: .leading, spacing: 0) {
                        cards[0]
                        
                        RoundedRectangle(cornerRadius: 0.5)
                            .frame(height: 1)
                            .padding(.leading)
                        
                        HStack {
                            Label("Sep. 7 - Sep. 11", systemImage: "football.fill")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("Enter")
                                .font(.caption.bold())
                                .foregroundColor(Color("oW"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color("lion"))
                                .cornerRadius(4)
                        }
                        .padding(12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Prizes")
                                .foregroundStyle(.lion)
                                .bold()
                            
                            RoundedRectangle(cornerRadius: 0.5)
                                .frame(height: 2)
                                .foregroundStyle(.lion)
                        }
                        .padding([.leading, .bottom])
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(0 ..< prizes.count, id: \.self) { index in
                                    HStack {
                                        ForEach(prizes[index].sorted(by: >), id: \.key) { key, value in
                                            Text(key)
                                                .frame(width: 150, alignment: .leading)
                                                .bold()
                                            Spacer()
                                            Text(value)
                                                .frame(width: 150, alignment: .trailing)
                                        }
                                    }
                                    .padding(.horizontal)
                                    RoundedRectangle(cornerRadius: 0.5)
                                        .frame(height: 1)
                                        .foregroundStyle(.onyxLightish)
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(.onyx)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 0, style: .continuous)
                            .foregroundColor(Color.onyx)
                    )
                    .fontDesign(.rounded)

                }
            }
        }
    }
}

struct Contest {
    let title: String
    var entries: Int
    let totalEntries: Int
    let fee: Int
    let prizes: Int
}

#Preview {
    ContestDetails()
}
