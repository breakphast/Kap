//
//  HowToPlay.swift
//  Kap
//
//  Created by Desmond Fitch on 9/19/23.
//

import SwiftUI

struct HowToPlay: View {
    var body: some View {
            ZStack(alignment: .top) {
                Color("onyx").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack {
                        header
                        titleText
                        instructionsContent
                        endSpacer
                    }
                }
                .padding(.top, 4)
            }
            .fontDesign(.rounded)
            .preferredColorScheme(.dark)
        }
        
        var header: some View {
            HStack(spacing: 16) {
                Image("loch")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color("oW").opacity(0.7), radius: 4)
                
                VStack(alignment: .leading) {
                    Text("Loch")
                        .font(.title.bold())
                    Text("Competitive Sports Betting")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("lion"))
                }
            }
            .padding(.top, 8)
        }
        
        var titleText: some View {
            Text("How To Play")
                .font(.title.bold())
                .padding(.top)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
        }
        
        var instructionsContent: some View {
            VStack(alignment: .leading) {
                InstructionStep(number: "1", description: "Select your bets for the week")
                InstructionStep(number: "2", description: "Wait for your bets to settle")
                schedule
                    .padding(.top)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
        
        var endSpacer: some View {
            RoundedRectangle(cornerRadius: 2)
                .frame(height: 20)
                .foregroundColor(.clear)
        }
    var schedule: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Season & Playoffs")
                .font(.title)
                .fontWeight(.black)
            Text("A full season consists of 16 weeks.\nThe top 6 (varies by league settings) leaders in points advance to the Playoffs.")
                .foregroundColor(Color("oW"))
                .fontWeight(.none)
            Text("There are 3 rounds of playoffs\n- Quarterfinals\n- Semifinals\n- Championship")
                .foregroundColor(Color("oW"))
            Text("The 2 players with the least amount of points are eliminated per round.\nThe points format stays the same, except there are no parlay bonuses.")
                .foregroundColor(Color("oW"))
                .fontWeight(.none)
        }
        .fontWeight(.semibold)
    }
}

struct InstructionStep: View {
    let number: String
    let description: String
    let image: Image? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number). \(description)")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(Color("lion"))
            if number == "1" {
                VStack(alignment: .leading) {
                    Text("Each week, players select 10 bets to compete and showcase their sports knowledge.")
                        .fontWeight(.medium)
                        .padding(.bottom, 2)
                    Text("1. Select your bet(s) on the homepage.\n2.Click the BETSLIP tab to place your bets.")
                        .fontWeight(.bold)
                    HStack {
                        Image("chooseBet")
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .frame(width: 110, height: 110)  // Specify both width and height
                            .shadow(color: Color("oW").opacity(0.2), radius: 4)
                        Spacer()
                        Image("placeBet")
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .frame(width: 110, height: 110)  // Specify both width and height
                            .shadow(color: Color("oW").opacity(0.2), radius: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 30)
                    .padding(.vertical)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bets Format")
                            .font(.title2)
                            .fontWeight(.black)
                        Text("Thursday Night Football: 1 Bet\nSunday Afternoon Games: 7 Bets\nSunday Night Football: 1 Bet\nMonday Night Football: 1 Bet")
                            .foregroundColor(Color("oW"))
                            .fontWeight(.none)
                        Text("Users must bet all 10 games in the specified format. Each missed bet will be counted as a loss.")
                            .fontWeight(.bold)
                        Text("Players also get 1 Parlay Bonus per week. The parlay must be between +400 and +1000. This is optional and can result in a loss (-10 points).")
                    }
                }
                .fontWeight(.semibold)
                .foregroundColor(Color("oW"))
            } else if number == "2" {
                pointsSystem
            }
        }
        .padding(.vertical, 4)
    }
    
    var pointsSystem: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Points System")
                    .font(.title2)
                    .fontWeight(.black)
                Text("Each bet is calculated using a base of 10 points and is adjusted based on its odds.")
                    .foregroundColor(Color("oW"))
                    .fontWeight(.none)
                Text("If a bet ") + Text("wins").foregroundColor(Color("bean")) + Text(", the player is rewarded the calculated points.\nIf a bet ") + Text("loses").foregroundColor(Color("redd")) + Text(", the player is deducted 10 base points.")
                    .fontWeight(.none)
            }
            
            HStack {
                Image("settledBet")
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(width: 120, height: 120)  // Specify both width and height
                    .shadow(color: Color("oW").opacity(0.2), radius: 4)
                Spacer()
                Image("lostBet")
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(width: 120, height: 120)  // Specify both width and height
                    .shadow(color: Color("oW").opacity(0.2), radius: 4)
            }
            .padding(.horizontal, 30)
            
            Text("As bets settle, the leaderboard is updated accordingly. This shows league rankings per week and overall.")
                .fontWeight(.bold)
            
            RoundedRectangle(cornerRadius: 4)
                .frame(height: 2)
                .foregroundStyle(.secondary)
        }
        .fontWeight(.semibold)
    }
}

struct HowToPlay_Previews: PreviewProvider {
    static var previews: some View {
        HowToPlay()
    }
}
