import 'dart:async';
import 'package:flutter/material.dart';
import 'mori.dart';
import 'localization.dart';

/// One cover per launch. The real screen loads underneath it.
class StartupCover extends StatefulWidget {
  final Widget child;
  const StartupCover({super.key, required this.child});
  @override
  State<StartupCover> createState() => _StartupCoverState();
}

class _StartupCoverState extends State<StartupCover> {
  Timer? timer;
  bool visible = true, fading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      timer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          if (MediaQuery.disableAnimationsOf(context)) {
            visible = false;
          } else {
            fading = true;
          }
        });
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(
        excluding: visible,
        child: IgnorePointer(ignoring: visible, child: widget.child),
      ),
      if (visible)
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: fading ? 0 : 1,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            onEnd: () {
              if (mounted && fading) setState(() => visible = false);
            },
            child: Material(
              key: const ValueKey('mori-startup-cover'),
              color: const Color(0xFFF6F8F2),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 150,
                          height: 165,
                          child: DoctorMori(),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'MORI',
                          style: TextStyle(
                            color: Color(0xFF193B32),
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 7,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          tr('Find a clinic. Explain your symptoms in Korean.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF21664F),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const SizedBox(
                          width: 36,
                          child: Divider(
                            color: Color(0xFF21664F),
                            thickness: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
