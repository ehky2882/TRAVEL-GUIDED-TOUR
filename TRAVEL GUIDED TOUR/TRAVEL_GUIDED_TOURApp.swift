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
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            if isLoading {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                isLoading = false
                            }
                        }
                    }
            } else {
                ContentView()
                    .environment(dataService)
                    .environment(collectionStore)
                    .environment(locationManager)
            }
        }
    }
}
