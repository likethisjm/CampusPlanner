import SwiftUI

@main
struct CampusPlannerApp: App {
    @StateObject private var manager = TaskManager()

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("홈", systemImage: "house.fill")
                    }
                    .environmentObject(manager)

                StatisticsView()
                    .tabItem {
                        Label("통계", systemImage: "chart.bar.fill")
                    }
                    .environmentObject(manager)
            }
        }
    }
}
