import SwiftUI

struct HomeView: View {
    @EnvironmentObject var manager: TaskManager
    @State private var showingAdd       = false
    @State private var searchText       = ""
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedCategory = "전체"
    @State private var pendingDelete: TaskItem?
    @State private var showingDeleteAlert = false

    // Toast
    @State private var toastMessage = ""
    @State private var showToast    = false

    private var filteredTasks: [TaskItem] {
        manager.tasks.filter { task in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:       matchesFilter = true
            case .remaining: matchesFilter = !task.isDone
            case .done:      matchesFilter =  task.isDone
            case .high:      matchesFilter = !task.isDone && task.priority == 3
            case .today:     matchesFilter = !task.isDone && Calendar.current.isDateInToday(task.dueDate)
            }
            guard matchesFilter else { return false }
            guard selectedCategory == "전체" || task.category == selectedCategory else { return false }

            let kw = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !kw.isEmpty else { return true }
            return task.title.localizedCaseInsensitiveContains(kw)
                || task.course.localizedCaseInsensitiveContains(kw)
                || task.category.localizedCaseInsensitiveContains(kw)
                || (task.memo ?? "").localizedCaseInsensitiveContains(kw)
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 14) {
                        dashboardView
                        categoryChips

                        Picker("필터", selection: $selectedFilter) {
                            ForEach(TaskFilter.allCases) { f in
                                Text(f.title).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if filteredTasks.isEmpty {
                            emptyView
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredTasks) { task in
                                    NavigationLink(destination: TaskDetailView(task: task)) {
                                        TaskCardView(task: task)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(task.isDone ? "진행으로 변경" : "완료 처리") {
                                            manager.setDone(id: task.id, isDone: !task.isDone)
                                            triggerToast(task.isDone ? "진행 중으로 변경했습니다" : "완료 처리했습니다 ✓")
                                        }
                                        Button(role: .destructive) {
                                            pendingDelete = task
                                            showingDeleteAlert = true
                                        } label: { Text("삭제") }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.bottom, 60) // FAB 여백
                }

                // Toast
                if showToast {
                    ToastView(message: toastMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 80)
                        .zIndex(10)
                }
            }
            .navigationTitle("Campus Planner")
            .searchable(text: $searchText, prompt: "제목, 과목, 분류, 메모 검색")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddTaskView().environmentObject(manager)
            }
            .alert("삭제 확인", isPresented: $showingDeleteAlert) {
                Button("삭제", role: .destructive) {
                    if let task = pendingDelete {
                        manager.delete(task)
                        triggerToast("일정을 삭제했습니다")
                    }
                    pendingDelete = nil
                }
                Button("취소", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("선택한 일정을 삭제하시겠습니까?")
            }
            .animation(.easeInOut(duration: 0.25), value: showToast)
        }
    }

    // MARK: - Toast

    private func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showToast = false }
        }
    }

    // MARK: - Dashboard

    private var dashboardView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("오늘의 일정")
                        .font(.headline)
                    Text(manager.todayTasks.isEmpty
                         ? "오늘 마감 일정이 없습니다"
                         : "오늘 마감 \(manager.todayTasks.count)개")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(Int(manager.progress * 100))%")
                    .font(.system(size: 32, weight: .bold))
            }

            ProgressView(value: manager.progress)
                .tint(progressTint)

            HStack(spacing: 10) {
                StatBox(title: "남은 일정",  value: "\(manager.remainingCount)",   systemImage: "calendar",                    tint: .blue)
                StatBox(title: "높은 우선",  value: "\(manager.highPriorityCount)", systemImage: "exclamationmark.circle",       tint: .red)
                StatBox(title: "기한 초과",  value: "\(manager.overdueCount)",      systemImage: "clock.badge.exclamationmark", tint: .orange)
            }

            if !manager.upcomingTasks.isEmpty {
                Divider()
                Text("다가오는 일정")
                    .font(.subheadline).bold()
                ForEach(manager.upcomingTasks) { task in
                    HStack {
                        Image(systemName: TaskCategory.icon(for: task.category))
                            .foregroundColor(TaskCategory.color(for: task.category))
                        Text(task.title).lineLimit(1)
                        Spacer()
                        Text(task.dueDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(18)
        .padding(.horizontal)
    }

    private var progressTint: Color {
        let p = manager.progress
        if p < 0.3 { return .red }
        if p < 0.7 { return .orange }
        return .green
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "전체", count: manager.remainingCount,
                             isSelected: selectedCategory == "전체", tint: .accentColor) {
                    selectedCategory = "전체"
                }
                ForEach(TaskCategory.allCases) { cat in
                    CategoryChip(title: cat.rawValue, count: manager.count(for: cat),
                                 isSelected: selectedCategory == cat.rawValue, tint: cat.color) {
                        selectedCategory = cat.rawValue
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "표시할 일정이 없습니다" : "검색 결과가 없습니다")
                .font(.headline)
            Text(searchText.isEmpty
                 ? "오른쪽 위 + 버튼으로 새 일정을 추가하세요."
                 : "다른 검색어나 필터를 사용해보세요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding()
    }
}

// MARK: - TaskFilter

private enum TaskFilter: String, CaseIterable, Identifiable {
    case all, remaining, done, high, today
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all:       return "전체"
        case .remaining: return "진행"
        case .done:      return "완료"
        case .high:      return "중요"
        case .today:     return "오늘"
        }
    }
}

// MARK: - Sub-views

private struct StatBox: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundColor(tint)
            Text(value).font(.headline)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

private struct CategoryChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color(.systemBackground).opacity(0.7))
                    .cornerRadius(6)
            }
            .font(.caption)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(isSelected ? tint.opacity(0.18) : Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? tint.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TaskCardView: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 12) {
            // 카테고리 아이콘 — 단일 진입점 사용
            VStack(spacing: 6) {
                Image(systemName: task.isDone
                      ? "checkmark.circle.fill"
                      : TaskCategory.icon(for: task.category))
                    .font(.title3)
                    .foregroundColor(task.isDone ? .green : TaskCategory.color(for: task.category))
                Text(task.category)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 52)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isDone)
                        .lineLimit(1)
                    if task.priority == 3 && !task.isDone {
                        Text("중요")
                            .font(.caption2).bold()
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.red.opacity(0.14))
                            .foregroundColor(.red)
                            .cornerRadius(6)
                    }
                }
                Text(task.course)
                    .font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                if let memo = task.memo, !memo.isEmpty {
                    Text(memo).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(task.dueDate, style: .date)
                Text(task.dueDate, style: .time)
                    .font(.caption).foregroundColor(.secondary)
                // 기한 초과 배지
                if !task.isDone && task.dueDate < Date() {
                    Text("기한 초과")
                        .font(.caption2).bold()
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(5)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(task.isDone ? Color(.systemBackground) : Color(.secondarySystemBackground))
        .cornerRadius(16)
        .opacity(task.isDone ? 0.6 : 1.0)
    }
}

struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.subheadline).bold()
            .foregroundColor(.white)
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(Color.black.opacity(0.78))
            .cornerRadius(20)
            .shadow(radius: 6)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(TaskManager())
    }
}
