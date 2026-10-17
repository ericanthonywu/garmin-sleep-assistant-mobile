import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Color Palette

extension Color {
    static let momcareTeal = Color(red: 0.0, green: 0.85, blue: 0.75)       // Primary Garmin/MomCare Cyan
    static let windDownLavender = Color(red: 0.72, green: 0.65, blue: 1.0)   // Calming Wind Down Purple
    static let baselineBlue = Color(red: 0.35, green: 0.72, blue: 1.0)       // Circadian Baseline Anchor
    static let cutoffCoral = Color(red: 1.0, green: 0.45, blue: 0.35)        // Hard Cutoff Warning
    static let wakeAmber = Color(red: 1.0, green: 0.78, blue: 0.30)          // Morning Wake Sun
    static let darkCardBg = Color(red: 0.09, green: 0.13, blue: 0.22)        // Card surface
}

// MARK: - Models

struct SleepEntry: TimelineEntry {
    let date: Date
    let formattedDate: String     // e.g. "Monday, Sep 29"
    let todayShort: String        // e.g. "Mon, 29 Sep"
    let targetBedtime: String     // e.g. "11:30 PM"
    let windDownStart: String     // e.g. "10:45 PM"
    let baselineBedtime: String   // e.g. "12:00 AM" (Habitual anchor baseline)
    let cutoffTime: String        // e.g. "12:15 AM"
    let wakeTime: String          // e.g. "07:30 AM"
    let sleepOnset: String        // e.g. "12:00 AM"
    let baselineWake: String      // e.g. "07:45 AM"
    let sleepNeed: String         // e.g. "7h 45m"
    let statusText: String        // e.g. "Optimal circadian window"
    let adherenceStatus: String   // e.g. "holding", "advancing"
    let shiftMinutes: Int         // e.g. 15
    let guidance: String          // e.g. "Wind down 45m before bed..."
    let lastUpdated: String       // e.g. "01:05"

    static var placeholder: SleepEntry {
        SleepEntry(
            date: Date(),
            formattedDate: "Monday, Sep 29",
            todayShort: "Mon, 29 Sep",
            targetBedtime: "11:30 PM",
            windDownStart: "10:45 PM",
            baselineBedtime: "12:00 AM",
            cutoffTime: "12:15 AM",
            wakeTime: "07:30 AM",
            sleepOnset: "12:00 AM",
            baselineWake: "07:45 AM",
            sleepNeed: "7h 45m",
            statusText: "Optimal circadian window",
            adherenceStatus: "holding",
            shiftMinutes: 15,
            guidance: "Wind down 45m before bed to consolidate circadian rhythm.",
            lastUpdated: "Now"
        )
    }
}

// MARK: - App Intent for Interactive Refresh (iOS 17+)

struct RefreshSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Sleep Target"
    static var description = IntentDescription("Reloads bedtime recommendation and circadian timeline.")

    func perform() async throws -> some IntentResult {
        // Actively pull latest live recommendation directly in interactive intent
        _ = await SleepFetcher.fetch()
        WidgetCenter.shared.reloadTimelines(ofKind: "SleepWidget")
        return .result()
    }
}

// MARK: - Refresh Button

