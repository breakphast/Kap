//
//  Home.swift
//  Kap
//
//  Created by Desmond Fitch on 7/12/23.
//

import SwiftUI
import Observation

struct Home: View {
    @Environment(\.viewModel) private var viewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("onyx").ignoresSafeArea()
                
                VStack {
                    Text("Devsmond's League")
                        .bold()
                    
                    VStack(alignment: .leading) {
                        HStack {
                            NavigationLink(destination: MyBets()) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor(.blue.opacity(0.8)) // Assuming you have defined a color extension for light blue
                                    
                                    Text("My Bets")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 200)
                            
                            Spacer()
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.green.opacity(0.8)) // Assuming you have defined a color extension for light blue
                                
                                Text("Profile")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                            .frame(height: 200)
                        }
                        
                        NavigationLink(destination: Board()) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.red.opacity(0.8)) // Assuming you have defined a color extension for light blue
                                
                                Text("BOARD")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 200)
                        
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.lion.opacity(0.8)) // Assuming you have defined a color extension for light blue
                                
                                Text("Stats & News")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                            .frame(height: 200)
                            
                            Spacer()
                            
                            NavigationLink(destination: Betslip()) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor(.purple.opacity(0.8)) // Assuming you have defined a color extension for light blue
                                    
                                    Text("MyBets")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 200)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                }
            }
            .task {
                if viewModel.players.isEmpty {
                    let _ = await viewModel.getLeaderboardData()
               
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    Home()
}

extension EnvironmentValues {
    var viewModel: AppDataViewModel {
        get { self[ViewModelKey.self] }
        set { self[ViewModelKey.self] = newValue }
    }
}

private struct ViewModelKey: EnvironmentKey {
    static var defaultValue: AppDataViewModel = AppDataViewModel()
}
