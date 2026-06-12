# CampusPlanner

대학생이 여러 과목의 과제와 시험 일정을 한 곳에서 관리할 수 있도록 만든 iOS 앱이다. 일반 캘린더 앱에서 아쉬웠던 완료 체크, 우선순위 구분, 마감 알림 기능을 중심으로 구성했다.

SwiftUI와 MVVM 구조를 기반으로 하며, 저장은 CoreData를 사용했다. 스토리보드나 XIB는 사용하지 않았다.

## 주요 기능

일정 등록 시 제목, 과목명, 마감일, 카테고리(과제/시험/개인/약속/기타), 우선순위(높음/보통/낮음), 메모, 알림 시각을 설정할 수 있다. 등록된 일정은 홈 화면에서 우선순위와 마감일 기준으로 정렬되며, 완료 처리 시 진행률이 자동으로 업데이트된다.

홈 대시보드에서는 오늘 마감 일정 수, 전체 완료율, 기한 초과 항목을 한눈에 확인할 수 있고, 통계 탭에서는 카테고리별 진행 현황과 우선순위 분포, 최근 6주 등록 추이를 볼 수 있다.

검색은 제목, 과목, 분류, 메모 전체를 대상으로 하며, 전체/진행/완료/중요/오늘 필터와 카테고리 칩을 조합해서 쓸 수 있다.

알림은 UNUserNotification 기반으로 마감 하루 전 또는 당일에 예약되며, 완료 처리 시 자동으로 취소된다. 권한이 거부된 경우 설정 앱으로 안내한다.

## 실행 방법

Xcode에서 `CampusPlanner.xcodeproj`를 열고 iPhone 시뮬레이터로 실행하면 된다. 별도 설정은 필요 없다.

## 구조

```
CampusPlanner/
 ├── Models/          TaskItem, TaskCategory
 ├── ViewModels/      TaskManager (CRUD, 정렬, 통계)
 ├── Views/           HomeView, AddTaskView, TaskDetailView, StatisticsView
 └── Utilities/       Storage (CoreData), NotificationManager
```
