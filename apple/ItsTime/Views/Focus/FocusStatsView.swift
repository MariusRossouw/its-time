import SwiftUI
import SwiftData

struct FocusStatsView: View {
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var allSessions: [FocusSession]

    @State private var timeRange: StatsTimeRange = .week

    private let calendar = Calendar.current

    private var filteredSessions: [FocusSession] {
        let now = Date()
        let start: Date
        switch timeRange {
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: now)!
        case .allTime:
            return allSessions.filter { $0.isCompleted && $0.sessionType == .pomodoro }
        }
        return allSessions.filter { session in
            session.isCompleted && session.sessionType == .pomodoro && session.startedAt >= start
        }
    }

    private var totalFocusMinutes: Int {
        filteredSessions.reduce(0) { $0 + $1.actualDuration } / 60
    }

    private var totalSessions: Int {
        filteredSessions.count
    }

    private var averageDailyMinutes: Int {
        let days: Int
        switch timeRange {
        case .week: days = 7
        case .month: days = 30
        case .allTime:
            guard let earliest = filteredSessions.last?.startedAt else { return 0 }
            days = max(1, calendar.dateComponents([.day], from: earliest, to: Date()).day ?? 1)
        }
        guard days > 0 else { return 0 }
        return totalFocusMinutes / days
    }

    private var dailyData: [(day: String, minutes: Int)] {
        let daysCount: Int
        switch timeRange {
        case .week: daysCount = 7
        case .month: daysCount = 30
        case .allTime: daysCount = 14
        }

        let now = Date()
        return (0..<daysCount).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: now)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let minutes = filteredSessions
                .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
                .reduce(0) { $0 + $1.actualDuration } / 60

            let df = DateFormatter()
            df.dateFormat = daysCount <= 7 ? "EEE" : "M/d"
            return (day: df.string(from: date), minutes: minutes)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range picker
                Picker("Range", selection: $timeRange) {
                    ForEach(StatsTimeRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Summary cards
                HStack(spacing: 12) {
                    statCard(title: "Total", value: "\(totalFocusMinutes)", unit: "min")
                    statCard(title: "Sessions", value: "\(totalSessions)", unit: "")
                    statCard(title: "Daily Avg", value: "\(averageDailyMinutes)", unit: "min")
                }
                .padding(.horizontal)

                // Bar chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Time")
                        .font(.headline)
                        .padding(.horizontal)

                    let maxMinutes = max(dailyData.map(\.minutes).max() ?? 1, 1)

                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(dailyData, id: \.day) { entry in
                            VStack(spacing: 4) {
                                if entry.minutes > 0 {
                                    Text("\(entry.minutes)")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.secondary)
                                }

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentColor.opacity(entry.minutes > 0 ? 0.7 : 0.15))
                                    .frame(
                                        height: max(4, CGFloat(entry.minutes) / CGFloat(maxMinutes) * 120)
                                    )

                                Text(entry.day)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 160)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color.gray.opacity(0.15).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Recent sessions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .padding(.horizontal)

                    if filteredSessions.isEmpty {
                        Text("No focus sessions yet")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(filteredSessions.prefix(10)) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.task?.title ?? "Untitled")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Text(session.startedAt, format: .dateTime.month().day().hour().minute())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("\(session.actualDuration / 60) min")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                    }
                }

                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Focus Stats")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func statCard(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.15).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

enum StatsTimeRange: String, CaseIterable, Identifiable {
    case week
    case month
    case allTime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .allTime: return "All Time"
        }
    }
}
