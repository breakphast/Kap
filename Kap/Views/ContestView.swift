//
//  ContestView.swift
//  Kap
//
//  Created by Desmond Fitch on 10/20/23.
//

import SwiftUI

struct ContestView: View {
    @State private var progress: Float = 0.15
    @State private var showDetails = false
    
    let cards = [
        Card(title: "$86K NFL Week 8 ($17.2K to 1st)", totalEntries: 10382, entries: 2441, fee: 10, prizes: 86000),
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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.lion.ignoresSafeArea()
                VStack {
                    Text("Contests")
                        .foregroundColor(.oW)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(cards, id: \.title) { card in
                                Card(title: card.title, totalEntries: card.totalEntries, entries: card.entries, fee: card.fee, prizes: card.prizes)
                                    .onTapGesture {
                                        withAnimation {
                                            showDetails.toggle()
                                        }
                                    }
                                RoundedRectangle(cornerRadius: 0.5)
                                    .frame(height: 1)
                                    .foregroundStyle(.onyxLightish)
                            }
                        }
                    }
                    .background(.onyx)
                }
            }
            .fullScreenCover(isPresented: $showDetails) {
                ContestDetails()
            }
        }
    }
}

struct Card: View {
    let title: String
    let totalEntries: Int
    var entries: Int
    let fee: Int
    let prizes: Int
    var noImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .foregroundColor(.lion)
                    .fontWeight(.heavy)
                    .lineLimit(1)
                Spacer()
                if !noImage {
                    Image("loch")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                        .shadow(radius: 4)
                }
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entries) of \(totalEntries)")
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("ENTRIES")
                        .foregroundColor(Color(uiColor: .lightGray))
                        .font(.caption2)
                        .fontWidth(.condensed)
                }
                .frame(width: UIScreen.main.bounds.width / 3, alignment: .leading)
                .fontWeight(.semibold)

                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text(fee == 0 ? "FREE" : "$\(fee)")
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("ENTRY")
                        .foregroundColor(Color(uiColor: .lightGray))
                        .font(.caption2)
                        .fontWidth(.condensed)
                }
                .frame(width: UIScreen.main.bounds.width / 8, alignment: .leading)
                .fontWeight(.semibold)

                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(prizes)")
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("PRIZES")
                        .foregroundColor(Color(uiColor: .lightGray))
                        .font(.caption2)
                        .fontWidth(.condensed)
                }
                .frame(width: UIScreen.main.bounds.width / 4, alignment: .trailing)
                .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .foregroundColor(Color.onyx)
        )
        .fontDesign(.rounded)
    }
}

struct ProgressBar: View {
    @Binding var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(Color.oW.opacity(0.3))
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .frame(width: geometry.size.width * CGFloat(value))
                    .foregroundColor(.lion)
            }
            .frame(width: geometry.size.width * 0.4)
            .cornerRadius(45.0)
        }
    }
}

#Preview {
    ContestView()
}
