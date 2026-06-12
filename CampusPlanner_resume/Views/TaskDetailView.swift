import SwiftUI
import UIKit

struct TaskDetailView: View {
    @EnvironmentObject var manager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State var task: TaskItem
    @State private var showingEdit        = false
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title).font(.title2).bold()
                        Text(task.course).foregroundColor(.secondary)
                    }
                    Spacer()
                    priorityBadge
                }

                Divider()

                Label(task.dueDate.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "calendar")
                Label(task.category,
                      systemImage: TaskCategory.icon(for: task.category))
                    .foregroundColor(TaskCategory.color(for: task.category))

                if let memo = task.memo, !memo.isEmpty {
                    Divider()
                    Text("메모").font(.headline)
                    Text(memo).frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                HStack {
                    Text("하루 전 알림")
                    Spacer()
                    Text(task.notifyDayBefore ? "예 (\(task.notifyHour)시)" : "아니오")
                        .foregroundColor(.secondary)
                }
            }

            Toggle("완료 처리", isOn: Binding(
                get: { task.isDone },
                set: { newValue in
                    task.isDone = newValue
                    manager.setDone(id: task.id, isDone: newValue)
                }
            ))
            .padding(.top, 8)

            Spacer()

            HStack {
                Button("수정하기") { showingEdit = true }
                    .buttonStyle(.borderedProminent)
                Spacer()
                Button("삭제하기") { showingDeleteAlert = true }
                    .buttonStyle(.bordered)
                    .tint(.red)
            }
        }
        .padding()
        .navigationTitle("일정 상세")
        .sheet(isPresented: $showingEdit) {
            EditTaskView(task: task).environmentObject(manager)
        }
        .alert("삭제 확인", isPresented: $showingDeleteAlert) {
            Button("삭제", role: .destructive) {
                manager.delete(task)
                dismiss()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("이 일정을 삭제하시겠습니까?")
        }
        .onReceive(manager.$tasks) { _ in
            if let updated = manager.tasks.first(where: { $0.id == task.id }) {
                task = updated
            }
        }
    }

    private var priorityBadge: some View {
        Text(task.priority.priorityLabel)
            .font(.caption).bold()
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(task.priority.priorityColor.opacity(0.16))
            .foregroundColor(task.priority.priorityColor)
            .cornerRadius(10)
    }
}

// MARK: - EditTaskView

struct EditTaskView: View {
    @EnvironmentObject var manager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State var task: TaskItem
    @State private var showAlert             = false
    @State private var alertTitle            = "오류"
    @State private var alertMsg              = ""
    @State private var openSettingsOnAlert   = false
    @State private var shouldDismissAfterAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("기본")) {
                    TextField("제목",   text: $task.title)
                    TextField("과목명", text: $task.course)
                    DatePicker("마감일", selection: $task.dueDate,
                               displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("분류")) {
                    Picker("카테고리", selection: Binding(
                        get: { TaskCategory(rawValue: task.category) ?? .assignment },
                        set: { task.category = $0.rawValue }
                    )) {
                        ForEach(TaskCategory.allCases) { item in
                            Label(item.rawValue, systemImage: item.iconName).tag(item)
                        }
                    }
                }

                Section(header: Text("우선순위")) {
                    Picker("우선순위", selection: $task.priority) {
                        Text("높음").tag(3)
                        Text("보통").tag(2)
                        Text("낮음").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("알림")) {
                    Toggle("하루 전 알림", isOn: $task.notifyDayBefore)
                    Stepper("알림 시각: \(task.notifyHour)시",
                            value: $task.notifyHour, in: 0...23)
                }

                Section(header: Text("메모")) {
                    TextEditor(text: Binding($task.memo, replacingNilWith: ""))
                        .frame(height: 100)
                }
            }
            .navigationTitle("일정 수정")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") { save() }
                }
            }
            .alert(isPresented: $showAlert) {
                if openSettingsOnAlert {
                    return Alert(
                        title: Text(alertTitle),
                        message: Text(alertMsg),
                        primaryButton: .default(Text("설정 열기")) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                            dismissIfNeeded()
                        },
                        secondaryButton: .cancel(Text("나중에")) { dismissIfNeeded() }
                    )
                } else {
                    return Alert(
                        title: Text(alertTitle),
                        message: Text(alertMsg),
                        dismissButton: .default(Text("확인")) { dismissIfNeeded() }
                    )
                }
            }
        }
    }

    private func save() {
        let t = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = task.course.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !t.isEmpty else { return showMessage(title: "오류", message: "제목을 입력하세요") }
        guard !c.isEmpty else { return showMessage(title: "오류", message: "과목명을 입력하세요") }
        guard task.dueDate > Date() || task.isDone else {
            return showMessage(title: "오류", message: "완료되지 않은 일정은 과거 날짜로 저장할 수 없습니다")
        }

        task.title  = t
        task.course = c
        let m = task.memo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        task.memo = m.isEmpty ? nil : m
        manager.update(task)
        finishAfterCheckingNotificationPermission()
    }

    private func finishAfterCheckingNotificationPermission() {
        NotificationManager.shared.checkPermission { status in
            if status == .denied && !task.isDone {
                alertTitle = "알림 권한"
                alertMsg   = "일정은 저장되었습니다. 알림을 받으려면 설정 앱에서 알림 권한을 허용하세요."
                openSettingsOnAlert     = true
                shouldDismissAfterAlert = true
                showAlert = true
            } else {
                dismiss()
            }
        }
    }

    private func showMessage(title: String, message: String) {
        alertTitle = title; alertMsg = message
        openSettingsOnAlert = false; shouldDismissAfterAlert = false
        showAlert = true
    }

    private func dismissIfNeeded() {
        if shouldDismissAfterAlert { dismiss() }
        openSettingsOnAlert = false; shouldDismissAfterAlert = false
    }
}

extension Binding where Value == String? {
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }
}

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TaskDetailView(task: TaskItem(title: "샘플", course: "iOS",
                                     dueDate: Date().addingTimeInterval(3600)))
            .environmentObject(TaskManager())
    }
}
