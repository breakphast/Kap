//
//  ContentView.swift
//  kappers
//
//  Created by Desmond Fitch on 6/23/23.
//

import SwiftUI

struct Leaderboard: View {
    @State private var games = [Game]()
    @State private var players: [Player] = []
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("onyx").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(players.enumerated()), id: \.1.id) { index, player in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("\(index + 1)")
                                        .frame(width: 24)
                                        .font(.title3.bold())
                                    
                                    ZStack(alignment: .leading) {
                                        if abs(player.points[0] ?? 0) > 30 || index == 0 {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.clear)
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .padding()
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(index == 0 ? Color("leader") : player.points[0] ?? 0 >= 0 ? Color.green : Color.red, lineWidth: 3)
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
                                                        .foregroundStyle(player.points[0]! < 0 ? .red : .green)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: index == 0 ? "minus" : player.points[0]! >= 0 ? "chevron.up.circle" : "chevron.down.circle")
                                                .font(.title2.bold())
                                                .foregroundStyle(index == 0 ? .secondary : player.points[0]! >= 0 ? Color.green : Color.red)
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
                    .padding(.horizontal)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Leaderboard")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        }
                    }
                    .task {
                        do {
                            let league = AppDataViewModel().createLeague(name: "BIG JOHN SILVER", players: [])
                            let season = AppDataViewModel().createSeason(league: league, year: 2023)
                            var weeks = [Week]()
                            
                            let week = await AppDataViewModel().createWeek(season: season, league: season.league, weekNumber: 0)
                            let week2 = await AppDataViewModel().createWeek(season: season, league: season.league, weekNumber: 1)
                            weeks.append(week)
                            weeks.append(week2)
                            
                            season.weeks = weeks
                            
                            let games = try await GameService().getGames()
                            let weeklyGames = games.chunked(into: 16)
                            self.games = weeklyGames[0]
                            
                            for player in league.players {
                                let _ = AppDataViewModel().generateRandomBets(from: self.games, betCount: 6, player: player)
                                let _ = AppDataViewModel().createParlayWithinOddsRange(for: player, from: self.games)
                            }
                            
                            self.players = league.players.sorted { $0.points[0] ?? 0 > $1.points[0] ?? 0 }
                        } catch {
                            print("Failed to get games: \(error)")
                        }
                    }
                }
            }
            .fontDesign(.rounded)
        }
    }
}

#Preview {
    Leaderboard()
}
