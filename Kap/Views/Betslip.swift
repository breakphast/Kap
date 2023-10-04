//
//  Betslip.swift
//  Kap
//
//  Created by Desmond Fitch on 7/17/23.
//

import SwiftUI

struct Betslip: View {
    private let dismissThreshold: CGFloat = 100.0
    
    @State private var offset: CGFloat = 0.0
    @State private var shouldDismiss = false
    @State private var parlays: [Parlay] = []
    @State private var parlay: Parlay?
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color("onyx").ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                contentStack
            }
        }
        .gesture(swipeGesture)
        .onChange(of: shouldDismiss, perform: { newValue in
            withAnimation { dismiss() }
        })
        .onChange(of: homeViewModel.selectedBets.count, perform: { newValue in
            withAnimation {
                guard newValue >= 2 else { return }
                updateParlay()
            }
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Betslip")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
        }
    }
    
    private func updateParlay() {
        self.parlay?.bets = homeViewModel.selectedBets
        if calculateParlayOdds(bets: homeViewModel.selectedBets) < 400 {
            parlay = nil
            homeViewModel.activeParlays = []
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.startLocation.x < 50 {
                    self.offset = value.translation.width
                }
            }
            .onEnded { value in
                // Check if swipe distance is more than the threshold
                if value.translation.width > dismissThreshold {
                    shouldDismiss = true
                } else {
                    offset = 0
                }
            }
    }
    
    var contentStack: some View {
        VStack(spacing: 20) {
            ForEach(homeViewModel.selectedBets, id: \.id) { bet in
                BetView(bet: bet)
            }
            
            if parlay != nil {
                ParlayView(parlays: $parlays, parlay: parlay!)
            }
        }
        .padding(.top, 20)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .onTapGesture {
                        dismiss()
                    }
            }
        }
    }
}
