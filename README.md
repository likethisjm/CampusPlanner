# 📚 CampusPlanner

![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=flat&logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-16.0+-000000?style=flat&logo=apple&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-15-147EFB?style=flat&logo=xcode&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-MVVM-blueviolet?style=flat)
![Storage](https://img.shields.io/badge/Storage-CoreData-blue?style=flat)

> 대학생을 위한 과제·시험 일정 통합 관리 iOS 앱

---

## 소개

캠퍼스 생활에서 흩어져 있는 과제, 시험, 수업 일정을 한 곳에서 관리할 수 있도록 만든 앱입니다.  
마감일 기반 정렬, 우선순위 구분, 완료 체크, 알림 예약까지 일반 캘린더 앱에서 아쉬웠던 기능들을 중심으로 구성했습니다.

SwiftUI와 MVVM 구조를 기반으로 하며, 저장은 CoreData를 사용했습니다. 스토리보드나 XIB는 사용하지 않았습니다.

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| 일정 등록 | 제목, 과목명, 마감일, 카테고리, 우선순위, 메모, 알림 설정 |
| 홈 화면 | 오늘 마감 일정 수, 전체 완료율, 기한 초과 항목 한눈에 확인 |
| 캘린더 뷰 | 날짜별 일정 시각화, 마감일 기준 정렬 |
| 통계 탭 | 카테고리별 진행 현황, 우선순위 분포, 최근 6주 등록 추이 |
| 검색 | 제목·과목·분류·메모 전체 검색, 필터 및 카테고리 칩 조합 |
| 알림 | UNUserNotification 기반, 마감 하루 전·당일 예약 |

---

## 프로젝트 구조

```
CampusPlanner/
├── CampusPlanner/
│   ├── CampusPlannerApp.swift       # 앱 진입점
│   ├── Models/
│   │   ├── Task.swift               # 데이터 모델
│   │   └── Category.swift
│   ├── ViewModels/
│   │   └── TaskManager.swift        # 비즈니스 로직, CoreData 관리
│   ├── Views/
│   │   ├── HomeView.swift           # 홈 탭
│   │   ├── TaskDetailView.swift     # 일정 상세/편집
│   │   ├── CalendarView.swift       # 캘린더 탭
│   │   ├── StatisticsView.swift     # 통계 탭
│   │   └── SettingsView.swift       # 설정
│   └── Utilities/
│       └── NotificationManager.swift
└── README.md
```

---

## 아키텍처

```
View  ──(이벤트)──▶  ViewModel  ──(CRUD)──▶  CoreData
  ◀──(State 바인딩)──              ◀──(변경 알림)──
```

- **View**: SwiftUI, `@State` / `@Binding` / `@EnvironmentObject`
- **ViewModel**: `TaskManager` — `@Published` 프로퍼티로 상태 관리
- **Model**: CoreData Entity + Swift 구조체 래핑

---

## 개발 환경

- Xcode 15
- Swift 5.9
- iOS 16.0+
- CoreData (로컬 저장)
- UNUserNotifications (로컬 알림)
