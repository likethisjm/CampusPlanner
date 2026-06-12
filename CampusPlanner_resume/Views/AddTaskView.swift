import SwiftUI
import UIKit
import UserNotifications

struct AddTaskView: View {
    @EnvironmentObject var manager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("CampusPlanner.DefaultNotifyDayBefore") private var defaultNotifyDayBefore: Bool = true
    @AppStorage("CampusPlanner.DefaultNotifyHour") private var defaultNotifyHour: Int = 9

    @State private var title = ""
    @State private var course = ""
    @State private var dueDate = Date()
    @State private var priority = 2
    @State private var category = TaskCategory.assignment
    @State private var memo = ""
    @State private var notifyDayBefore = true
    @State private var notifyHour = 9

    @State private var showAlert = false
    @State private var alertTitle = "오류"
    @State private var alertMsg = ""
    @State private var openSettingsOnAlert = false
    @State private var shouldDismissAfterAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("기본")) {
                    TextField("제목", text: $title)
                    TextField("과목명", text: $course)
                    DatePicker("마감일", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("분류")) {
                    Picker("카테고리", selection: $category) {
                        ForEach(TaskCategory.allCases) { item in
                            Label(item.rawValue, systemImage: item.iconName).tag(item)
                        }
                    }
                }

                Section(header: Text("우선순위")) {
                    Picker("우선순위", selection: $priority) {
                        Text("높음").tag(3)
                        Text("보통").tag(2)
                        Text("낮음").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("알림")) {
                    Toggle("하루 전 알림", isOn: $notifyDayBefore)
                    Stepper("알림 시각: \(notifyHour)시", value: $notifyHour, in: 0...23)
                }

                Section(header: Text("메모")) {
                    TextEditor(text: $memo)
                        .frame(height: 100)
                }
            }
            .navigationTitle("새 일정 추가")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") { save() }
                }
            }
            .onAppear {
                notifyDayBefore = defaultNotifyDayBefore
                notifyHour = defaultNotifyHour
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
                        secondaryButton: .cancel(Text("나중에")) {
                            dismissIfNeeded()
                        }
                    )
                } else {
                    return Alert(
                        title: Text(alertTitle),
                        message: Text(alertMsg),
                        dismissButton: .default(Text("확인")) {
                            dismissIfNeeded()
                        }
                    )
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCourse = course.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            showMessage(title: "오류", message: "제목을 입력하세요")
            return
        }

        guard !trimmedCourse.isEmpty else {
            showMessage(title: "오류", message: "과목명을 입력하세요")
            return
        }

        guard dueDate > Date() else {
            showMessage(title: "오류", message: "과거 날짜는 선택할 수 없습니다")
            return
        }

        let task = TaskItem(
            title: trimmedTitle,
            course: trimmedCourse,
            dueDate: dueDate,
            priority: priority,
            category: category.rawValue,
            memo: trimmedMemo.isEmpty ? nil : trimmedMemo,
            notifyDayBefore: notifyDayBefore,
            notifyHour: notifyHour
        )
        manager.add(task)
        finishAfterCheckingNotificationPermission()
    }

    private func finishAfterCheckingNotificationPermission() {
        NotificationManager.shared.checkPermission { status in
            if status == .denied {
                alertTitle = "알림 권한"
                alertMsg = "일정은 저장되었습니다. 알림을 받으려면 설정 앱에서 알림 권한을 허용하세요."
                openSettingsOnAlert = true
                shouldDismissAfterAlert = true
                showAlert = true
            } else {
                dismiss()
            }
        }
    }

    private func showMessage(title: String, message: String) {
        alertTitle = title
        alertMsg = message
        openSettingsOnAlert = false
        shouldDismissAfterAlert = false
        showAlert = true
    }

    private func dismissIfNeeded() {
        if shouldDismissAfterAlert {
            dismiss()
        }
        openSettingsOnAlert = false
        shouldDismissAfterAlert = false
    }
}

struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView().environmentObject(TaskManager())
    }
}
