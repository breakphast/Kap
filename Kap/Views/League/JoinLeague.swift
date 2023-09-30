//
//  JoinLeague.swift
//  Kap
//
//  Created by Desmond Fitch on 9/25/23.
//

import SwiftUI

struct JoinLeague: View {
    @FocusState private var focusedField: Int?
    @State private var code: [String] = ["", "", "", ""]
    @State private var validCode: Bool?
    @State private var result: Bool?
    @State private var navigateToNextView: Bool = false
    @Binding var loggedIn: Bool
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.onyx.ignoresSafeArea()
                
                if result == true {
                    Image(systemName: "checkmark")
                        .font(.system(size: 48))
                        .bold()
                        .foregroundStyle(.bean)
                } else {
                    VStack {
                        Text("Enter Code")
                            .foregroundStyle(.oW)
                        
                        HStack(spacing: 20) {
                            ForEach(0..<4) { index in
                                DigitTextField(digit: $code[index], code: $code, focusedField: _focusedField, validCode: $validCode, result: $result, loggedIn: $loggedIn, index: index)
                            }
                        }
                        .onAppear {
                            focusedField = 0
                        }
                        
                        if validCode == false {
                            Text("Invalid code. Please try again.")
                                .foregroundStyle(.redd)
                                .font(.caption.bold())
                        }
                    }
                }
            }
            .font(.largeTitle.bold())
            .fontDesign(.rounded)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.oW)
                        .onTapGesture {
                            dismiss()
                        }
                }
            }
        }
    }
}

struct DigitTextField: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel

    @Binding var digit: String
    @Binding var code: [String]
    @FocusState var focusedField: Int?
    @Binding var validCode: Bool?
    @Binding var result: Bool?
    @Binding var loggedIn: Bool
    
    let index: Int
    
    var body: some View {
        TextField("", text: $digit)
            .keyboardType(.numberPad)
            .onChange(of: digit) { newValue in
                handleDigitChange(newValue: newValue)
            }
            .focused($focusedField, equals: index)
            .frame(width: 40, height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(lineWidth: 3.0)
                    .foregroundStyle(digit.isEmpty ? .oW : .lion)
            )
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(digit.isEmpty ? .onyx : Color.lion)
            )
            .textCase(.uppercase)
            .multilineTextAlignment(.center)
            .foregroundColor(.oW)
            .font(.system(size: 24, weight: .bold, design: .default))
            .disableAutocorrection(true)
            .autocapitalization(.none)
    }
    func handleDigitChange(newValue: String) {
        adjustDigitCountBasedOn(newValue: newValue)
        handleFieldFocusWhenDigitIsNotEmpty()
        validateCodeWhenIndexIsThree()
        focusPreviousFieldIfNewValueIsEmpty(newValue: newValue)
    }

    private func adjustDigitCountBasedOn(newValue: String) {
        if newValue.count > 1 {
            digit = String(newValue.first ?? Character(""))
        }
    }

    private func handleFieldFocusWhenDigitIsNotEmpty() {
        if !digit.isEmpty && index < 3 {
            focusedField = index + 1
        }
    }

    private func validateCodeWhenIndexIsThree() {
        if index == 3 {
            if homeViewModel.leagueIDs.contains(code.joined()) {
                withAnimation(.easeInOut) {
                    result = true
                }
                Task {
                    homeViewModel.activeLeagueID = code.joined()
                    if code.joined() == "5555" {
                        leaderboardViewModel.leagueType = .season
                    } else {
                        leaderboardViewModel.leagueType = .weekly
                    }
                    homeViewModel.users = try await UserViewModel().fetchAllUsers()
                    homeViewModel.leagues = try await LeagueViewModel().fetchAllLeagues()

                    leagueViewModel.activeLeague = homeViewModel.leagues.first(where: {$0.code == code.joined()})
                    if let activeLeague = leagueViewModel.activeLeague {
                        leagueViewModel.points = activeLeague.points ?? [:]
                        _ = homeViewModel.leagues.first(where: { $0.code == code.joined() })?.players
                        if let userID = authViewModel.currentUser?.id {
                            try await LeagueViewModel().addPlayerToLeague(leagueId: activeLeague.id!, playerId: userID)
                            homeViewModel.leagues = try await LeagueViewModel().fetchAllLeagues()
                            let leaguePlayers = homeViewModel.leagues.first(where: { $0.code == activeLeague.code })?.players
                            if let leaguePlayers = leaguePlayers {
                                homeViewModel.users = homeViewModel.users.filter({ leaguePlayers.contains($0.id!) })
                            } else {
                                homeViewModel.users = []
                            }
                        }
                    }
                    await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.bets.filter({$0.leagueID == leagueViewModel.activeLeague?.code}), parlays: homeViewModel.parlays.filter({$0.leagueID == leagueViewModel.activeLeague?.code}), week: homeViewModel.currentWeek)

                    homeViewModel.leagues = try await LeagueViewModel().fetchAllLeagues()
                    homeViewModel.userLeagues = try await LeagueViewModel().fetchLeaguesContainingID(id: authViewModel.currentUser?.id ?? "")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        validCode = true
                        loggedIn = true
                    }
                }
            } else {
                validCode = false
            }
        }
    }

    private func focusPreviousFieldIfNewValueIsEmpty(newValue: String) {
        if newValue == "" && index > 0 {
            validCode = nil
            focusedField = index - 1
        }
    }
}