struct RefreshButton: View {
    var body: some View {
        Button(intent: RefreshSleepIntent()) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Background Auto-Update Network Fetcher

struct SleepFetcher {
    static var baseURL: String {
        let defaults = SleepTimelineProvider.sharedDefaults
        if let saved = defaults.string(forKey: "base_url"), !saved.isEmpty {
            return saved
        }
        return "http://srv1743851.hstgr.cloud:3002/api"
    }

    /// Fetches live dashboard & sleep recommendation data from the backend.
    /// Runs directly from WidgetKit in the background to ensure widget auto-updates.
    static func fetch() async -> SleepEntry? {
        guard let url = URL(string: "\(baseURL)/dashboard") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let payload = json["data"] as? [String: Any] else { return nil }

            let rec = payload["sleepEngineRecommendation"] as? [String: Any]

            let fullDf = DateFormatter()
            fullDf.dateFormat = "EEEE, MMM d"
            fullDf.locale = Locale(identifier: "en_US")

            let shortDf = DateFormatter()
            shortDf.dateFormat = "EEE, d MMM"
            shortDf.locale = Locale(identifier: "en_US")

            let timeDf = DateFormatter()
            timeDf.dateFormat = "HH:mm"

            let now = Date()

            // Formats 'HH:mm' to 'h:mm a'
            func fmt(_ raw: String?) -> String {
                guard let raw = raw, !raw.isEmpty else { return "--" }
                if raw.contains("AM") || raw.contains("PM") { return raw }
                let parts = raw.split(separator: ":")
                if parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                    let period = h >= 12 ? "PM" : "AM"
                    let displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h)
                    return String(format: "%d:%02d %@", displayH, m, period)
                }
                return raw
            }

            let targetBedtime = fmt(rec?["recommendedBedtime"] as? String)
            let windDownStart = fmt(rec?["windDownStart"] as? String)
            let baselineBedtime = fmt(rec?["anchorBedtime"] as? String)
            let cutoffTime = fmt(rec?["latestBedtimeCutoff"] as? String)
            let wakeTime = fmt(rec?["targetWakeTime"] as? String)
            let sleepOnset = fmt(rec?["recommendedSleepOnset"] as? String)
            let baselineWake = fmt(rec?["habitualWakeTime"] as? String)
            let shiftMinutes = rec?["shiftMinutes"] as? Int ?? 0
            let adherenceStatus = rec?["adherenceStatus"] as? String ?? "holding"
            let guidance = rec?["guidance"] as? String ?? "Dim lights & wind down before bed."

            let sleepNeedMins = rec?["sleepNeedMins"] as? Int
            let sleepNeedHours = rec?["sleepNeedHours"] as? Double
            let sleepNeed: String
            if let mins = sleepNeedMins {
                sleepNeed = "\(mins / 60)h \(mins % 60)m"
            } else if let hours = sleepNeedHours {
                sleepNeed = String(format: "%.1fh", hours)
            } else {
                sleepNeed = "7h 30m"
            }

            let statusText: String
            switch adherenceStatus {
            case "advancing": statusText = "\(shiftMinutes)m earlier step"
            case "holding":   statusText = "Holding steady"
            case "regressing": statusText = "Anchored · resume soon"
            case "achieved":  statusText = "Goal achieved ✓"
            default:          statusText = "Optimal circadian window"
            }

            let lastUpdated = timeDf.string(from: now)
            let formattedDate = fullDf.string(from: now)
            let todayShort = shortDf.string(from: now)

            // Cache to App Group UserDefaults (with standard fallback)
            let defaults = SleepTimelineProvider.sharedDefaults
            defaults.set(targetBedtime, forKey: "target_bedtime")
            defaults.set(windDownStart, forKey: "wind_down_start")
            defaults.set(baselineBedtime, forKey: "baseline_bedtime")
            defaults.set(cutoffTime, forKey: "cutoff_time")
            defaults.set(wakeTime, forKey: "wake_time")
            defaults.set(sleepOnset, forKey: "sleep_onset")
            defaults.set(baselineWake, forKey: "baseline_wake")
            defaults.set(sleepNeed, forKey: "sleep_need")
            defaults.set(statusText, forKey: "status_text")
            defaults.set(adherenceStatus, forKey: "adherence_status")
            defaults.set(shiftMinutes, forKey: "shift_minutes")
            defaults.set(guidance, forKey: "guidance")
            defaults.set(formattedDate, forKey: "formatted_date")
            defaults.set(todayShort, forKey: "today_short")
            defaults.set(lastUpdated, forKey: "last_updated")

            return SleepEntry(
                date: now,
                formattedDate: formattedDate,
                todayShort: todayShort,
                targetBedtime: targetBedtime,
                windDownStart: windDownStart,
                baselineBedtime: baselineBedtime,
                cutoffTime: cutoffTime,
                wakeTime: wakeTime,
                sleepOnset: sleepOnset,
                baselineWake: baselineWake,
                sleepNeed: sleepNeed,
                statusText: statusText,
                adherenceStatus: adherenceStatus,
                shiftMinutes: shiftMinutes,
                guidance: guidance,
                lastUpdated: lastUpdated
            )
        } catch {
            return nil
        }
    }
}

