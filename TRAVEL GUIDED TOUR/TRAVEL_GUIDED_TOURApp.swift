//
//  TRAVEL_GUIDED_TOURApp.swift
//  TRAVEL GUIDED TOUR
//
//  Created by Edward Yung on 3/4/26.
//

import SwiftUI

@main
struct TRAVEL_GUIDED_TOURApp: App {
    @State private var dataService = DataService()
    @State private var collectionStore = CollectionStore()
    @State private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataService)
                .environment(collectionStore)
                .environment(locationManager)
        }
    }
}
