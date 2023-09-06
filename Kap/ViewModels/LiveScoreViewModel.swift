//
//  LiveScoreViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 8/18/23.
//

import Foundation
import SwiftUI

struct LiveScoreView: View {
    @ObservedObject var viewModel = LiveScoreViewModel()

    var body: some View {
        List(viewModel.liveScores, id: \.gameKey) { score in
            VStack(alignment: .leading) {
                Text("Match: \(score.homeTeam) vs \(score.awayTeam)")
                if let quarter = score.quarter {
                    Text("Quarter: \(String(describing: quarter))")
                }
                if let timeRemaining = score.timeRemaining {
                    Text("Time Remaining: \(String(describing: timeRemaining))")
                }

            }
        }
        .onAppear(perform: viewModel.fetchLiveScores)
    }
}

class LiveScoreViewModel: ObservableObject {
    @Published var liveScores: LiveScore = []
    
    func fetchLiveScores() {
        // Here, you'd fetch the JSON data from the desired endpoint.
        // For the sake of this example, I'll use a placeholder URL.
        guard let url = URL(string: "https://api.sportsdata.io/v3/nfl/scores/json/ScoresByWeek/2023PRE/3?key=bb4e410c9936e44178d46969c50504e9") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let decodedData = try JSONDecoder().decode(LiveScore.self, from: data)
                    DispatchQueue.main.async {
                        self.liveScores = decodedData
                    }
                } catch {
                    print("Failed to decode: \(error)")
                }
            }
        }.resume()
    }
}
