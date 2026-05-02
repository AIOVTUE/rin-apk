import 'dart:async';

import 'package:flutter/material.dart';

class Ui {
  static OverlayEntry? _toastEntry;
  static Timer? _toastTimer;

  static void toast(BuildContext context, String message) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final media = MediaQuery.maybeOf(context);
    final topInset = (media?.padding.top ?? 0) + 10;
    final cs = Theme.of(context).colorScheme;

    _toastTimer?.cancel();
    _toastEntry?.remove();
    _toastEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: topInset,
        left: 12,
        right: 12,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_toastEntry!);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelText)),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(confirmText)),
          ],
        );
      },
    );
    return result ?? false;
  }
}

