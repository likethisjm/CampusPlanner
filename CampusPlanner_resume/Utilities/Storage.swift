import Foundation
import CoreData

final class Storage {
    static let shared = Storage()
    private let legacyKey = "CampusPlanner.Tasks.v1"

    private let stack: CoreDataStack

    private init() {
        stack = CoreDataStack()
        migrateIfNeeded()
    }

    func save(_ tasks: [TaskItem]) {
        let container = stack.container
        container.performBackgroundTask { ctx in
            let req = NSFetchRequest<NSManagedObject>(entityName: "CDTask")
            do {
                // Fetch existing objects and index by id for upsert
                let existing = try ctx.fetch(req)
                var existingById: [String: NSManagedObject] = [:]
                for obj in existing {
                    if let id = obj.value(forKey: "id") as? String {
                        existingById[id] = obj
                    }
                }

                // Upsert: update existing, insert new
                for t in tasks {
                    if let obj = existingById[t.id.uuidString] {
                        obj.setValue(t.title, forKey: "title")
                        obj.setValue(t.course, forKey: "course")
                        obj.setValue(t.dueDate, forKey: "dueDate")
                        obj.setValue(Int16(t.priority), forKey: "priority")
                        obj.setValue(t.category, forKey: "category")
                        obj.setValue(t.memo, forKey: "memo")
                        obj.setValue(t.isDone, forKey: "isDone")
                        obj.setValue(t.createdAt, forKey: "createdAt")
                        obj.setValue(t.notifyDayBefore, forKey: "notifyDayBefore")
                        obj.setValue(Int16(t.notifyHour), forKey: "notifyHour")
                        existingById.removeValue(forKey: t.id.uuidString)
                    } else {
                        let obj = NSEntityDescription.insertNewObject(forEntityName: "CDTask", into: ctx)
                        obj.setValue(t.id.uuidString, forKey: "id")
                        obj.setValue(t.title, forKey: "title")
                        obj.setValue(t.course, forKey: "course")
                        obj.setValue(t.dueDate, forKey: "dueDate")
                        obj.setValue(Int16(t.priority), forKey: "priority")
                        obj.setValue(t.category, forKey: "category")
                        obj.setValue(t.memo, forKey: "memo")
                        obj.setValue(t.isDone, forKey: "isDone")
                        obj.setValue(t.createdAt, forKey: "createdAt")
                        obj.setValue(t.notifyDayBefore, forKey: "notifyDayBefore")
                        obj.setValue(Int16(t.notifyHour), forKey: "notifyHour")
                    }
                }

                // Delete objects that are no longer present
                for (_, obj) in existingById {
                    ctx.delete(obj)
                }

                try ctx.save()
            } catch {
                print("[Storage] upsert/save error: \(error)")
            }
        }
    }

    func load() -> [TaskItem] {
        let ctx = stack.container.viewContext
        let req = NSFetchRequest<NSManagedObject>(entityName: "CDTask")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        do {
            let rows = try ctx.fetch(req)
            return rows.compactMap { obj in
                guard let idStr = obj.value(forKey: "id") as? String, let id = UUID(uuidString: idStr),
                      let title = obj.value(forKey: "title") as? String,
                      let course = obj.value(forKey: "course") as? String,
                      let dueDate = obj.value(forKey: "dueDate") as? Date,
                      let createdAt = obj.value(forKey: "createdAt") as? Date else { return nil }
                let priority = Int((obj.value(forKey: "priority") as? Int16) ?? 2)
                let category = (obj.value(forKey: "category") as? String) ?? TaskCategory.assignment.rawValue
                let memo = obj.value(forKey: "memo") as? String
                let isDone = (obj.value(forKey: "isDone") as? Bool) ?? false
                let notifyDayBefore = (obj.value(forKey: "notifyDayBefore") as? Bool) ?? true
                let notifyHour = Int((obj.value(forKey: "notifyHour") as? Int16) ?? 9)
                return TaskItem(id: id, title: title, course: course, dueDate: dueDate, priority: priority, category: category, memo: memo, isDone: isDone, createdAt: createdAt, notifyDayBefore: notifyDayBefore, notifyHour: notifyHour)
            }
        } catch {
            print("[Storage] load error: \(error)")
            return []
        }
    }

    private func migrateIfNeeded() {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: legacyKey) {
            do {
                let legacy = try JSONDecoder().decode([TaskItem].self, from: data)
                // save into CoreData
                save(legacy)
                ud.removeObject(forKey: legacyKey)
                print("[Storage] migrated \(legacy.count) tasks from UserDefaults to CoreData")
            } catch {
                print("[Storage] migration decode error: \(error)")
            }
        }
    }
}

// Simple Core Data stack with programmatic model
final class CoreDataStack {
    let container: NSPersistentContainer

    init() {
        let model = CoreDataStack.makeModel()
        container = NSPersistentContainer(name: "CampusPlannerModel", managedObjectModel: model)
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        container.loadPersistentStores { _, error in
            if let error { print("[CoreData] load error: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "CDTask"
        entity.managedObjectClassName = "NSManagedObject"

        func attr(_ name: String, _ type: NSAttributeType, isOptional: Bool = false) -> NSAttributeDescription {
            let a = NSAttributeDescription(); a.name = name; a.attributeType = type; a.isOptional = isOptional; return a
        }

        entity.properties = [
            attr("id", .stringAttributeType),
            attr("title", .stringAttributeType),
            attr("course", .stringAttributeType),
            attr("dueDate", .dateAttributeType),
            attr("priority", .integer16AttributeType),
            attr("category", .stringAttributeType, isOptional: true),
            attr("memo", .stringAttributeType, isOptional: true),
            attr("isDone", .booleanAttributeType),
            attr("createdAt", .dateAttributeType),
            attr("notifyDayBefore", .booleanAttributeType),
            attr("notifyHour", .integer16AttributeType)
        ]

        model.entities = [entity]
        return model
    }
}
