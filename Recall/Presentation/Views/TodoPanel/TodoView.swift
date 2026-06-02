//
//  TodoView.swift
//  Recall
//
//  Created by twixx  on 16/05/26.
//

import SwiftUI

struct TodoView: View {
    var viewModel: TodoViewModel

    // For adding a new task
    @State private var isAddingTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskTime = "All Day"
    @State private var newTaskColor = "Purple"

    private let availableColorNames = ["Purple", "Blue", "Green", "Red", "Teal"]

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.hasAccess {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "calendar.badge.key")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Calendar & Reminders Access Required")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Recall requires permission to read and manage tasks.")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    Button(action: {
                        viewModel.requestAccess()
                    }) {
                        Text("Grant Access")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 0) {
                    // MARK: - Date Strip Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(monthYearString.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                            .tracking(1)

                        HStack(spacing: 6) {
                            ForEach(weekDays, id: \.self) { date in
                                let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
                                let dayNumber = String(Calendar.current.component(.day, from: date))
                                let isToday = Calendar.current.isDateInToday(date)

                                VStack(spacing: 2) {
                                    Text(dayNameAbbreviation(for: date))
                                        .font(.system(size: 7, weight: .semibold, design: .rounded))
                                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .white.opacity(0.2))

                                    Text(dayNumber)
                                        .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(isSelected ? Color.black : (isToday ? Color.white : Color.white.opacity(0.4)))
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(isSelected ? Color.white : (isToday ? Color.white.opacity(0.12) : Color.clear))
                                        )
                                }
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        viewModel.selectedDate = date
                                        viewModel.loadItems()
                                    }
                                }
                            }
                        }

                        HStack(spacing: 4) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.39, green: 0.40, blue: 0.95),
                                            Color(red: 0.55, green: 0.36, blue: 0.96)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 5, height: 5)

                            Text(selectedDayInfoString)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 12)

                    Divider()
                        .overlay(.white.opacity(0.06))
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 8)

                    // MARK: - Event Cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Loading schedule...")
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                                .frame(width: 140, height: 100)
                            } else if viewModel.eventsAndReminders.isEmpty {
                                VStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white.opacity(0.15))
                                    Text("All caught up!")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.2))
                                    Text("No tasks for today")
                                        .font(.system(size: 8, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.15))
                                }
                                .frame(width: 140, height: 100)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(.white.opacity(0.01))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(.white.opacity(0.03), lineWidth: 0.5)
                                )
                            } else {
                                ForEach(viewModel.eventsAndReminders) { event in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(timeRangeString(for: event))
                                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                                .foregroundStyle(.white.opacity(0.35))
                                            
                                            Spacer()
                                            
                                            // Delete button
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                    deleteTodo(event)
                                                }
                                            }) {
                                                Image(systemName: "trash.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundStyle(.white.opacity(0.25))
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        Text(event.title)
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(event.isCompleted ? .white.opacity(0.35) : .white.opacity(0.9))
                                            .strikethrough(event.isCompleted, color: .white.opacity(0.35))
                                            .lineLimit(2)

                                        Spacer()

                                        // Completion checkbox or event indicator
                                        HStack {
                                            Spacer()
                                            
                                            if event.isReminder {
                                                Button(action: {
                                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                        toggleTodoCompletion(event)
                                                    }
                                                }) {
                                                    Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundStyle(event.isCompleted ? Color.green : .white.opacity(0.4))
                                                }
                                                .buttonStyle(.plain)
                                            } else {
                                                Image(systemName: "calendar")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(.white.opacity(0.25))
                                            }
                                        }
                                    }
                                    .padding(8)
                                    .frame(width: 140, height: 100)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(event.isCompleted ? .white.opacity(0.01) : .white.opacity(0.04))
                                    )
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(
                                                LinearGradient(
                                                    colors: [event.color, event.color.opacity(0.5)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(width: 3)
                                            .padding(.vertical, 6)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(.white.opacity(event.isCompleted ? 0.03 : 0.06), lineWidth: 0.5)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }

                            // Add Task Card
                            addTaskCard
                        }
                        .padding(.horizontal, 10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if viewModel.hasAccess {
                viewModel.loadItems()
            }
        }
    }

    // MARK: - Add Task Card
    private var addTaskCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !isAddingTask {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isAddingTask = true
                        newTaskTitle = ""
                        newTaskTime = "All Day"
                        newTaskColor = "Purple"
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.35))
                        Text("Add Task")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Task title...", text: $newTaskTitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(4)
                        .onSubmit {
                            saveNewTodo()
                        }

                    TextField("Time (e.g. 10:00 AM)", text: $newTaskTime)
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(4)

                    HStack(spacing: 4) {
                        ForEach(availableColorNames, id: \.self) { colorName in
                            Circle()
                                .fill(colorForName(colorName))
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: newTaskColor == colorName ? 1 : 0)
                                )
                                .onTapGesture {
                                    newTaskColor = colorName
                                }
                        }
                        Spacer()
                    }
                    
                    HStack(spacing: 6) {
                        Button(action: {
                            withAnimation { isAddingTask = false }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(action: {
                            saveNewTodo()
                        }) {
                            Text("Save")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white)
                                .cornerRadius(3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(8)
        .frame(width: 140, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isAddingTask ? Color.white.opacity(0.03) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isAddingTask ? Color.white.opacity(0.12) : Color.white.opacity(0.15),
                    style: isAddingTask ? StrokeStyle(lineWidth: 0.5) : StrokeStyle(lineWidth: 1, dash: [3])
                )
        )
    }

    // MARK: - Date Helpers
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (-3...3).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate)
    }

    private var selectedDayInfoString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: viewModel.selectedDate)
    }

    private func dayNameAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(3)).uppercased()
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "Purple": return Color(red: 0.55, green: 0.36, blue: 0.96)
        case "Blue": return Color(red: 0.23, green: 0.51, blue: 0.96)
        case "Green": return Color(red: 0.18, green: 0.70, blue: 0.44)
        case "Red": return Color(red: 0.92, green: 0.30, blue: 0.30)
        case "Teal": return Color(red: 0.12, green: 0.69, blue: 0.73)
        default: return Color(red: 0.55, green: 0.36, blue: 0.96)
        }
    }

    private func timeRangeString(for event: ReminderEvent) -> String {
        if event.isReminder {
            if let date = event.startDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                return formatter.string(from: date)
            }
            return "All Day"
        } else {
            guard let start = event.startDate, let end = event.endDate else { return "All Day" }
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        }
    }

    // MARK: - Logic & Actions
    private func toggleTodoCompletion(_ item: ReminderEvent) {
        viewModel.toggleReminderCompletion(item)
    }

    private func deleteTodo(_ item: ReminderEvent) {
        viewModel.deleteItem(item)
    }

    private func saveNewTodo() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        viewModel.addEventOrReminder(
            title: trimmed,
            timeRange: newTaskTime.trimmingCharacters(in: .whitespacesAndNewlines),
            colorName: newTaskColor,
            isReminder: true
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            isAddingTask = false
        }
    }
}