// MARK: - Timeline Provider (Automated Background Refresh)

struct SleepTimelineProvider: TimelineProvider {
    static let appGroupId = "group.com.ericanthony.garminMomcare"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
    }

    func placeholder(in context: Context) -> SleepEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        completion(readFromUserDefaults())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepEntry>) -> Void) {
        // Fast, non-blocking path: Immediately deliver current cached data from UserDefaults.
        // This guarantees completion is called synchronously, preventing WidgetKit's 
        // background watchdog from killing the extension.
        let entry = readFromUserDefaults()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readFromUserDefaults() -> SleepEntry {
        let defaults = Self.sharedDefaults
        let now = Date()

        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "EEEE, MMM d"
        fullDateFormatter.locale = Locale(identifier: "en_US")

        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "EEE, d MMM"
        shortDateFormatter.locale = Locale(identifier: "en_US")

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let formattedDate = defaults.string(forKey: "formatted_date") ?? fullDateFormatter.string(from: now)
        let todayShort = defaults.string(forKey: "today_short") ?? shortDateFormatter.string(from: now)

        let targetBedtime = defaults.string(forKey: "target_bedtime") ?? "11:30 PM"
        let windDownStart = defaults.string(forKey: "wind_down_start") ?? "10:45 PM"
        let baselineBedtime = defaults.string(forKey: "baseline_bedtime") ?? "12:00 AM"
        let cutoffTime = defaults.string(forKey: "cutoff_time") ?? "12:15 AM"
        let wakeTime = defaults.string(forKey: "wake_time") ?? "07:30 AM"
        let sleepOnset = defaults.string(forKey: "sleep_onset") ?? "12:00 AM"
        let baselineWake = defaults.string(forKey: "baseline_wake") ?? "07:45 AM"
        let sleepNeed = defaults.string(forKey: "sleep_need") ?? "7h 45m"
        let statusText = defaults.string(forKey: "status_text") ?? "Optimal circadian window"
        let adherenceStatus = defaults.string(forKey: "adherence_status") ?? "holding"
        let shiftMinutes = defaults.integer(forKey: "shift_minutes") != 0 ? defaults.integer(forKey: "shift_minutes") : 15
        let guidance = defaults.string(forKey: "guidance") ?? "Dim lights & wind down 45m before bed."
        let lastUpdated = defaults.string(forKey: "last_updated") ?? timeFormatter.string(from: now)

        return SleepEntry(
            date: now,
            formattedDate: formattedDate,
            todayShort: todayShort,
            targetBedtime: targetBedtime,
            windDownStart: windDownStart,
            baselineBedtime: baselineBedtime,
            cutoffTime: cutoffTime,
            wakeTime: wakeTime,
            sleepOnset: sleepOnset,
            baselineWake: baselineWake,
            sleepNeed: sleepNeed,
            statusText: statusText,
            adherenceStatus: adherenceStatus,
            shiftMinutes: shiftMinutes,
            guidance: guidance,
            lastUpdated: lastUpdated
        )
    }
}

// MARK: - Small View (systemSmall ~158x158 pt on iPhone 13)

