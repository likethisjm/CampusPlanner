import Foundation
import Combine

final class TaskManager: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []

    init() { load() }

    // MARK: - CRUD

    func add(_ task: TaskItem) {
        tasks.append(task)
        sortAndSave()
        NotificationManager.shared.scheduleNotifications(for: task)
    }

    func update(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        sortAndSave()
        NotificationManager.shared.scheduleNotifications(for: task)
    }

    func delete(_ task: TaskItem) {
        NotificationManager.shared.cancelNotifications(for: task)
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func toggleDone(_ task: TaskItem) {
        setDone(id: task.id, isDone: !task.isDone)
    }

    func setDone(id: UUID, isDone: Bool) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isDone = isDone
        let updated = tasks[index]
        isDone
            ? NotificationManager.shared.cancelNotifications(for: updated)
            : NotificationManager.shared.scheduleNotifications(for: updated)
        sortAndSave()
    }

    // MARK: - Persistence

    private func sortAndSave() {
        tasks.sort(by: taskSortRule)
        save()
    }

    func save() { Storage.shared.save(tasks) }

    func load() {
        tasks = Storage.shared.load().sorted(by: taskSortRule)
    }

    // MARK: - Sort

    private func taskSortRule(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        if lhs.isDone != rhs.isDone   { return !lhs.isDone }
        if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
        if lhs.dueDate  != rhs.dueDate  { return lhs.dueDate  < rhs.dueDate  }
        return lhs.createdAt < rhs.createdAt
    }

    // MARK: - Basic Stats

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(doneCount) / Double(tasks.count)
    }

    var remainingCount: Int { tasks.filter { !$0.isDone }.count }
    var doneCount:      Int { tasks.filter {  $0.isDone }.count }

    var highPriorityCount: Int {
        tasks.filter { !$0.isDone && $0.priority == 3 }.count
    }

    var overdueCount: Int {
        let now = Date()
        return tasks.filter { !$0.isDone && $0.dueDate < now }.count
    }

    // MARK: - Filtered Lists

    var todayTasks: [TaskItem] {
        tasks.filter { !$0.isDone && Calendar.current.isDateInToday($0.dueDate) }
            .sorted(by: taskSortRule)
    }

    var upcomingTasks: [TaskItem] {
        let now = Date()
        return tasks.filter { !$0.isDone && $0.dueDate >= now }
            .sorted(by: taskSortRule)
            .prefix(3)
            .map { $0 }
    }

    func count(for category: TaskCategory) -> Int {
        tasks.filter { !$0.isDone && $0.category == category.rawValue }.count
    }

    // MARK: - Statistics

    /// 카테고리별 (전체, 완료 포함)
    var categoryDistribution: [(category: TaskCategory, total: Int, done: Int)] {
        TaskCategory.allCases.compactMap { cat in
            let total = tasks.filter { $0.category == cat.rawValue }.count
            guard total > 0 else { return nil }
            let done  = tasks.filter { $0.category == cat.rawValue && $0.isDone }.count
            return (cat, total, done)
        }
    }

    /// 우선순위별 미완료 수
    var priorityDistribution: [(label: String, count: Int, color: PriorityColor)] {
        [
            ("높음", tasks.filter { !$0.isDone && $0.priority == 3 }.count, .high),
            ("보통", tasks.filter { !$0.isDone && $0.priority == 2 }.count, .mid),
            ("낮음", tasks.filter { !$0.isDone && $0.priority == 1 }.count, .low)
        ].filter { $0.count > 0 }
    }

    /// 이번 주 일별 완료 수 (0=일 … 6=토)
    var weeklyDoneByDay: [Int] {
        var counts = Array(repeating: 0, count: 7)
        let cal = Calendar.current
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else { return counts }
        for task in tasks where task.isDone {
            let diff = cal.dateComponents([.day], from: weekStart, to: task.dueDate).day ?? -1
            if (0..<7).contains(diff) { counts[diff] += 1 }
        }
        return counts
    }

    /// 전체 기간 주차별 등록 추이 (최근 6주)
    var weeklyRegisteredLast6: [(week: String, count: Int)] {
        let cal = Calendar.current
        let now = Date()
        return (0..<6).reversed().map { offset -> (String, Int) in
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -offset, to: now),
                  let weekEnd   = cal.date(byAdding: .day, value: 7, to: weekStart) else { return ("", 0) }
            let count = tasks.filter { $0.createdAt >= weekStart && $0.createdAt < weekEnd }.count
            let label = cal.component(.weekOfYear, from: weekStart)
            return ("\(label)주", count)
        }
    }
}

enum PriorityColor { case high, mid, low }
