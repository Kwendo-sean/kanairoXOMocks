//
//  KanairoMomentWidget.swift
//  KanairoMomentWidget
//
//  Locket-style widget that shows the user's most recent moment on the home
//  screen. The Flutter app downloads the latest moment's still image into the
//  shared App Group container; this widget reads it and renders it.
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

private func sharedDefaults() -> UserDefaults? {
    UserDefaults(suiteName: kAppGroup)
}

// MARK: - Timeline entry

struct MomentEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let caption: String
    let isVideo: Bool
}

// MARK: - Provider

struct MomentProvider: TimelineProvider {
    func placeholder(in context: Context) -> MomentEntry {
        MomentEntry(date: Date(), image: nil, caption: "Your moments", isVideo: false)
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
        return MomentEntry(date: Date(), image: image, caption: caption, isVideo: isVideo)
    }
}

// MARK: - View (polaroid frame)

struct KanairoMomentWidgetEntryView: View {
    var entry: MomentEntry

    var body: some View {
        ZStack {
            // Cream polaroid background
            Color(red: 0.97, green: 0.94, blue: 0.88)

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
        .configurationDisplayName("Latest Moment")
        .description("See your most recent KanairoXO polaroid right on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
