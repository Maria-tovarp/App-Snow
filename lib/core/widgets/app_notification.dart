import 'dart:async';
import 'package:flutter/material.dart';

class AppNotification {
  static OverlayEntry? _overlay;

  static void success(
    BuildContext context, {
    required String message,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFF5B4CF0),
      icon: Icons.check_circle_rounded,
    );
  }

  static void error(
    BuildContext context, {
    required String message,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error_rounded,
    );
  }

  static void warning(
    BuildContext context, {
    required String message,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning_rounded,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    _overlay?.remove();

    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _NotificationWidget(
        message: message,
        color: backgroundColor,
        icon: icon,
      ),
    );

    _overlay = entry;

    overlay.insert(entry);

    Timer(const Duration(seconds: 2), () {
      if (entry.mounted) {
        entry.remove();
      }

      if (_overlay == entry) {
        _overlay = null;
      }
    });
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _NotificationWidget({
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  late final Animation<Offset> slide;

  late final Animation<double> fade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    slide = Tween<Offset>(
      begin: const Offset(0.25, -0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
    );

    fade = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );

    controller.forward();

    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) {
        controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 20;

    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              top: top,
              right: 20,
              child: FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: slide,
                  child: Material(
                    color: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 360,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFF0F0F5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: widget.color.withOpacity(0.12),
                              child: Icon(
                                widget.icon,
                                color: const Color(0xFF6A5AF9),
                                size: 22,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.message,
                                      style: const TextStyle(
                                        color: Color(0xFF4338CA),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
