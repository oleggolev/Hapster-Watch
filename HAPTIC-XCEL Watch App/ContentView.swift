//
//  ContentView.swift
//  HAPTIC-XCEL Watch App
//
//  Created by Oleg Golev on 10/4/23.
//

import SwiftUI

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
            // Make an HTTP request to get a new session ID
            session_id = "10456"
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

struct SessionRefresh: View {
    @State var index = 0
    var now: Date
    var body: some View {
            VStack {
                List {
                    HStack {
                        Text("😂")
                        Spacer()
                        Text("\(index)s ago")
                    }
                    HStack {
                        Text("✋")
                        Spacer()
                        Text("\(index - 7)s ago")
                    }
                }
            }
            .onChange(of: now) { _ in
                // Obtain new reactions from the API server.
                index += 1
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
