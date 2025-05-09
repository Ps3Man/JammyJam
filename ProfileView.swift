import SwiftUI

struct ProfileView: View {
    @AppStorage("username") private var username: String = ""
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = true
    @AppStorage("streamingQuality") private var streamingQuality: String = "High"
    @State private var isEditingUsername = false
    @State private var newUsername = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("PROFILE")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("AccentColor"))
                            .frame(width: 80, height: 80)
                        
                        VStack(alignment: .leading) {
                            Text(username.isEmpty ? "Deadhead" : username)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Button("Edit Username") {
                                newUsername = username
                                isEditingUsername = true
                            }
                            .font(.caption)
                            .foregroundColor(Color("AccentColor"))
                        }
                        .padding(.leading)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("APPEARANCE")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .onChange(of: darkModeEnabled) { _, newValue in
                            // This would update app-wide theme if we had that capability
                        }
                }
                
                Section(header: Text("PLAYBACK")) {
                    Picker("Streaming Quality", selection: $streamingQuality) {
                        Text("Low").tag("Low")
                        Text("Medium").tag("Medium")
                        Text("High").tag("High")
                    }
                }
                
                Section(header: Text("ABOUT")) {
                    NavigationLink(destination: AboutView()) {
                        Text("About JammyJam")
                    }
                    
                    Link(destination: URL(string: "https://archive.org/details/GratefulDead")!) {
                        HStack {
                            Text("Archive.org Grateful Dead")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/RelistenNet/relisten-ios")!) {
                        HStack {
                            Text("Inspired by Relisten")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("APP INFO")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Profile")
            .alert("Edit Username", isPresented: $isEditingUsername) {
                TextField("Username", text: $newUsername)
                
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    if !newUsername.isEmpty {
                        username = newUsername
                    }
                }
            } message: {
                Text("Enter your username")
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .center) {
                    Image(systemName: "music.note.house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("AccentColor"))
                        .padding(.bottom)
                    
                    Text("JammyJam")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Grateful Dead Live Show Streaming")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 30)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("About")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("JammyJam is a dedicated app for streaming Grateful Dead live shows from Archive.org. The app allows you to browse, search, and listen to thousands of live recordings from throughout the band's history.")
                        .padding(.bottom, 10)
                    
                    Text("All audio content is streamed directly from the Internet Archive's extensive collection of Grateful Dead recordings, which are available free of charge to the public.")
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Credits")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("All Grateful Dead recordings are sourced from Archive.org.")
                        .padding(.bottom, 5)
                    
                    Text("This app was inspired by the excellent Relisten iOS app.")
                        .padding(.bottom, 5)
                    
                    Text("JammyJam is not affiliated with or endorsed by the Grateful Dead, Archive.org, or Relisten.")
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
    }
} 