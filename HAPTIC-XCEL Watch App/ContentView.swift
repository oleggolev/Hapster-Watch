//
//  ContentView.swift
//  HAPTIC-XCEL Watch App
//
//  Created by Oleg Golev on 10/4/23.
//

import SwiftUI

let BASE_APP_URL: String = "https://haptic-xcel.onrender.com"
let REACTION_POOLING_INTERVAL_MS: Int = 5000
let REACTION_ID_TO_EMOJI_MAP: [Int: String] = [
    1: "✋",
    2: "😕",
    3: "💡"
]

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("HAPTIC XCEL")
                    .font(.headline)
                Text("Real-time feedback for instructors")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
                NavigationLink(destination: SessionIdView(session_id_view: SessionIdViewModel()).navigationBarBackButtonHidden(true)) {
                    Text("Begin Session")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct GetSessionResponse: Decodable {
    var session_id: String
    var link: String
}

class SessionIdViewModel: ObservableObject {
    @Published var is_loading: Bool
    var session_id: String = ""
    var reset: Bool
    
    init() {
        self.is_loading = true
        self.reset = false
        // Make an HTTP request to get a new session ID.
        let url = URL(string: "\(BASE_APP_URL)/get-session")!
        URLSession.shared.dataTask(with: url) { data, response, internal_error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("ERROR: could not start new session, received error code \(httpResponse.statusCode).")
                    self.reset = true
                }
            }
            if let data = data {
                do {
                    let res = try JSONDecoder().decode(GetSessionResponse.self, from: data)
                    print("Session \(res.session_id) created successfully.")
                    self.session_id = res.session_id
                } catch let internal_error {
                    print("ERROR: could not unpack JSON when creating session: \(internal_error.localizedDescription)")
                    self.reset = true
                }
            }
            if let internal_error = internal_error {
                print("ERROR: could not start new session, received error \(internal_error.localizedDescription)")
                self.reset = true
            }
            self.is_loading = false
        }.resume()
    }
}

struct SessionIdView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var session_id_view: SessionIdViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    if session_id_view.is_loading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Session active at")
                            .font(.system(size: 14))
                            .padding()
                        Text("haptic-excel.onrender.com")
                            .multilineTextAlignment(.center)
                            .bold()
                            .font(.system(size: 12))
                        Text("Session ID: \(session_id_view.session_id)")
                            .bold()
                        Image(systemName: "baseball.diamond.bases")
                            .font(.largeTitle)
                            .padding()
                        NavigationLink(destination: SessionView(session_id: session_id_view.session_id).navigationBarBackButtonHidden(true)) {
                            Text("Dismiss")
                                .font(.headline)
                        }
                        .buttonStyle(.bordered)
                    }
                }.alert(isPresented: $session_id_view.reset) {
                    Alert(
                        title: Text("Oops! Something went wrong..."),
                        message: Text("Seems like our servers are down :("),
                        dismissButton: Alert.Button.default(
                            Text("Dismiss"), action: { dismiss() }
                        )
                    )
                }
            }
        }
    }
}

struct SessionView: View {
    var session_id: String
    var body: some View {
        TabView {
            LiveSessionView(session_id: self.session_id)
            EndSessionView(session_id: self.session_id)
        }
    }
}

struct LiveSessionView: View {
    var session_id: String
    var body: some View {
       VStack {
           Text("Live Feedback")
           TimelineView(.periodic(from: .now, by: 1)) { timeline in
               SessionRefresh(now: timeline.date, session_id: session_id)
           }
           .navigationTitle("ID: " + session_id)
           .navigationBarTitleDisplayMode(.inline)
       }
    }
}

struct Reaction: Hashable {
    var reaction: String
    var quantity: Int
    var timestamp: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.reaction)
        hasher.combine(self.quantity)
        return hasher.combine(self.timestamp)
    }
}

extension Date {
    func currentTimeMillis() -> Int {
        return Int(self.timeIntervalSince1970 * 1000)
    }
    func secondsToHoursMinutesSeconds(seconds: Int) -> String {
        let (hours, minutes, seconds) = (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
        var time_str = ""
        if hours != 0 {
            time_str += "\(hours)h "
        }
        if minutes != 0 {
            time_str += "\(minutes)m "
        }
        return time_str + "\(seconds)s"
    }
}

struct GetReactionResponse: Decodable {
    var reaction: Int
    var timeStamp: String
    var sessionId: String
    var userSessionId: String
}

struct SessionRefresh: View {
    @State var reactions: [Reaction] = []
    var now: Date
    var session_id: String
    
