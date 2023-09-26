//
//  LeagueIntro.swift
//  Kap
//
//  Created by Desmond Fitch on 9/25/23.
//

import SwiftUI

struct LeagueIntro: View {
    @Binding var loggedIn: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.onyx.ignoresSafeArea()
                
                VStack(spacing: 12) {
                    NavigationLink(destination: JoinLeague(loggedIn: $loggedIn)) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .shadow(radius: 4)
                            Text("Join League")
                                .foregroundStyle(.oW)
                        }
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .shadow(radius: 4)
                        VStack {
                            Text("Create League")
                            Text("(Coming Soon)")
                                .font(.title3)
                        }
                        .foregroundStyle(.oW)
                    }

                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).foregroundStyle(.onyx.opacity(0.5)))
                }
                .foregroundStyle(.lion)
                .padding()
            }
            .font(.largeTitle.bold())
            .fontDesign(.rounded)
        }
    }
}

//#Preview {
//    LeagueIntro()
//}
