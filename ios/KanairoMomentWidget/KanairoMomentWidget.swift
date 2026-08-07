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

// MARK: - KXO Stamp (mirrors the Flutter KXOStamp widget)

struct KXOStampView: View {
    var size: CGFloat
    var color: Color

    var body: some View {
        ZStack {
            // Dashed circle border — matches KXOStampPainter
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [3.2, 2.1]))
                .foregroundColor(color)
                .frame(width: size, height: size)

            // Inner content: KanairoXO / Moments / separator
            VStack(spacing: 0) {
                Text("KanairoXO")
                    .font(Font.custom("DancingScript-Bold", size: size * 0.177))
                    .foregroundColor(color)
                    .lineLimit(1)

                Text("Moments")
                    .font(Font.custom("DancingScript-Bold", size: size * 0.129))
                    .foregroundColor(color)
                    .lineLimit(1)

                Rectangle()
                    .frame(width: size * 0.45, height: 0.7)
                    .foregroundColor(color.opacity(0.4))
                    .padding(.vertical, 1.5)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Polaroid view (small + large widgets show the latest moment)

struct MomentPolaroidView: View {
    var entry: MomentEntry

    private let accent = Color(red: 0.61, green: 0.07, blue: 0.12)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // White polaroid card — slightly tilted like a real photo
                VStack(spacing: 0) {

                    // ── Photo area ──────────────────────────────────────────
                    ZStack(alignment: .bottomTrailing) {
                        if let img = entry.image {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: geo.size.height * 0.70)
                                .clipped()
                        } else {
                            Color(white: 0.88)
                                .frame(maxWidth: .infinity)
                                .frame(height: geo.size.height * 0.70)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(Color(white: 0.60))
                                        .font(.system(size: 22)))
                        }

                        // Video badge
                        if entry.isVideo {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.90))
                                .shadow(color: .black.opacity(0.45), radius: 4, x: 0, y: 1)
                                .padding(7)
                        }
                    }

                    // ── Polaroid caption strip ──────────────────────────────
                    HStack(alignment: .center, spacing: 6) {
                        Text(entry.caption.isEmpty ? "a moment" : entry.caption)
                            .font(Font.custom("DMSans-Regular", size: 9.5))
                            .foregroundColor(Color(red: 0.17, green: 0.03, blue: 0.05))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 4)

                        // KanairoXO Moments stamp — matches the in-app KXOStamp
                        KXOStampView(size: 44, color: accent)
                            .rotationEffect(.degrees(-12))
                            .opacity(0.82)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                }
                .background(Color.white)
                // 6 pt border on sides/top, 0 extra (the caption strip IS the bottom)
                .padding(.horizontal, 6)
                .padding(.top, 6)
                .background(Color.white)
                // Subtle drop shadow so the card lifts off the background
                .shadow(color: .black.opacity(0.28), radius: 14, x: 0, y: 7)
                .rotationEffect(.degrees(-1.5))
                .padding(14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Warm dark background — makes the white polaroid card pop
        .containerBackground(Color(red: 0.12, green: 0.08, blue: 0.06), for: .widget)
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
