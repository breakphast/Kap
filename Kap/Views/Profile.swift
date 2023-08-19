//
//  Profile.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI

struct Profile: View {
    @Environment(\.viewModel) private var viewModel
    @State var user: User?
    
    var body: some View {
        VStack {
            Text(user?.username ?? "")
                .task {
                    UserService().fetchUser(withUid: viewModel.activeUserID, completion: { user in
                        self.user = user
                    })
                }
            
            Button("Sign Out") {
                AuthViewModel().signOut()
                viewModel.activeUserID = ""
            }
        }
    }
}

//#Preview {
//    Profile()
//}