    var body: some View {
            VStack {
                List {
                    ForEach(self.reactions, id: \.self) { reaction in
                        HStack {
                            Text("\(reaction.reaction)")
                            if reaction.quantity > 1 {
                                Text(" x\(reaction.quantity)")
                            } else {
                                Text("")
                            }
                            Spacer()
                            Text("\(Date().secondsToHoursMinutesSeconds(seconds: (Date().currentTimeMillis() - reaction.timestamp) / 1000)) ago")
                                .foregroundColor(.gray)
                                .bold()
                                .font(.system(size: 14))
                        }
                    }
                }
            }
            .onChange(of: now) { _ in
                // Get new reaction for this session.
                let url = URL(string: "\(BASE_APP_URL)/get-reaction/\(self.session_id)")!
                var new_reactions: [String: (Int, Int)] = [:]
                URLSession.shared.dataTask(with: url) { data, response, internal_error in
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode != 200 {
                            print("ERROR: could not get reactions for session \(session_id), received error code \(httpResponse.statusCode).")
                            return
                        }
                    }
                    if let data = data {
                        do {
                            let response = try JSONDecoder().decode([GetReactionResponse].self, from: data)
                            // Accumulate the reaction responses to reduce noise.
                            for get_reaction in response {
                                if let reaction_str = REACTION_ID_TO_EMOJI_MAP[get_reaction.reaction] {
                                    if new_reactions[reaction_str] != nil {
                                        new_reactions[reaction_str]?.0 += 1
                                    } else {
                                        new_reactions[reaction_str] = (1, Date().currentTimeMillis())
                                    }
                                } else {
                                    new_reactions["INVALID REACTION"] = (1, Date().currentTimeMillis())
                                }
                            }
                        } catch let internal_error {
                            print("ERROR: could not unpack JSON when receiving reaction for session \(self.session_id): \(internal_error.localizedDescription)")
                            new_reactions["JSON ERROR"] = (1, Date().currentTimeMillis())
                        }
                    }
                    if let internal_error = internal_error {
                        print("ERROR: could not get reaction for session \(self.session_id), received error \(internal_error.localizedDescription)")
                        new_reactions["HTTP ERROR"] = (1, Date().currentTimeMillis())
                    }
                    // Insert each unique type of reaction (scaled to quantity) such that it appears in the list.
                    for new_reaction in new_reactions {
                        var idx = 0
                        var added = false
                        while idx < self.reactions.count {
                            if self.reactions[idx].reaction == new_reaction.key && abs(self.reactions[idx].timestamp - new_reaction.value.1) <= REACTION_POOLING_INTERVAL_MS {
                                self.reactions[idx].quantity += new_reaction.value.0
                                added = true
                            }
                            idx += 1
                        }
                        // If this is a completely new reaction sent in the last REACTION_POOLING_INTERVAL_MS
                        // time period, then insert as new row and create a notification with haptic pattern.
                        if !added {
                            withAnimation(.easeIn) {
                                self.reactions.insert(Reaction(reaction: new_reaction.key, quantity: new_reaction.value.0, timestamp: new_reaction.value.1), at: 0)
                            }
                        }
                    }
                }.resume()
            }
    }
}

struct EndSessionView: View {
    var session_id: String
    var body: some View {
        VStack {
            Text("Done teaching the current session?")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
            NavigationLink(destination: HomeView().navigationBarBackButtonHidden(true)) {
                Text("End Session")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
            .simultaneousGesture(TapGesture().onEnded {
                let url = URL(string: "\(BASE_APP_URL)/end-session/\(self.session_id)")!
                URLSession.shared.dataTask(with: url) { _, response, internal_error in
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            print("Session \(session_id) ended successfully.")
                        } else {
                            print("ERROR: could not end session \(session_id), received error code \(httpResponse.statusCode).")
                        }
                    }
                    if let internal_error = internal_error {
                        print("ERROR: could not end session, received error \(internal_error.localizedDescription)")
                    }
                }.resume()
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
        SessionView(session_id: "RBAGO6")
    }
}