struct SmallSleepView: View {
    let entry: SleepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Icon + Today's Date + Refresh
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.momcareTeal)
                Text(entry.todayShort)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                RefreshButton()
            }

            Spacer(minLength: 6)

            // Primary Sleep Target
            VStack(alignment: .leading, spacing: 1) {
                Text("IN BED BY")
                    .font(.system(size: 8.5, weight: .heavy))
                    .foregroundStyle(Color.momcareTeal)
                    .tracking(0.6)

                Text(entry.targetBedtime)
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 6)

            // Wind Down & Baseline Rows
            VStack(spacing: 4) {
                // Wind Down
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.windDownLavender)
                    Text("Wind:")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(entry.windDownStart)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.windDownLavender)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.windDownLavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

                // Baseline
                HStack(spacing: 4) {
                    Image(systemName: "anchor.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.baselineBlue)
                    Text("Base:")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(entry.baselineBedtime)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.baselineBlue)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.baselineBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(13)
    }
}

// MARK: - Medium View (systemMedium ~338x158 pt on iPhone 13)

struct MediumSleepView: View {
    let entry: SleepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Branding, Today's Date, Refresh Button
            HStack(spacing: 6) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.momcareTeal)

                Text("MOMCARE SLEEP")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(Color.momcareTeal)
                    .tracking(0.6)

                Spacer()

                Text(entry.todayShort)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))

                RefreshButton()
            }

            // Two-column split layout
            HStack(spacing: 12) {
                // Left Column: Sleep Recommendation Target & Wake
                VStack(alignment: .leading, spacing: 4) {
                    Text("TONIGHT'S BEDTIME")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(Color.momcareTeal)
                        .tracking(0.5)

                    Text(entry.targetBedtime)
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    HStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.wakeAmber)
                        Text("Wake: \(entry.wakeTime)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.wakeAmber.opacity(0.95))
                    }

                    Spacer(minLength: 0)

                    // Shift or Status Badge
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.momcareTeal)
                            .frame(width: 5, height: 5)
                        Text(entry.statusText)
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(Color.momcareTeal)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color.momcareTeal.opacity(0.14), in: Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .background(Color.white.opacity(0.15))

                // Right Column: Wind Down, Baseline, Hard Cutoff
                VStack(alignment: .leading, spacing: 5) {
                    // 1. Wind Down
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.windDownLavender)
                            .frame(width: 14)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("WIND DOWN")
                                .font(.system(size: 7.5, weight: .heavy))
                                .foregroundStyle(Color.windDownLavender.opacity(0.85))
                                .tracking(0.4)
                            Text(entry.windDownStart)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }

                    // 2. Baseline
                    HStack(spacing: 6) {
                        Image(systemName: "anchor.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.baselineBlue)
                            .frame(width: 14)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("BASELINE")
                                .font(.system(size: 7.5, weight: .heavy))
                                .foregroundStyle(Color.baselineBlue.opacity(0.85))
                                .tracking(0.4)
                            Text(entry.baselineBedtime)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }

                    // 3. Latest Cutoff
                    HStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.cutoffCoral)
                            .frame(width: 14)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("CUTOFF CEILING")
                                .font(.system(size: 7.5, weight: .heavy))
                                .foregroundStyle(Color.cutoffCoral.opacity(0.85))
                                .tracking(0.4)
                            Text(entry.cutoffTime)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.cutoffCoral)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
    }
}

// MARK: - Large View (systemLarge ~338x354 pt on iPhone 13)

