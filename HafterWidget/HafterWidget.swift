//
//  HafterWidget.swift
//  HafterWidget
//

import WidgetKit
import SwiftUI

// MARK: - Shared data reader (mirrors WidgetDataBridge in the main app)

#if !FREE_SIGNING
private let appGroupId = "group.app.olar.Hafter"
private let moviesKey  = "widget_foremost_movies"
private let tonightKey = "widget_tonight_pick"
#endif

private struct SharedMovieEntry: Codable {
    let title: String
    let year: String?
    let posterPath: String?
}

private struct SharedTonightEntry: Codable {
    let title: String
    let year: String?
}

private func readSharedMovies() -> [SharedMovieEntry] {
    #if FREE_SIGNING
    return []
    #else
    guard let data = UserDefaults(suiteName: appGroupId)?.data(forKey: moviesKey),
          let entries = try? JSONDecoder().decode([SharedMovieEntry].self, from: data)
    else { return [] }
    return entries
    #endif
}

private func readTonight() -> SharedTonightEntry? {
    #if FREE_SIGNING
    return nil
    #else
    guard let data = UserDefaults(suiteName: appGroupId)?.data(forKey: tonightKey),
          let entry = try? JSONDecoder().decode(SharedTonightEntry.self, from: data)
    else { return nil }
    return entry
    #endif
}

// MARK: - Timeline

struct HafterTimelineEntry: TimelineEntry {
    let date: Date
    let title: String
    let year: String?
    let isEmpty: Bool
    let isTonight: Bool
}

struct HafterProvider: TimelineProvider {

    func placeholder(in context: Context) -> HafterTimelineEntry {
        .init(date: .now, title: "Oppenheimer", year: "2023", isEmpty: false, isTonight: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (HafterTimelineEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HafterTimelineEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> HafterTimelineEntry {
        if let tonight = readTonight() {
            return .init(date: .now, title: tonight.title, year: tonight.year, isEmpty: false, isTonight: true)
        }
        let movies = readSharedMovies()
        guard let pick = movies.randomElement() else {
            return .init(date: .now, title: "", year: nil, isEmpty: true, isTonight: false)
        }
        return .init(date: .now, title: pick.title, year: pick.year, isEmpty: false, isTonight: false)
    }
}

// MARK: - Design tokens (mirrors DS in the main app)

private enum WidgetColor {
    static let tierForemost  = Color(red: 180/255, green: 215/255, blue: 213/255)
    static let accent        = Color(red: 0.51, green: 0.58, blue: 0.99)
    static let brandIndigo   = Color(red: 0.26, green: 0.32, blue: 0.72)
    static let labelMuted    = Color(red: 0.357, green: 0.325, blue: 0.541)
}

// MARK: - Small widget view

struct HafterSmallView: View {
    let entry: HafterTimelineEntry

    var body: some View {
        ZStack {
            WidgetColor.tierForemost.ignoresSafeArea()
            if entry.isEmpty {
                emptyView
            } else {
                filledView
            }
        }
    }

    private var filledView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.isTonight ? "Tonight" : "Hafter")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(WidgetColor.labelMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Text(entry.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(WidgetColor.brandIndigo)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let year = entry.year {
                Text(year)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(WidgetColor.labelMuted)
            }
        }
        .padding(14)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "film")
                .font(.system(size: 28))
                .foregroundColor(WidgetColor.labelMuted)
            #if FREE_SIGNING
            Text("Movies stay\nin the app")
            #else
            Text("Add movies\nto Foremost")
            #endif
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(WidgetColor.labelMuted)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Medium widget view

struct HafterMediumView: View {
    let entry: HafterTimelineEntry

    var body: some View {
        ZStack {
            WidgetColor.tierForemost.ignoresSafeArea()
            if entry.isEmpty {
                HafterSmallView(entry: entry)
            } else {
                filledView
            }
        }
    }

    private var filledView: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left: decorative accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(WidgetColor.accent)
                .frame(width: 4)
                .padding(.leading, 14)
                .padding(.vertical, 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.isTonight ? "Tonight's pick" : "Watch tonight")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(WidgetColor.labelMuted)

                Text(entry.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(WidgetColor.brandIndigo)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                if let year = entry.year {
                    Text(year)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(WidgetColor.labelMuted)
                }

                Spacer()

                Text("Tap to open Hafter")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(WidgetColor.accent)
            }
            .padding(.leading, 14)
            .padding(.trailing, 14)
            .padding(.vertical, 16)

            Spacer()
        }
    }
}

// MARK: - Widget declaration

struct HafterWidget: Widget {
    static let kind = "HafterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HafterProvider()) { entry in
            HafterWidgetEntryView(entry: entry)
                .containerBackground(WidgetColor.tierForemost, for: .widget)
        }
        .configurationDisplayName("Foremost pick")
        .description("Shows a random movie from your Foremost list.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HafterWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HafterTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall:  HafterSmallView(entry: entry)
        case .systemMedium: HafterMediumView(entry: entry)
        default:            HafterSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    HafterWidget()
} timeline: {
    HafterTimelineEntry(date: .now, title: "Interstellar", year: "2014", isEmpty: false, isTonight: true)
    HafterTimelineEntry(date: .now, title: "", year: nil, isEmpty: true, isTonight: false)
}
