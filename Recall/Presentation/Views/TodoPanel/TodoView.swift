//
//  TodoView.swift
//  Recall
//

import SwiftUI

struct TodoView: View {
    @Bindable var viewModel: TodoViewModel

    @State private var isAddingTask = false
    @State private var newTaskTitle  = ""
    @State private var newTaskTime   = "All Day"
    @State private var newTaskColor  = "Purple"

    private let availableColorNames = ["Purple", "Blue", "Green", "Red", "Teal"]

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.hasAccess {
                accessDeniedView
            } else {
                mainContentView
            }
        }
        .onAppear {
            if viewModel.hasAccess { viewModel.loadItems() }
        }
    }

    // MARK: - Access Denied

    private var accessDeniedView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "calendar.badge.key")
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.35))
            Text("Calendar & Reminders Access Required")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
            Text("Recall requires permission to read and manage tasks.")
                .font(.system(size: 8, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Button {
                viewModel.requestAccess()
            } label: {
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
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        HStack(spacing: 0) {
            leftCalendarPanel
            Divider()
                .overlay(Color.white.opacity(0.06))
                .frame(maxHeight: .infinity)
                .padding(.vertical, 8)
            rightCardsPanel
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Left: Date Panel

    private var leftCalendarPanel: some View {
        VStack(alignment: .leading, spacing: 7) {
            // Month / year header
            Text(monthYearString.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(0.8)

            // Compact scrollable calendar
            HorizontalCalendarView(selectedDate: $viewModel.selectedDate) { _ in
                viewModel.loadItems()
            }

            // Selected day label
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
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.28))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 148)
    }

    // MARK: - Right: Event Cards

    private var rightCardsPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    loadingCard
                } else if viewModel.eventsAndReminders.isEmpty {
                    emptyCard
                } else {
                    ForEach(viewModel.eventsAndReminders) { event in
                        EventCardView(
                            event: event,
                            timeString: timeRangeString(for: event),
                            onToggle: { toggleTodoCompletion(event) },
                            onDelete: { deleteTodo(event) }
                        )
                    }
                }

                // Add / Form card
                if isAddingTask {
                    addFormCard
                } else {
                    addPlaceholderCard
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Loading & Empty States

    private var loadingCard: some View {
        VStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Loading schedule…")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(width: 130, height: 100)
    }

    private var emptyCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.14))
            Text("All caught up!")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.18))
            Text("No tasks for today")
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.14))
        }
        .frame(width: 130, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(.white.opacity(0.01))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(.white.opacity(0.04), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Add Placeholder Card

    private var addPlaceholderCard: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isAddingTask = true
                newTaskTitle = ""
                newTaskTime  = "All Day"
                newTaskColor = "Purple"
            }
        } label: {
            VStack(spacing: 7) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.3))
                Text("Add Task")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .frame(width: 130, height: 100)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(
                        .white.opacity(0.15),
                        style: StrokeStyle(lineWidth: 1, dash: [3])
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Form Card (larger, Apple HIG)

    private var addFormCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Title field
            TextField("Task title…", text: $newTaskTitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(7)
                .onSubmit { saveNewTodo() }

            Spacer().frame(height: 6)

            // Time field
            TextField("Time  e.g. 10:00 AM", text: $newTaskTime)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .textFieldStyle(.plain)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)

            Spacer().frame(height: 8)

            // Color picker
            HStack(spacing: 6) {
                ForEach(availableColorNames, id: \.self) { name in
                    Circle()
                        .fill(colorForName(name))
                        .frame(width: 11, height: 11)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: newTaskColor == name ? 1.5 : 0)
                        )
                        .scaleEffect(newTaskColor == name ? 1.15 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: newTaskColor)
                        .onTapGesture { newTaskColor = name }
                }
                Spacer()
            }

            Spacer(minLength: 0)

            // Actions
            HStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isAddingTask = false
                    }
                } label: {
                    Text("Cancel")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)

                Spacer()

                Button { saveNewTodo() } label: {
                    Text("Save")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(width: 200, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: viewModel.selectedDate)
    }

    private var selectedDayInfoString: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: viewModel.selectedDate)
    }

    private func timeRangeString(for event: ReminderEvent) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        if event.isReminder {
            return event.startDate.map { f.string(from: $0) } ?? "All Day"
        }
        guard let s = event.startDate, let e = event.endDate else { return "All Day" }
        return "\(f.string(from: s)) – \(f.string(from: e))"
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "Purple": return Color(red: 0.55, green: 0.36, blue: 0.96)
        case "Blue":   return Color(red: 0.23, green: 0.51, blue: 0.96)
        case "Green":  return Color(red: 0.18, green: 0.70, blue: 0.44)
        case "Red":    return Color(red: 0.92, green: 0.30, blue: 0.30)
        case "Teal":   return Color(red: 0.12, green: 0.69, blue: 0.73)
        default:       return Color(red: 0.55, green: 0.36, blue: 0.96)
        }
    }

    private func toggleTodoCompletion(_ item: ReminderEvent) {
        viewModel.toggleReminderCompletion(item)
    }

    private func deleteTodo(_ item: ReminderEvent) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            viewModel.deleteItem(item)
        }
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

// MARK: - Event Card Subview

private struct EventCardView: View {
    let event: ReminderEvent
    let timeString: String
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Time + delete row
            HStack(spacing: 0) {
                Text(timeString)
                    .font(.system(size: 8.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.22))
                }
                .buttonStyle(.plain)
            }

            // Title
            Text(event.title)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(event.isCompleted ? .white.opacity(0.3) : .white.opacity(0.88))
                .strikethrough(event.isCompleted, color: .white.opacity(0.28))
                .lineLimit(2)

            Spacer(minLength: 0)

            // Footer: check or calendar icon
            HStack {
                Spacer()
                if event.isReminder {
                    Button(action: onToggle) {
                        Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(event.isCompleted ? Color.green : .white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.22))
                }
            }
        }
        .padding(8)
        .frame(width: 130, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(event.isCompleted ? .white.opacity(0.01) : .white.opacity(0.04))
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [event.color, event.color.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.vertical, 6)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(.white.opacity(event.isCompleted ? 0.03 : 0.07), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}
