//
//  DataManager.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var tasks: [Task] = []
    @Published var focusSessions: [FocusSession] = []
    @Published var checkIns: [CheckIn] = []
    @Published var tags: [Tag] = []
    @Published var temporaryIdeas: [TemporaryIdea] = []
    
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults Keys
    private enum Keys {
        static let tasks = "SavedTasks"
        static let focusSessions = "SavedFocusSessions"
        static let checkIns = "SavedCheckIns"
        static let tags = "SavedTags"
        static let temporaryIdeas = "SavedTemporaryIdeas"
    }
    
    private init() {
        loadData()
    }
    
    // MARK: - Data Loading
    private func loadData() {
        loadTasks()
        loadFocusSessions()
        loadCheckIns()
        loadTags()
        loadTemporaryIdeas()
    }
    
    private func loadTasks() {
        if let data = userDefaults.data(forKey: Keys.tasks),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decodedTasks
        }
    }
    
    private func loadFocusSessions() {
        if let data = userDefaults.data(forKey: Keys.focusSessions),
           let decodedSessions = try? JSONDecoder().decode([FocusSession].self, from: data) {
            focusSessions = decodedSessions.sorted { $0.startTime > $1.startTime }
        }
    }
    
    private func loadCheckIns() {
        if let data = userDefaults.data(forKey: Keys.checkIns),
           let decodedCheckIns = try? JSONDecoder().decode([CheckIn].self, from: data) {
            checkIns = decodedCheckIns
        }
    }
    
    private func loadTags() {
        if let data = userDefaults.data(forKey: Keys.tags),
           let decodedTags = try? JSONDecoder().decode([Tag].self, from: data) {
            tags = decodedTags
        }
    }
    
    private func loadTemporaryIdeas() {
        if let data = userDefaults.data(forKey: Keys.temporaryIdeas),
           let decodedIdeas = try? JSONDecoder().decode([TemporaryIdea].self, from: data) {
            temporaryIdeas = decodedIdeas.sorted { $0.createdDate > $1.createdDate }
        }
    }
    
    // MARK: - Data Saving
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: Keys.tasks)
        }
    }
    
    private func saveFocusSessions() {
        if let encoded = try? JSONEncoder().encode(focusSessions) {
            userDefaults.set(encoded, forKey: Keys.focusSessions)
        }
    }
    
    private func saveCheckIns() {
        if let encoded = try? JSONEncoder().encode(checkIns) {
            userDefaults.set(encoded, forKey: Keys.checkIns)
        }
    }
    
    private func saveTags() {
        if let encoded = try? JSONEncoder().encode(tags) {
            userDefaults.set(encoded, forKey: Keys.tags)
        }
    }
    
    private func saveTemporaryIdeas() {
        if let encoded = try? JSONEncoder().encode(temporaryIdeas) {
            userDefaults.set(encoded, forKey: Keys.temporaryIdeas)
        }
    }
    
    // MARK: - Task Operations
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    // MARK: - Focus Session Operations
    func addFocusSession(_ session: FocusSession) {
        focusSessions.insert(session, at: 0)
        saveFocusSessions()
    }
    
    func updateFocusSession(_ session: FocusSession) {
        if let index = focusSessions.firstIndex(where: { $0.id == session.id }) {
            focusSessions[index] = session
            saveFocusSessions()
        }
    }
    
    func deleteFocusSession(_ session: FocusSession) {
        focusSessions.removeAll { $0.id == session.id }
        saveFocusSessions()
    }
    
    // MARK: - Check-in Operations
    func addCheckIn(_ checkIn: CheckIn) {
        checkIns.append(checkIn)
        saveCheckIns()
    }
    
    func updateCheckIn(_ checkIn: CheckIn) {
        if let index = checkIns.firstIndex(where: { $0.id == checkIn.id }) {
            checkIns[index] = checkIn
            saveCheckIns()
        }
    }
    
    func deleteCheckIn(_ checkIn: CheckIn) {
        checkIns.removeAll { $0.id == checkIn.id }
        saveCheckIns()
    }
    
    func performCheckIn(for checkIn: CheckIn) {
        if let index = checkIns.firstIndex(where: { $0.id == checkIn.id }) {
            checkIns[index].checkIn()
            saveCheckIns()
        }
    }
    
    func undoCheckIn(for checkIn: CheckIn) {
        if let index = checkIns.firstIndex(where: { $0.id == checkIn.id }) {
            checkIns[index].uncheckIn()
            saveCheckIns()
        }
    }
    
    // MARK: - Tag Operations
    func addTag(_ tag: Tag) {
        if !tags.contains(where: { $0.name == tag.name }) {
            tags.append(tag)
            saveTags()
        }
    }
    
    func deleteTag(_ tag: Tag) {
        tags.removeAll { $0.id == tag.id }
        saveTags()
    }
    
    func incrementTagUsage(_ tagName: String) {
        if let index = tags.firstIndex(where: { $0.name == tagName }) {
            tags[index].incrementUsage()
            saveTags()
        }
    }
    
    // MARK: - Temporary Ideas Operations
    func addTemporaryIdea(_ idea: TemporaryIdea) {
        temporaryIdeas.insert(idea, at: 0)
        saveTemporaryIdeas()
    }
    
    func deleteTemporaryIdea(_ idea: TemporaryIdea) {
        temporaryIdeas.removeAll { $0.id == idea.id }
        saveTemporaryIdeas()
    }
    
    func archiveTemporaryIdea(_ idea: TemporaryIdea) {
        if let index = temporaryIdeas.firstIndex(where: { $0.id == idea.id }) {
            temporaryIdeas[index].isArchived = true
            saveTemporaryIdeas()
        }
    }
    
    // MARK: - Helper Methods
    func getTasksForDate(_ date: Date) -> [Task] {
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: date)
        }
    }
    
    func getActiveCheckIns() -> [CheckIn] {
        return checkIns.filter { $0.isActive }
    }
    
    func getUnarchiveIdeas() -> [TemporaryIdea] {
        return temporaryIdeas.filter { !$0.isArchived }
    }
    
    // MARK: - Today Statistics
    func getTodayFocusSessionsCount() -> Int {
        let today = Date()
        return focusSessions.filter { session in
            Calendar.current.isDate(session.startTime, inSameDayAs: today)
        }.count
    }
    
    func getTodayTasksCount() -> Int {
        let today = Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: today) && !task.isCompleted
        }.count
    }
    
    func getTodayCheckInsCount() -> Int {
        return checkIns.filter { $0.isActive }.count
    }
}
