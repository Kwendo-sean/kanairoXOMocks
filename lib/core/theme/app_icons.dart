import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Central icon registry — the single source of truth for icons.
///
/// The bottom nav bar set the visual standard (Phosphor regular /
/// fill). Everything user-facing should pull from here instead of
/// Material `Icons.*` so the app reads as one hand-drawn system.
///
/// Usage:
///   Icon(AppIcons.share, size: 20)
///   PhosphorIcon(AppIcons.shareFill)   // filled variant where offered
///
/// Adding a new icon? Pick the Phosphor equivalent at
/// https://phosphoricons.com and add BOTH the semantic name and the
/// filled variant if the surface toggles (like/save/bookmark).
class AppIcons {
  AppIcons._();

  // ── Engagement ─────────────────────────────────────────────────
  static final like = PhosphorIcons.heart(PhosphorIconsStyle.regular);
  static final likeFill = PhosphorIcons.heart(PhosphorIconsStyle.fill);
  static final comment = PhosphorIcons.chatCircle(PhosphorIconsStyle.regular);
  static final share = PhosphorIcons.shareFat(PhosphorIconsStyle.regular);
  static final send = PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.regular);
  static final bookmark = PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.regular);
  static final bookmarkFill = PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill);

  // ── Media ──────────────────────────────────────────────────────
  static final download = PhosphorIcons.downloadSimple(PhosphorIconsStyle.regular);
  static final camera = PhosphorIcons.camera(PhosphorIconsStyle.regular);
  static final gallery = PhosphorIcons.images(PhosphorIconsStyle.regular);
  static final addPhoto = PhosphorIcons.imageSquare(PhosphorIconsStyle.regular);
  static final play = PhosphorIcons.play(PhosphorIconsStyle.fill);
  static final pause = PhosphorIcons.pause(PhosphorIconsStyle.fill);
  static final muted = PhosphorIcons.speakerSlash(PhosphorIconsStyle.regular);
  static final unmuted = PhosphorIcons.speakerHigh(PhosphorIconsStyle.regular);

  // ── Navigation / chrome ────────────────────────────────────────
  static final back = PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular);
  static final close = PhosphorIcons.x(PhosphorIconsStyle.regular);
  static final more = PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.regular);
  static final search = PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular);
  static final settings = PhosphorIcons.gearSix(PhosphorIconsStyle.regular);
  static final add = PhosphorIcons.plus(PhosphorIconsStyle.regular);
  static final check = PhosphorIcons.check(PhosphorIconsStyle.regular);
  static final forward = PhosphorIcons.arrowRight(PhosphorIconsStyle.regular);
  static final scan = PhosphorIcons.qrCode(PhosphorIconsStyle.regular);

  // ── Domain ─────────────────────────────────────────────────────
  static final calendar = PhosphorIcons.calendar(PhosphorIconsStyle.regular);
  static final location = PhosphorIcons.mapPin(PhosphorIconsStyle.regular);
  static final community = PhosphorIcons.usersThree(PhosphorIconsStyle.regular);
  static final groupAdd = PhosphorIcons.userPlus(PhosphorIconsStyle.regular);
  static final ticket = PhosphorIcons.ticket(PhosphorIconsStyle.regular);
  static final verified = PhosphorIcons.sealCheck(PhosphorIconsStyle.fill);
  static final notification = PhosphorIcons.bell(PhosphorIconsStyle.regular);
  static final message = PhosphorIcons.chatsCircle(PhosphorIconsStyle.regular);
  static final profile = PhosphorIcons.user(PhosphorIconsStyle.regular);
  static final delete = PhosphorIcons.trashSimple(PhosphorIconsStyle.regular);
  static final edit = PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular);
  static final warning = PhosphorIcons.warning(PhosphorIconsStyle.regular);
  static final invite = PhosphorIcons.envelopeSimple(PhosphorIconsStyle.regular);
  static final phone = PhosphorIcons.phone(PhosphorIconsStyle.regular);
  static final clock = PhosphorIcons.clock(PhosphorIconsStyle.regular);
  static final music = PhosphorIcons.musicNote(PhosphorIconsStyle.regular);
  static final spark = PhosphorIcons.sparkle(PhosphorIconsStyle.regular);
}
