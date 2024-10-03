import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';

class LampScreen extends StatefulWidget {
  const LampScreen({super.key});

  @override
  State<LampScreen> createState() => _LampScreenState();
}

class _LampScreenState extends State<LampScreen> with TickerProviderStateMixin {
  Offset _offset = const Offset(0, 0);
  Offset previousVelocity = const Offset(0, 0);
  bool isOn = false;
  final _springDescription = const SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 6,
  );

  late SpringSimulation _springSimX;
  late SpringSimulation _springSimY;
  Ticker? _ticker;

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
    });
  }

  void _onPanStart(DragStartDetails details) {
    _endSpring();
  }

  void _onPanEnd(DragEndDetails details) {
    if (_offset.dy > 10) {
      setState(() {
        isOn = !isOn;
      });

      isOn ? _turnOnFlash(context) : _turnOffFlash(context);
    }
    _startSpring();
  }

  _startSpring() {
    _springSimX = SpringSimulation(
      _springDescription,
      _offset.dx,
      0,
      previousVelocity.dx,
    );

    _springSimY = SpringSimulation(
      _springDescription,
      _offset.dy,
      0,
      previousVelocity.dy,
    );

    _ticker ??= createTicker(_onTick);
    _ticker?.start();
  }

  _endSpring() {
    _ticker?.stop();
  }

  _onTick(Duration elapsedTime) {
    final elapsedTimeFraction = elapsedTime.inMilliseconds / 1000.0;
    setState(() {
      _offset = Offset(_springSimX.x(elapsedTimeFraction),
          _springSimY.x(elapsedTimeFraction));

      previousVelocity = Offset(_springSimX.dx(elapsedTimeFraction),
          _springSimY.dx(elapsedTimeFraction));
    });
    if (_springSimX.isDone(elapsedTimeFraction) &&
        _springSimY.isDone(elapsedTimeFraction)) {
      _endSpring();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mahmoud Azab',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: AnnotatedRegion(
        value: isOn ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanEnd: _onPanEnd,
          onPanUpdate: _onPanUpdate,
          child: Container(
            decoration: BoxDecoration(
              color: isOn ? Colors.yellowAccent : Colors.white,
            ),
            child: Stack(
              children: [
                CustomPaint(
                  painter: RopePainter(
                    springOffset: Offset(
                      _offset.dx,
                      _offset.dy + 100,
                    ),
                  ),
                  size: Size.infinite,
                ),
                Align(
                  alignment: const Alignment(0.0, -0.11),
                  child: Image.asset(
                    isOn ? 'assets/lamp_on.png' : 'assets/lamp_off.png',
                    height: 100,
                    width: 100,
                    colorBlendMode: BlendMode.modulate,
                    // color: Colors.white,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: Offset(_offset.dx, _offset.dy + 100),
                    child: Container(
                      height: 20,
                      width: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _turnOnFlash(BuildContext context) async {
    try {
      await TorchLight.enableTorch();
    } on Exception catch (e) {
      _showErrorMes('Could not enable Flashlight $e', context);
    }
  }

  Future<void> _turnOffFlash(BuildContext context) async {
    try {
      await TorchLight.disableTorch();
    } on Exception catch (e) {
      _showErrorMes('Could not enable Flashlight $e', context);
    }
  }

  void _showErrorMes(String mes, BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mes)));
  }
}

class RopePainter extends CustomPainter {
  Offset springOffset;
  final Paint springPaint = Paint()
    ..color = Colors.black45
    ..strokeWidth = 4.0
    ..style = PaintingStyle.stroke;

  RopePainter({this.springOffset = const Offset(0, 0)});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    canvas.drawLine(center, center + springOffset, springPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
