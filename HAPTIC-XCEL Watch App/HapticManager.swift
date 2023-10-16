//
//  HapticManager.swift
//  HAPTIC-XCEL Watch App
//
//  Created by Oleg Golev on 10/15/23.
//

import Foundation
import WatchKit

class HapticManager {
    
    private func playRaiseHand() {
        WKInterfaceDevice.current().play(.failure)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            WKInterfaceDevice.current().play(.failure)
        }
    }
    
    private func playConfused() {
        WKInterfaceDevice.current().play(.stop)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            WKInterfaceDevice.current().play(.stop)
        }
    }
    
    private func playInteresting() {
        WKInterfaceDevice.current().play(.success)
    }
    
    func playPattern(reaction: String) {
        switch reaction {
        case "✋":
            self.playRaiseHand()
        case "😕":
            self.playConfused()
        case "💡":
            self.playInteresting()
        default:
            break
        }
    }
}
