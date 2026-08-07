//
//  KanairoMomentWidget.swift
//  KanairoMomentWidget
//
//  Locket-style widget. Small/large show the user's most recent moment;
//  medium shows their soonest upcoming events. The Flutter app writes both
//  the moment image and an upcoming-events JSON blob into the shared App
//  Group container; this widget reads them and renders accordingly.
//
//  iOS widgets cannot host AVPlayer, so video moments display the server-
//  extracted first frame with a small play badge. Photo moments show the
//  photo directly.
//

import WidgetKit
import SwiftUI

// MARK: - App Group + shared keys

private let kAppGroup = "group.com.kanairoxo.kanairoxo"
private let kImagePathKey = "latest_moment_image_path"
private let kCaptionKey = "latest_moment_caption"
private let kIsVideoKey = "latest_moment_is_video"
private let kUpcomingEventsKey = "upcoming_events_json"

private func sharedDefaults() -> UserDefaults? {
    UserDefaults(suiteName: kAppGroup)
}

// MARK: - Upcoming event (decoded from the JSON the Flutter side writes)

struct UpcomingEvent: Decodable {
    let title: String
    let venue: String
    let startDate: TimeInterval
}

// MARK: - Timeline entry

struct MomentEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let caption: String
    let isVideo: Bool
    let upcomingEvents: [UpcomingEvent]
}

// MARK: - Provider

struct MomentProvider: TimelineProvider {
    func placeholder(in context: Context) -> MomentEntry {
        MomentEntry(date: Date(), image: nil, caption: "Your moments", isVideo: false, upcomingEvents: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (MomentEntry) -> Void) {
        completion(loadCurrent())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MomentEntry>) -> Void) {
        let entry = loadCurrent()
        // Refresh every 15 minutes (WidgetKit ultimately decides the cadence
        // based on system budget, but this is the requested frequency).
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadCurrent() -> MomentEntry {
        let defaults = sharedDefaults()
        let path = defaults?.string(forKey: kImagePathKey)
        let caption = defaults?.string(forKey: kCaptionKey) ?? ""
        let isVideo = defaults?.bool(forKey: kIsVideoKey) ?? false

        var image: UIImage? = nil
        if let path = path, let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            image = UIImage(data: data)
        }

        var events: [UpcomingEvent] = []
        if let json = defaults?.string(forKey: kUpcomingEventsKey),
           let data = json.data(using: .utf8) {
            events = (try? JSONDecoder().decode([UpcomingEvent].self, from: data)) ?? []
        }

        return MomentEntry(date: Date(), image: image, caption: caption, isVideo: isVideo, upcomingEvents: events)
    }
}

// MARK: - Polaroid view (small + large widgets show the latest moment)

struct MomentPolaroidView: View {
    var entry: MomentEntry

    var body: some View {
        VStack(spacing: 6) {
            // Photo area
            ZStack {
                if let img = entry.image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } else {
                    Color(white: 0.90)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.system(size: 28)))
                }

                // Play badge for video moments
                if entry.isVideo {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)
                                .padding(.top, 6)
                                .padding(.trailing, 6)
                        }
                        Spacer()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Caption row (the "polaroid" label area)
            HStack {
                Text(entry.caption.isEmpty ? "KanairoXO" : entry.caption)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.6, green: 0.07, blue: 0.12))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
        .padding(8)
        .containerBackground(Color(red: 0.97, green: 0.94, blue: 0.88), for: .widget)
    }
}

// MARK: - Upcoming events view (medium widget)

struct UpcomingEventsView: View {
    var events: [UpcomingEvent]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM, h:mm a")
        return formatter
    }()

    private static let accent = Color(red: 0.6, green: 0.07, blue: 0.12)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .bold))
                Text("Upcoming events")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(Self.accent)

            if events.isEmpty {
                Spacer(minLength: 0)
                Text("Nothing on your calendar yet")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
            } else {
                ForEach(Array(events.prefix(2).enumerated()), id: \.offset) { index, event in
                    if index > 0 {
                        Divider()
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(event.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text("\(event.venue) · \(Self.dateFormatter.string(from: Date(timeIntervalSince1970: event.startDate)))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Entry view (switches on widget family)

struct KanairoMomentWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: MomentEntry

    var body: some View {
        switch family {
        case .systemMedium:
            UpcomingEventsView(events: entry.upcomingEvents)
        default:
            MomentPolaroidView(entry: entry)
        }
    }
}

// MARK: - Widget

struct KanairoMomentWidget: Widget {
    let kind: String = "KanairoMomentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MomentProvider()) { entry in
            KanairoMomentWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("KanairoXO")
        .description("Your most recent polaroid, or a peek at what's coming up.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview("Moment", as: .systemSmall) {
    KanairoMomentWidget()
} timeline: {
    MomentEntry(date: .now, image: nil, caption: "Friday night out", isVideo: false, upcomingEvents: [])
}

#Preview("Upcoming", as: .systemMedium) {
    KanairoMomentWidget()
} timeline: {
    MomentEntry(date: .now, image: nil, caption: "", isVideo: false, upcomingEvents: [
        UpcomingEvent(title: "Jazz Night", venue: "Alliance Française", startDate: Date().addingTimeInterval(86_400).timeIntervalSince1970),
        UpcomingEvent(title: "Rooftop Mixer", venue: "The Alchemist", startDate: Date().addingTimeInterval(3 * 86_400).timeIntervalSince1970)
    ])
}
