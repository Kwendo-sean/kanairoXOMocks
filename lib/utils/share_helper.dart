import 'package:flutter/material.dart';

/// iOS throws if the share sheet's popover anchor rect is zero-sized.
/// Derive it from the calling widget, falling back to a small rect at the
/// screen centre.
Rect shareOriginFor(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final size = MediaQuery.of(context).size;
  return Rect.fromLTWH(size.width / 2 - 1, size.height / 2 - 1, 2, 2);
}
