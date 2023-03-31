import 'dart:developer' as l;
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});
  final double _ballSize = 60;
  final Color _ballColorIn = Colors.blue;
  final Color _ballColorOut = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const _GamePage(
        child: _BallImg(),
        // child: _Ball(size: _ballSize, colorIn: _ballColorIn, colorOut: _ballColorOut)
      ),
    );
  }
}

class _BallImg extends StatelessWidget {
  const _BallImg({super.key});

  final double size = 60.0;

  @override
  Widget build(BuildContext context) {
    return Image.asset('images/ball.png');
  }
}

class _Ball extends StatelessWidget {
  const _Ball({key, size, colorIn, colorOut})
      : _ballSize = size,
        _ballColorIn = colorIn,
        _ballColorOut = colorOut,
        super(key: key);

  final double _ballSize;
  final Color _ballColorIn;
  final Color _ballColorOut;

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: AlignmentDirectional.center, children: [
      Icon(
        Icons.circle,
        color: _ballColorOut,
        size: _ballSize,
      ),
      Icon(
        Icons.circle,
        color: _ballColorIn,
        size: _ballSize - (_ballSize * 0.1),
      )
    ]);
  }
}

class _GamePage extends StatefulWidget {
  const _GamePage({required this.child, super.key});

  final Widget child;

  @override
  State<_GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<_GamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;
  Alignment _currentPos = const Alignment(0, 0);
  Alignment _targetPos = const Alignment(0, 0);
  final List<double> _heightT = List<double>.generate(101, (index) => 0.3);
  final List<double> _heightB = List<double>.generate(101, (index) => 0.7);
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      setState(() {
        _currentPos = _animation.value;
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _runAnimationDrop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<ui.Image> getUiImage(
      String imageAssetPath, int height, int width) async {
    final ByteData assetImageByteData = await rootBundle.load(imageAssetPath);
    final codec = await ui.instantiateImageCodec(
      assetImageByteData.buffer.asUint8List(),
      targetHeight: height,
      targetWidth: width,
    );
    return (await codec.getNextFrame()).image;
  }

  @override
  Widget build(BuildContext context) {
    _score += 1;
    double h = _heightB[100] + ((Random().nextInt(3) - 1) / 100);
    if (h <= 0.4) {
      h = 0.4;
    } else if (h >= 1) {
      h = 1;
    }
    Size size = MediaQuery.of(context).size;
    _heightB.add(h);
    _heightB.removeAt(0);
    _heightT.add(h - 0.4);
    _heightT.removeAt(0);
    double ballSize = (widget.child as _BallImg).size;
    double y = (_currentPos.y * 0.5) + 0.5;
    double ty = y - (((y * ballSize)) / size.height);
    double by = y + ((ballSize - ((y * ballSize))) / size.height);
    List<Widget> children = List.of([
      CustomPaint(
        size: size,
        painter: _BottomWall(_heightB),
      ),
      CustomPaint(
        size: size,
        painter: _TopWall(_heightT),
      ),
      Align(
        alignment: _currentPos,
        child: RotationTransition(
              turns: Tween(begin: 0.0, end: 2.0).animate(_controller),
              child: widget.child,
            ),
      ),
       Align(
        alignment: const Alignment(0.9, -0.9),
        child: Text(_score.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    ], growable: true);
    if (by >= _heightB[50]) {
      l.log('$y >= ${_heightB[50]}');
      _controller.stop();
      children.add(_GameOver(_score));
      return _GameBody(children: children);
    } else if (ty <= _heightT[50]) {
      l.log('$y <= ${_heightT[50]}');
      _controller.stop();
      children.add(_GameOver(_score));
      return _GameBody(children: children);
    }
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => {_runAnimationJump()},
        child: _GameBody(children: children));
  }

  void _runAnimationJump() {
    double y = _currentPos.y - 0.25;
    if (y < -1) y = -1;
    _targetPos = Alignment(_currentPos.x, y);
    _animation = _controller.drive(
      AlignmentTween(
        begin: _currentPos,
        end: _targetPos,
      ),
    );
    const spring = SpringDescription(
      mass: 100,
      stiffness: 1,
      damping: 1,
    );

    final simulation = SpringSimulation(spring, 0, 1, 10);

    _controller.animateWith(simulation);
  }

  void _runAnimationDrop() {
    _animation = _controller.drive(
      AlignmentTween(
        begin: _currentPos,
        end: Alignment(_currentPos.x, 1),
      ),
    );
    final simulation = GravitySimulation(2, 0, 100, 1);
    _controller.animateWith(simulation);
  }
}

class _BottomWall extends CustomPainter {
  late List<double> _heightB;

  _BottomWall(List<double> heightB) {
    _heightB = heightB;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 10;

    var path = Path();

    path.moveTo(0, size.height);
    for (int i = 0; i <= 100; i++) {
      double h = _heightB[i];
      path.lineTo(size.width * (i / 100), size.height * h);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class _TopWall extends CustomPainter {
  late List<double> _heightT;

  _TopWall(List<double> heightT) {
    _heightT = heightT;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 10;

    var path = Path();

    path.moveTo(0, 0);
    for (int i = 0; i <= 100; i++) {
      double h = _heightT[i];
      path.lineTo(size.width * (i / 100), size.height * h);
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class _GameOver extends StatelessWidget {
  final int _score;
  const _GameOver(score) : _score = score;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Game over'),
      content: Text(_score.toString()),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/game'),
          child: const Text('Restart'),
        ),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          child: const Text('Back'),
        ),
      ],
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({key, required children})
      : _children = children,
        super(key: key);

  final List<Widget> _children;

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: AlignmentDirectional.center, children: _children);
  }
}

class MyCustomPainter extends CustomPainter {
  final ui.Image myBackground;
  const MyCustomPainter(this.myBackground);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(myBackground, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
