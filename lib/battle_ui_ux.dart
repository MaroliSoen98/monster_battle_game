part of 'battle_arena.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    this.maxLines = 3,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animateText();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _animateText();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _animateText() {
    _timer?.cancel();
    setState(() {
      _displayedText = '';
    });

    int charIndex = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (charIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[charIndex];
          charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Custom Clipper Dinamis untuk setengah layar atas (Musuh)
class DynamicTopClipper extends CustomClipper<Path> {
  final double morphProgress;
  DynamicTopClipper(this.morphProgress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final leftY = (size.height / 2) * (1 - morphProgress);
    final rightY = (size.height / 2) + (size.height / 2) * morphProgress;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, rightY);
    path.lineTo(0, leftY);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(DynamicTopClipper oldClipper) =>
      morphProgress != oldClipper.morphProgress;
}

// Custom Clipper Dinamis untuk setengah layar bawah (Pemain)
class DynamicBottomClipper extends CustomClipper<Path> {
  final double morphProgress;
  DynamicBottomClipper(this.morphProgress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final leftY = (size.height / 2) * (1 - morphProgress);
    final rightY = (size.height / 2) + (size.height / 2) * morphProgress;

    path.moveTo(0, leftY);
    path.lineTo(size.width, rightY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(DynamicBottomClipper oldClipper) =>
      morphProgress != oldClipper.morphProgress;
}

// ============================================================================
// 2. WILD BATTLE ARENA
// ============================================================================
