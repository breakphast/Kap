//
//  CustomTimer.swift
//  Kap
//
//  Created by Desmond Fitch on 8/30/23.
//

import Foundation
import SwiftUI

var timer: DispatchSourceTimer?

func startTimer() {
    timer?.cancel() // cancel any previous timer if it exists
    
    timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
    
    // Schedule the timer to fire after 1 hour (3600 seconds)
    timer?.schedule(deadline: .now() + 3600)
    
    timer?.setEventHandler {
        // Call the function you want to execute here
        self.functionToRunAfterOneHour()
    }
    
    timer?.resume()
}

func cancelTimer() {
    timer?.cancel()
}
