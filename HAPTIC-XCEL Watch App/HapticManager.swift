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
        WKInterfaceDevice.current().play(.notification)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            WKInterfaceDevice.current().play(.notification)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000)) {
            WKInterfaceDevice.current().play(.notification)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(3000)) {
            WKInterfaceDevice.current().play(.notification)
        }
    }
    
    private func playConfused() {
        WKInterfaceDevice.current().play(.failure)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
            WKInterfaceDevice.current().play(.failure)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1600)) {
            WKInterfaceDevice.current().play(.failure)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2400)) {
            WKInterfaceDevice.current().play(.failure)
        }
    }
    
    private func playConfident() {
        WKInterfaceDevice.current().play(.directionUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
            WKInterfaceDevice.current().play(.directionUp)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1600)) {
            WKInterfaceDevice.current().play(.directionUp)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2400)) {
            WKInterfaceDevice.current().play(.directionUp)
        }
    }
    
    func playPattern(reaction: String) {
        switch reaction {
        case "✋":
            self.playRaiseHand()
        case "😭":
            self.playConfused()
        case "😎":
            self.playConfident()
        default:
            break
        }
    }
}
