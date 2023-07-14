//
//  ExtendedWeeklyLeaderboard.swift
//  Kap
//
//  Created by Desmond Fitch on 7/12/23.
//

import SwiftUI

struct ExtendedWeeklyLeaderboard: View {
    @State var mainPlayers = [Player]()
    @State private var games = [Game]()
    
    var body: some View { 
        VStack(spacing: 24) {
            ZStack {
                Text("Week 1 Leaderboard")
                    .font(.title.bold())
            }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(games, id: \.id) { game in
                        Text(game.awayTeam + " @ " + game.homeTeam)
                            .font(.caption.bold())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .task {
            do {
                let league = AppDataViewModel().createLeague(name: "BIG JOHN SILVER", players: [])
                let season = AppDataViewModel().createSeason(league: league, year: 2023)
                var weeks = [Week]()
                
                let week = await AppDataViewModel().createWeek(season: season, league: season.league, weekNumber: 0)
                weeks.append(week)
                
                season.weeks = weeks
                
                let games = try await GameService().getGames()
                let weeklyGames = games.chunked(into: 16)
                self.games = weeklyGames[0]
            } catch {
                print("Failed to get games: \(error)")
            }
        }
    }
}

#Preview {
    ExtendedWeeklyLeaderboard()
}
