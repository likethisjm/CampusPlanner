import Foundation
import SwiftUI

struct TaskItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var course: String
    var dueDate: Date
    var priority: Int = 2 // 1 low, 2 normal, 3 high
    var category: String = "과제"
    var memo: String?
    var isDone: Bool = false
    var createdAt: Date = Date()
    var notifyDayBefore: Bool = true
    var notifyHour: Int = 9
}

enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case assignment = "과제"
    case exam = "시험"
    case personal = "개인"
    case appointment = "약속"
    case etc = "기타"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .assignment:  return "doc.text"
        case .exam:        return "pencil.and.list.clipboard"
        case .personal:    return "person"
        case .appointment: return "calendar"
        case .etc:         return "tray"
        }
    }

    var color: Color {
        switch self {
        case .assignment:  return .blue
        case .exam:        return .red
        case .personal:    return .purple
        case .appointment: return .orange
        case .etc:         return .gray
        }
    }

    // 단일 진입점 — 모든 곳에서 이걸 쓰면 중복 없음
    static func icon(for rawValue: String) -> String {
        TaskCategory(rawValue: rawValue)?.iconName ?? "tray"
    }

    static func color(for rawValue: String) -> Color {
        TaskCategory(rawValue: rawValue)?.color ?? .gray
    }
}

// 우선순위 색상도 한 곳에서 관리
extension Int {
    var priorityColor: Color {
        switch self {
        case 3: return .red
        case 2: return .orange
        default: return .blue
        }
    }

    var priorityLabel: String {
        switch self {
        case 3: return "높음"
        case 2: return "보통"
        default: return "낮음"
        }
    }
}
