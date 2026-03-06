import SwiftUI

struct ContentView: View {
    @Environment(LocationManager.self) private var locationManager
    @State private var showDiscover = false
    @State private var showSaved = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            MapView()
                .navigationDestination(for: Place.self) { place in
                    PlaceDetailView(place: place)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showDiscover = true
                        } label: {
                            Image(systemName: "square.grid.2x2")
                        }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            showSaved = true
                        } label: {
                            Image(systemName: "bookmark")
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
        .tint(AtlasColors.accent)
        .sheet(isPresented: $showDiscover) {
            DiscoverView()
        }
        .sheet(isPresented: $showSaved) {
            CollectionsView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }
}
