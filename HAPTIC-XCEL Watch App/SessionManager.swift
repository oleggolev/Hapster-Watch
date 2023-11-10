//
//  SessionManager.swift
//  HAPTIC-XCEL Watch App
//
//  Created by Oleg Golev on 10/16/23.
//

import Foundation
import WatchKit

class SessionManager {
    var session: WKExtendedRuntimeSession!
    
    func startSession() {
        self.session = WKExtendedRuntimeSession()
        self.session.start()
    }
    
    func endSession() {
        self.session.invalidate()
    }
    
    private func restart() {
        self.endSession()
        self.startSession()
    }
    
    func refreshSession() {
        // If the session if currently active, refresh it if there is little time left.
        if self.session.state != WatchKit.WKExtendedRuntimeSessionState.running {
            self.restart()
        }
        if let session_end_time = self.session.expirationDate {
            if Int64((session_end_time.timeIntervalSince1970 - Date().timeIntervalSince1970) * 1000) < SESSION_REFRESH_OFFSET_MS {
                self.restart()
            }
        }
    }
}
