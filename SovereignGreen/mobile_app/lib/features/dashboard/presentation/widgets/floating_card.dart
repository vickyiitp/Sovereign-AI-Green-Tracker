import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class FloatingCard extends StatefulWidget {
  final Widget child;
  final double height;
  final double? width;
  final Color? glowColor;

  const FloatingCard({
    super.key,
    required this.child,
    this.height = 200,
    this.width,
    this.glowColor,
  });

  @override
  State<FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<FloatingCard> {
  double x = 0;
  double y = 0;
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    // Only use sensors on mobile platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _streamSubscription = accelerometerEventStream().listen((
        AccelerometerEvent event,
      ) {
        if (mounted) {
          setState(() {
            // Subtle tilt effect
            x = -event.x * 0.05;
            y = event.y * 0.05;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Mouse Region for Web
      return MouseRegion(
        onHover: (event) {
          final size = MediaQuery.of(context).size;
          final center = Offset(size.width / 2, size.height / 2);
          setState(() {
            x = (event.position.dx - center.dx) / 1000;
            y = (event.position.dy - center.dy) / 1000;
          });
        },
        child: _buildCard(),
      );
    }
    return _buildCard();
  }

  Widget _buildCard() {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
        ..rotateY(x)
        ..rotateX(y),
      alignment: Alignment.center,
      child: GlassmorphicContainer(
        width: widget.width ?? MediaQuery.of(context).size.width * 0.9,
        height: widget.height,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.glowColor?.withOpacity(0.5) ?? Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
