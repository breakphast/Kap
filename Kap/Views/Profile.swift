//
//  Profile.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI

struct Profile: View {
    @EnvironmentObject var homeViewModel: AppDataViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var user: User?
    @Binding var loggedIn: Bool
    
    var body: some View {
        VStack {
            Text(user?.username ?? "")
                .task {
                    UserService().fetchUser(withUid: authViewModel.currentUser?.id ?? "", completion: { user in
                        self.user = user
                    })
                }
            
            Button("Sign Out") {
                authViewModel.signOut()
                homeViewModel.activeUserID = ""
                loggedIn = false
            }
        }
    }
}

//#Preview {
//    Profile()
//}