struct LargeSleepView: View {
    let entry: SleepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.momcareTeal)

                Text("GARMIN MOMCARE AI")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Color.momcareTeal)
                    .tracking(0.6)

                Spacer()

                Text(entry.formattedDate)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))

                RefreshButton()
            }

            Divider()
                .background(Color.white.opacity(0.12))

            // Hero Target Card
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("RECOMMENDED BEDTIME")
                        .font(.system(size: 8.5, weight: .heavy))
                        .foregroundStyle(Color.momcareTeal)
                        .tracking(0.5)

                    Text(entry.targetBedtime)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(entry.statusText)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(Color.momcareTeal)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Label(entry.wakeTime, systemImage: "sun.max.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.wakeAmber)

                    Text("\(entry.sleepNeed) need")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.darkCardBg, in: RoundedRectangle(cornerRadius: 8))
            }

            // Circadian Pathway Timeline (Wind Down -> In Bed -> Onset -> Cutoff)
            VStack(alignment: .leading, spacing: 6) {
                Text("CIRCADIAN TIMING PATHWAY")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                HStack(spacing: 6) {
                    // Step 1: Wind Down
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 8, weight: .bold))
                            Text("WIND DOWN")
                                .font(.system(size: 7, weight: .heavy))
                        }
                        .foregroundStyle(Color.windDownLavender)

                        Text(entry.windDownStart)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Dim lights")
                            .font(.system(size: 7.5, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.windDownLavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

                    // Step 2: In Bed Target
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 8, weight: .bold))
                            Text("IN BED")
                                .font(.system(size: 7, weight: .heavy))
                        }
                        .foregroundStyle(Color.momcareTeal)

                        Text(entry.targetBedtime)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Recommended")
                            .font(.system(size: 7.5, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.momcareTeal.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

                    // Step 3: Latest Cutoff
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 8, weight: .bold))
                            Text("CUTOFF")
                                .font(.system(size: 7, weight: .heavy))
                        }
                        .foregroundStyle(Color.cutoffCoral)

                        Text(entry.cutoffTime)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.cutoffCoral)

                        Text("Ceiling ⚠️")
                            .font(.system(size: 7.5, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cutoffCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                }
            }

            // Baseline Anchor Comparison Box
            HStack(spacing: 10) {
                Image(systemName: "anchor.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.baselineBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("HABITUAL CIRCADIAN BASELINE")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(Color.baselineBlue)
                        .tracking(0.4)

                    Text("Baseline Sleep Onset: \(entry.baselineBedtime)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)

                    Text(entry.guidance)
                        .font(.system(size: 8.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(9)
            .background(Color.baselineBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))

            Spacer(minLength: 0)

            // Footer: Last updated
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 9))
                Text("Updated \(entry.lastUpdated)")
                    .font(.system(size: 9))
                Spacer()
                Text("iPhone 13 Optimized")
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.quaternary)
        }
        .padding(16)
    }
}

// MARK: - Lock Screen Views (iOS 16+)

struct AccessoryRectangularSleepView: View {
    let entry: SleepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 9))
                Text("BED: \(entry.targetBedtime)")
                    .font(.system(size: 11, weight: .bold))
            }
            Text("Wind: \(entry.windDownStart) • Base: \(entry.baselineBedtime)")
                .font(.system(size: 9.5, weight: .medium))
            Text("Cutoff: \(entry.cutoffTime) • Wake: \(entry.wakeTime)")
                .font(.system(size: 8.5))
                .foregroundStyle(.secondary)
        }
    }
}

struct AccessoryCircularSleepView: View {
    let entry: SleepEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 11))
                Text(entry.targetBedtime.replacingOccurrences(of: " ", with: ""))
                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
            }
        }
    }
}

struct AccessoryInlineSleepView: View {
    let entry: SleepEntry

    var body: some View {
        Label(
            "Bed: \(entry.targetBedtime) · Wind: \(entry.windDownStart) · Base: \(entry.baselineBedtime)",
            systemImage: "moon.stars.fill"
        )
    }
}

// MARK: - Entry View Dispatcher

struct SleepWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SleepEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallSleepView(entry: entry)
            case .systemMedium:
                MediumSleepView(entry: entry)
            case .systemLarge:
                LargeSleepView(entry: entry)
            case .accessoryRectangular:
                AccessoryRectangularSleepView(entry: entry)
            case .accessoryCircular:
                AccessoryCircularSleepView(entry: entry)
            case .accessoryInline:
                AccessoryInlineSleepView(entry: entry)
            default:
                MediumSleepView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.14),
                    Color(red: 0.08, green: 0.12, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
        .configurationDisplayName("MomCare Sleep & Wind Down")
        .description("Today's date, bedtime recommendation, wind down schedule, and circadian baseline.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
