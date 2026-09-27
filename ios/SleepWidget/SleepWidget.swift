import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SleepEntry: TimelineEntry {
    let date: Date
    let formattedDate: String
    let targetBedtime: String
    let cutoffTime: String
    let wakeTime: String
    let statusText: String
    let lastUpdated: String

    static var placeholder: SleepEntry {
        SleepEntry(
            date: Date(),
            formattedDate: "Tonight",
            targetBedtime: "12:00 AM",
            cutoffTime: "12:45 AM",
            wakeTime: "07:30 AM",
            statusText: "Circadian Window Active",
            lastUpdated: "Now"
        )
    }
}

// MARK: - Timeline Provider

struct SleepTimelineProvider: TimelineProvider {
    static let appGroupId = "group.com.ericanthony.garminMomcare"

    func placeholder(in context: Context) -> SleepEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepEntry) -> Void) {
        completion(readFromUserDefaults())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepEntry>) -> Void) {
        let entry = readFromUserDefaults()
        // Refresh timeline every 15 minutes to keep date and status accurate
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readFromUserDefaults() -> SleepEntry {
        let defaults = UserDefaults(suiteName: Self.appGroupId)
        let targetBedtime = defaults?.string(forKey: "target_bedtime") ?? "12:00 AM"
        let cutoffTime = defaults?.string(forKey: "cutoff_time") ?? "12:45 AM"
        let formattedDate = defaults?.string(forKey: "formatted_date") ?? {
            let df = DateFormatter()
            df.dateFormat = "EEEE, MMM d"
            return df.string(from: Date())
        }()
        let wakeTime = defaults?.string(forKey: "wake_time") ?? "07:30 AM"
        let statusText = defaults?.string(forKey: "status_text") ?? "Optimal circadian window"
        let lastUpdated = defaults?.string(forKey: "last_updated") ?? "Synced"

        return SleepEntry(
            date: Date(),
            formattedDate: formattedDate,
            targetBedtime: targetBedtime,
            cutoffTime: cutoffTime,
            wakeTime: wakeTime,
            statusText: statusText,
            lastUpdated: lastUpdated
        )
    }
}

// MARK: - SwiftUI Views

struct SleepWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: SleepEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallSleepView(entry: entry)
        case .systemMedium:
            MediumSleepView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularSleepView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularSleepView(entry: entry)
        default:
            SmallSleepView(entry: entry)
        }
    }
}

// MARK: - Small View (2x2)

struct SmallSleepView: View {
    var entry: SleepEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.05, green: 0.08, blue: 0.14), Color(red: 0.09, green: 0.13, blue: 0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                // Header: Moon + Date
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.75)) // Teal/Cyan
                    
                    Text(entry.formattedDate)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
                        .lineLimit(1)
                }

                Spacer()

                // Bedtime target
                VStack(alignment: .leading, spacing: 1) {
                    Text("BEDTIME TARGET")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.75))
                        .tracking(0.5)

                    Text(entry.targetBedtime)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                // Latest Cutoff Pill
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.4))

                    Text("Cutoff: \(entry.cutoffTime)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.8))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(red: 0.9, green: 0.25, blue: 0.25).opacity(0.2))
                .cornerRadius(6)
            }
            .padding(14)
        }
    }
}

// MARK: - Medium View (4x2)

struct MediumSleepView: View {
    var entry: SleepEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.04, green: 0.07, blue: 0.12), Color(red: 0.08, green: 0.12, blue: 0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(spacing: 16) {
                // Left Column: Target Bedtime
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.75))

                        Text("TONIGHT'S SLEEP TARGET")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.75))
                            .tracking(0.5)
                    }

                    Text(entry.formattedDate)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.85))

                    Spacer()

                    Text(entry.targetBedtime)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("Target Wake: \(entry.wakeTime)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0.55, green: 0.6, blue: 0.7))
                }

                Divider()
                    .background(Color.white.opacity(0.15))

                // Right Column: Cutoff & Circadian Window
                VStack(alignment: .leading, spacing: 8) {
                    // Latest Cutoff Box
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.4))

                            Text("LATEST CUTOFF")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.4))
                        }

                        Text(entry.cutoffTime)
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.9, green: 0.25, blue: 0.25).opacity(0.18))
                    .cornerRadius(8)

                    // Circadian status note
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.0, green: 0.85, blue: 0.75))
                            .frame(width: 6, height: 6)

                        Text("Circadian window active")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.85))
                    }
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Lock Screen Views (iOS 16+)

struct AccessoryRectangularSleepView: View {
    var entry: SleepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 10))
                Text("\(entry.formattedDate)")
                    .font(.system(size: 11, weight: .bold))
            }
            Text("Bed: \(entry.targetBedtime) • Cutoff: \(entry.cutoffTime)")
                .font(.system(size: 10, weight: .semibold))
            Text("Wake: \(entry.wakeTime)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

struct AccessoryCircularSleepView: View {
    var entry: SleepEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 12))
                Text(entry.targetBedtime.replacingOccurrences(of: " ", with: ""))
                    .font(.system(size: 9, weight: .bold))
            }
        }
    }
}

// MARK: - Widget Definition

struct SleepWidget: Widget {
    let kind: String = "SleepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepTimelineProvider()) { entry in
            SleepWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bedtime Recommendation")
        .description("Shows today's recommended sleep time, latest cutoff, and wake schedule.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular,
        ])
    }
}
