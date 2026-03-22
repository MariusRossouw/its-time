import SwiftUI

struct PunchCardGrid: View {
    let habit: Habit
    let weeks: Int

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 14
    private let spacing: CGFloat = 3

    private var dates: [[Date]] {
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeks * 7
        var grid: [[Date]] = Array(repeating: [], count: 7) // 7 rows (days of week)

        for dayOffset in stride(from: totalDays - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let weekday = (calendar.component(.weekday, from: date) + 5) % 7 // Mon=0..Sun=6
            grid[weekday].append(date)
        }

        return grid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Month labels
            monthLabels

            HStack(alignment: .top, spacing: spacing) {
                // Day labels
                VStack(spacing: spacing) {
                    ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .frame(width: cellSize, height: cellSize)
                    }
                }

                // Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(0..<weeks, id: \.self) { week in
                            VStack(spacing: spacing) {
                                ForEach(0..<7, id: \.self) { day in
                                    if week < dates[day].count {
                                        let date = dates[day][week]
                                        punchCell(date: date)
                                    } else {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.clear)
                                            .frame(width: cellSize, height: cellSize)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var monthLabels: some View {
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeks * 7

        return HStack(spacing: 0) {
            Spacer().frame(width: cellSize + spacing) // offset for day labels

            ForEach(0..<weeks, id: \.self) { week in
                let dayOffset = totalDays - 1 - (week * 7)
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                    let isFirstOfMonth = calendar.component(.day, from: date) <= 7
                    if isFirstOfMonth {
                        Text(date, format: .dateTime.month(.abbreviated))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
                if week < weeks - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func punchCell(date: Date) -> some View {
        let completed = habit.isCompletedOn(date)
        let value = habit.valueOn(date)
        let intensity: Double = habit.isCumulative
            ? min(Double(value) / Double(max(habit.goalCount, 1)), 1.0)
            : (completed ? 1.0 : 0.0)

        return RoundedRectangle(cornerRadius: 2)
            .fill(intensity > 0 ? Color(hex: habit.color).opacity(0.2 + intensity * 0.8) : Color.gray.opacity(0.15))
            .frame(width: cellSize, height: cellSize)
    }
}
