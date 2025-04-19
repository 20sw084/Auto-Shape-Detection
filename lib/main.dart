import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: ShapeCanvas()));
}

class ShapeCanvas extends StatefulWidget {
  const ShapeCanvas({super.key});

  @override
  State<ShapeCanvas> createState() => _ShapeCanvasState();
}

class _ShapeCanvasState extends State<ShapeCanvas> {
  List<Offset> points = [];
  List<Shape> detectedShapes = [];

  void onPanUpdate(DragUpdateDetails details) {
    setState(() {
      points.add(details.localPosition);
    });
  }

  void onPanEnd(DragEndDetails details) {
    final shape = ShapeDetector.detect(points);
    if (shape != null) {
      setState(() {
        detectedShapes.add(shape);
      });
    }
    points.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Shape Detection')),
      body: GestureDetector(
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: CustomPaint(
          painter: ShapePainter(points, detectedShapes),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  final List<Offset> currentPoints;
  final List<Shape> shapes;

  ShapePainter(this.currentPoints, this.shapes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..color = Colors.blue
      ..style = PaintingStyle.stroke;

    for (var shape in shapes) {
      shape.draw(canvas, paint);
    }

    if (currentPoints.isNotEmpty) {
      final path = Path()..moveTo(currentPoints[0].dx, currentPoints[0].dy);
      for (int i = 1; i < currentPoints.length; i++) {
        path.lineTo(currentPoints[i].dx, currentPoints[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

abstract class Shape {
  void draw(Canvas canvas, Paint paint);
}

class CircleShape extends Shape {
  final Offset center;
  final double radius;

  CircleShape(this.center, this.radius);

  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawCircle(center, radius, paint);
  }
}

class LineShape extends Shape {
  final Offset start, end;

  LineShape(this.start, this.end);

  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawLine(start, end, paint);
  }
}

class ShapeDetector {
  static Shape? detect(List<Offset> points) {
    if (points.length < 5) return null;

    final shape = _detectPolygon(points) ??
        _detectCircle(points) ??
        _detectLine(points);
    return shape;
  }

  static Shape? _detectLine(List<Offset> points) {
    final start = points.first;
    final end = points.last;
    final distance = (end - start).distance;
    if (distance > 50 && points.every((p) => _pointLineDistance(start, end, p) < 10)) {
      return LineShape(start, end);
    }
    return null;
  }

  static Shape? _detectCircle(List<Offset> points) {
    final center = _findCentroid(points);
    final distances = points.map((p) => (p - center).distance).toList();
    final avgRadius = distances.reduce((a, b) => a + b) / distances.length;
    final radiusVariance = distances.map((d) => pow(d - avgRadius, 2)).reduce((a, b) => a + b) / distances.length;
    return radiusVariance < 500 ? CircleShape(center, avgRadius) : null;
  }

  static bool _isQuadrilateral(List<Offset> vertices) {
    if (vertices.length != 4) return false;

    for (int i = 0; i < 4; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % 4];
      final p3 = vertices[(i + 2) % 4];

      if (_areColinear(p1, p2, p3)) return false;
    }
    return true;
  }

  static bool _areColinear(Offset a, Offset b, Offset c) {
    return ((b.dy - a.dy) * (c.dx - b.dx) - (b.dx - a.dx) * (c.dy - b.dy)).abs() < 1e-6;
  }

  static Shape? _detectPolygon(List<Offset> points) {
    final simplified = _ramerDouglasPeucker(points, 3.0);
    final vertices = _detectVertices(simplified);

    switch (vertices.length) {
      case 3:
        return TriangleShape(vertices[0], vertices[1], vertices[2]);
      case 4:
        if (_isQuadrilateral(vertices)) {
          return _classifyQuadrilateral(vertices);
        }
        return PolygonShape(vertices);
      case 5:
        return PolygonShape(vertices);
      case 6:
        return PolygonShape(vertices);
    }
    return null;
  }

  static Shape? _classifyQuadrilateral(List<Offset> vertices) {
    final angles = _calculateAngles(vertices);
    final sides = _calculateSideLengths(vertices);
    if (angles.every((a) => (a - 90).abs() < 25)) {
      final sorted = vertices.map((v) => v.dx).toList()..sort();
      final width = sorted.last - sorted.first;
      final sortedY = vertices.map((v) => v.dy).toList()..sort();
      final height = sortedY.last - sortedY.first;

      return RectangleShape(
          Offset(sorted.first, sortedY.first),
          width,
          height
      );
    }
    if ((sides[0] - sides[2]).abs() < 5 && (sides[1] - sides[3]).abs() < 5) {
      return PolygonShape(vertices);
    }
    return PolygonShape(vertices);
  }

  static List<double> _calculateAngles(List<Offset> vertices) {
    List<double> angles = [];
    for (int i = 0; i < vertices.length; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % vertices.length];
      final p3 = vertices[(i + 2) % vertices.length];
      angles.add(_calculateAngle(p1, p2, p3));
    }
    return angles;
  }

  static List<double> _calculateSideLengths(List<Offset> vertices) {
    return List.generate(vertices.length,
            (i) => (vertices[i] - vertices[(i+1)%vertices.length]).distance);
  }

  static List<Offset> _detectVertices(List<Offset> points) {
    List<Offset> vertices = [];
    for (int i = 1; i < points.length - 1; i++) {
      final angle = _calculateAngle(points[i-1], points[i], points[i+1]);
      if (angle < 150) vertices.add(points[i]);
    }
    return vertices;
  }

  static double _calculateAngle(Offset a, Offset b, Offset c) {
    final ba = a - b;
    final bc = c - b;
    final dot = ba.dx * bc.dx + ba.dy * bc.dy;
    final magBA = sqrt(ba.dx * ba.dx + ba.dy * ba.dy);
    final magBC = sqrt(bc.dx * bc.dx + bc.dy * bc.dy);
    return acos(dot / (magBA * magBC)) * 180 / pi;
  }

  static List<Offset> _ramerDouglasPeucker(List<Offset> points, double epsilon) {
    if (points.length < 3) return points;

    int index = 0;
    double dmax = 0;
    final end = points.length - 1;

    for (int i = 1; i < end; i++) {
      double d = _perpendicularDistance(points[i], points[0], points[end]);
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    if (dmax > epsilon) {
      final rec1 = _ramerDouglasPeucker(points.sublist(0, index + 1), epsilon);
      final rec2 = _ramerDouglasPeucker(points.sublist(index), epsilon);
      return [...rec1.sublist(0, rec1.length - 1), ...rec2];
    }
    return [points[0], points[end]];
  }

  static double _perpendicularDistance(Offset p, Offset a, Offset b) {
    final nom = ((b.dy - a.dy) * p.dx - (b.dx - a.dx) * p.dy + b.dx * a.dy - b.dy * a.dx).abs();
    final den = sqrt(pow(b.dy - a.dy, 2) + pow(b.dx - a.dx, 2));
    return nom / den;
  }

  static Offset _findCentroid(List<Offset> points) {
    double x = 0, y = 0;
    for (var p in points) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / points.length, y / points.length);
  }


  static double _pointLineDistance(Offset a, Offset b, Offset p) {
    double num = ((b.dy - a.dy) * p.dx - (b.dx - a.dx) * p.dy + b.dx * a.dy - b.dy * a.dx).abs();
    double den = (b - a).distance;
    return num / den;
  }
}

class RectangleShape extends Shape {
  final Offset topLeft;
  final double width;
  final double height;

  RectangleShape(this.topLeft, this.width, this.height);

  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(topLeft.dx, topLeft.dy, width, height), paint);
  }
}

class TriangleShape extends Shape {
  final Offset p1, p2, p3;

  TriangleShape(this.p1, this.p2, this.p3);

  @override
  void draw(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    canvas.drawPath(path, paint);
  }
}

class PolygonShape extends Shape {
  final List<Offset> vertices;
  PolygonShape(this.vertices);

  @override
  void draw(Canvas canvas, Paint paint) {
    final path = Path()..moveTo(vertices[0].dx, vertices[0].dy);
    for (var vertex in vertices.skip(1)) {
      path.lineTo(vertex.dx, vertex.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
