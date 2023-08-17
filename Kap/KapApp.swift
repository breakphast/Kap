//
//  KapApp.swift
//  Kap
//
//  Created by Desmond Fitch on 7/12/23.
//

import SwiftUI
import Firebase

@main
struct KapApp: App {
    @State private var viewModel = AppDataViewModel(activeUserID: "")

    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Home()
                .environment(\.viewModel, viewModel)
        }
    }
}
