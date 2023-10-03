//
//  LiveBetsView.swift
//  Kap
//
//  Created by Desmond Fitch on 9/22/23.
//

import SwiftUI

struct LiveBetsView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    let bets: [Bet]
    let users: [User]
    
    var body: some View {
        ZStack {
            Color.onyx.ignoresSafeArea()
            
            VStack(alignment: .leading) {
                VStack {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: 100, height: 4)
                        .foregroundStyle(Color("onyxLightish"))
                    
                    Text("LIVE BETS")
                        .foregroundStyle(.oW)
                        .font(.title2)
                        .fontWeight(.black)
                        .kerning(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
                
                ScrollView(showsIndicators: false) {
                    ForEach(users) { user in
                        VStack(alignment: .leading) {
                            HStack {
                                Image("avatar\(user.avatar ?? 0)")
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                                    .frame(width: 40)
                                
                                Text(user.username.uppercased())
                                    .foregroundStyle(.oW)
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .kerning(0.8)
                                Spacer()
                            }
                            ForEach(bets.filter({ $0.playerID == user.id! }), id: \.id) { bet in
                                PlacedBetView(bet: bet, week: homeViewModel.currentWeek)
                            }
                        }
                    }
                }
                .padding([.top, .horizontal])
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
