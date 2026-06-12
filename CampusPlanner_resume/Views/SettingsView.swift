import SwiftUI
import UserNotifications

// MARK: - StatisticsView (탭 2)

struct StatisticsView: View {
    @EnvironmentObject var manager: TaskManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    overallCard
                    categoryCard
                    priorityCard
                    weeklyCard
                }
                .padding()
            }
            .navigationTitle("통계")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }

    // MARK: 전체 현황

    private var overallCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("전체 현황", systemImage: "chart.bar.fill")
                .font(.headline)

            HStack(spacing: 12) {
                SummaryTile(label: "전체",    value: "\(manager.tasks.count)",        color: .blue)
                SummaryTile(label: "완료",    value: "\(manager.doneCount)",          color: .green)
                SummaryTile(label: "진행 중", value: "\(manager.remainingCount)",     color: .orange)
                SummaryTile(label: "기한 초과", value: "\(manager.overdueCount)",     color: .red)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("완료율")
                    Spacer()
                    Text("\(Int(manager.progress * 100))%")
                        .bold()
                }
                .font(.subheadline)
                ProgressView(value: manager.progress)
                    .tint(progressTint)
                    .scaleEffect(x: 1, y: 1.6, anchor: .center)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var progressTint: Color {
        let p = manager.progress
        if p < 0.3 { return .red }
        if p < 0.7 { return .orange }
        return .green
    }

    // MARK: 카테고리별

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("카테고리별 현황", systemImage: "folder.fill")
                .font(.headline)

            if manager.categoryDistribution.isEmpty {
                Text("등록된 일정이 없습니다")
                    .font(.subheadline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ForEach(manager.categoryDistribution, id: \.category) { item in
                    CategoryStatRow(
                        category: item.category,
                        total: item.total,
                        done: item.done
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: 우선순위별

    private var priorityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("우선순위별 미완료", systemImage: "exclamationmark.circle.fill")
                .font(.headline)

            let dist = manager.priorityDistribution
            if dist.isEmpty {
                Text("미완료 일정이 없습니다")
                    .font(.subheadline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                let maxVal = dist.map(\.count).max() ?? 1
                ForEach(dist, id: \.label) { item in
                    HStack(spacing: 10) {
                        Text(item.label)
                            .font(.caption).bold()
                            .frame(width: 32, alignment: .leading)
                        GeometryReader { geo in
                            let ratio = CGFloat(item.count) / CGFloat(maxVal)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(priorityBarColor(item.color))
                                .frame(width: geo.size.width * ratio)
                        }
                        .frame(height: 22)
                        Text("\(item.count)")
                            .font(.caption).foregroundColor(.secondary)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func priorityBarColor(_ c: PriorityColor) -> Color {
        switch c {
        case .high: return .red
        case .mid:  return .orange
        case .low:  return .blue
        }
    }

    // MARK: 주간 등록 추이

    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("주간 등록 추이 (최근 6주)", systemImage: "calendar")
                .font(.headline)

            let data = manager.weeklyRegisteredLast6
            let maxVal = data.map(\.count).max() ?? 1

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data, id: \.week) { item in
                    VStack(spacing: 4) {
                        Text("\(item.count)")
                            .font(.caption2)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(width: 28, height: maxVal > 0
                                   ? CGFloat(item.count) / CGFloat(maxVal) * 80
                                   : 4)
                        Text(item.week)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Sub-views

private struct SummaryTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3).bold().foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

private struct CategoryStatRow: View {
    let category: TaskCategory
    let total: Int
    let done: Int

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Label(category.rawValue, systemImage: category.iconName)
                    .font(.subheadline)
                Spacer()
                Text("\(done)/\(total)")
                    .font(.caption).foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(.systemBackground))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(category.color)
                        .frame(width: total > 0
                               ? geo.size.width * CGFloat(done) / CGFloat(total)
                               : 0,
                               height: 10)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - SettingsView (알림 설정)

struct SettingsView: View {
    @AppStorage("CampusPlanner.DefaultNotifyDayBefore") private var defaultNotifyDayBefore = true
    @AppStorage("CampusPlanner.DefaultNotifyHour")      private var defaultNotifyHour      = 9

    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingAlert = false
    @State private var alertMsg     = ""

    var body: some View {
        Form {
            Section(header: Text("알림 권한")) {
                HStack {
                    Text("상태")
                    Spacer()
                    Text(permissionText)
                        .foregroundColor(permissionColor)
                        .bold()
                }
                Button("권한 확인/요청") { checkOrRequest() }
            }

            Section(header: Text("기본 알림 설정")) {
                Toggle("하루 전 알림 기본 사용", isOn: $defaultNotifyDayBefore)
                Stepper("하루 전 알림 시각: \(defaultNotifyHour)시",
                        value: $defaultNotifyHour, in: 0...23)
            }

            Section {
                Button("설정 저장") {
                    alertMsg = "기본 알림 설정이 저장되었습니다"
                    showingAlert = true
                }
            }
        }
        .navigationTitle("설정")
        .onAppear { NotificationManager.shared.checkPermission { permissionStatus = $0 } }
        .alert("안내", isPresented: $showingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMsg)
        }
    }

    private var permissionText: String {
        switch permissionStatus {
        case .authorized:    return "허용됨"
        case .denied:        return "거부됨"
        case .notDetermined: return "미결정"
        case .provisional:   return "임시 허용"
        default:             return "알 수 없음"
        }
    }

    private var permissionColor: Color {
        switch permissionStatus {
        case .authorized:    return .green
        case .denied:        return .red
        default:             return .orange
        }
    }

    private func checkOrRequest() {
        NotificationManager.shared.checkPermission { status in
            permissionStatus = status
            switch status {
            case .notDetermined:
                NotificationManager.shared.requestPermission { _ in
                    NotificationManager.shared.checkPermission { permissionStatus = $0 }
                }
            case .denied:
                alertMsg = "알림 권한이 거부되어 있습니다. 설정 앱에서 권한을 허용하세요."
                showingAlert = true
            default:
                alertMsg = "이미 권한이 허용되어 있습니다."
                showingAlert = true
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View { SettingsView() }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView().environmentObject(TaskManager())
    }
}
