//
//  KapApp.swift
//  Kap
//
//  Created by Desmond Fitch on 7/12/23.
//

import SwiftUI

@main
struct KapApp: App {
    @State private var viewModel = AppDataViewModel()
    
    var body: some Scene {
        WindowGroup {
            Home()
                .environment(\.viewModel, viewModel)
        }
    }
}
