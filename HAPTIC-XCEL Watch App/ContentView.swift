//
//  ContentView.swift
//  HAPTIC-XCEL Watch App
//
//  Created by Oleg Golev on 10/4/23.
//

import SwiftUI

let base_app_url: String = "https://haptx-excel.onrender.com"

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
                NavigationLink(destination: SessionIdView().navigationBarBackButtonHidden(true)) {
                    Text("Begin Session")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .buttonStyle(.bordered)
            }.padding()
        }
    }
}

struct GetSessionResponse: Decodable {
    var session_id: String
    var link: String
}

struct SessionIdView: View {
    @State var session_id = ""
    var body: some View {
        VStack {
            Text("Session active at")
            Text("haptic-xcel.com/" + session_id)
                .bold()
            Image(systemName: "baseball.diamond.bases")
                .font(.largeTitle)
                .padding()
            NavigationLink(destination: SessionView(session_id: self.session_id).navigationBarBackButtonHidden(true)) {
                Text("Dismiss")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
        }.onAppear {
            // Make an HTTP request to get a new session ID.
            let url = URL(string: base_app_url + "/get-session")!
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data {
                    do {
                        let res = try JSONDecoder().decode(GetSessionResponse.self, from: data)
                        session_id = res.session_id
                    } catch let error {
                        // TODO: Make a pop-up that dismisses the user back to the home page.
                    }
                }
            }.resume()
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
               SessionRefresh(now: timeline.date)
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

struct SessionRefresh: View {
    @State var reactions: [Reaction] = []
    var now: Date
    
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
//                            TimelineView(.periodic(from: .now, by: 1)) { timeline in
//                                Text("\(Date().secondsToHoursMinutesSeconds(seconds: (Date().currentTimeMillis() - reaction.timestamp) / 1000)) ago")
//                            }
                        }
                    }
                }
            }
            .onChange(of: now) { _ in
                // Obtain a new reaction from the API server and timestamp it.
                var new_reactions: [Reaction] = [Reaction(reaction: "✋", quantity: 2, timestamp: 1696536101113), Reaction(reaction: "😕", quantity: 1, timestamp: 1696536101113)]
                let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    let timestamp = Date().currentTimeMillis()
                    if let data = data {
                        // TODO: If data was successfully acquired, process all reactions and add them to new_reactions.
                    } else if let error = error {
                        new_reactions.append(Reaction(reaction: "HTTP Error: Contact Administrator", quantity: 1, timestamp: timestamp))
                    }
                }
                // Insert each unique type of reaction (scaled to quantity) appear in the list.
                for new_reaction in new_reactions {
                    let random_num = Int.random(in: 1..<100)
                    if random_num > 90 {
                        withAnimation(.easeIn) {
                            self.reactions.insert(new_reaction, at: 0)
                        }
                    }
                }
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
        SessionIdView()
        SessionView(session_id: "1234")
        EndSessionView(session_id: "1234")
    }
}
