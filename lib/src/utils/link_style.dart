import 'dart:math' as math;
import 'dart:ui';

import 'package:diagram_editor/src/utils/vector_utils.dart';
import 'package:flutter/material.dart';

enum ArrowType {
  none,
  arrow,
  pointedArrow,
  pointedArrow1,
  pointedArrow2,
  circle,
  centerCircle,
  semiCircle,
}

enum LineType {
  solid,
  dashed,
  dotted,
}

enum LinkType {
  straight,
  curved,
}

class LinkStyle {
  /// Defines the design of the link's line.
  ///
  /// It can be [LineType.solid], [LineType.dashed] or [LineType.dotted].
  LineType lineType;

  /// Defines the type of the link.
  ///
  /// It can be [LinkType.straight] or [LinkType.curved].
  LinkType linkType;

  /// Defines the design of the link's front arrowhead.
  ///
  /// There are several designs, choose from [ArrowType] enum.
  ArrowType arrowType;

  /// Defines the design of the link's back arrowhead.
  ///
  /// There are several designs, choose from [ArrowType] enum.
  ArrowType backArrowType;

  /// Defines the size of the link's front arrowhead.
  double arrowSize;

  /// Defines the size of the link's back arrowhead.
  double backArrowSize;

  /// Defines the width of the link's line.
  double lineWidth;

  /// Defines the color of the link's line and both arrowheads.
  Color color;

  /// Defines a visual design of a link on the canvas.
  LinkStyle({
    this.linkType = LinkType.curved,
    this.lineType = LineType.solid,
    this.arrowType = ArrowType.none,
    this.backArrowType = ArrowType.none,
    this.arrowSize = 5,
    this.backArrowSize = 5,
    this.lineWidth = 1,
    this.color = Colors.black,
  })  : assert(lineWidth > 0),
        assert(arrowSize > 0);

  Path getArrowTipPath(
    ArrowType arrowType,
    double arrowSize,
    Offset point1,
    Offset point2,
    double scale,
  ) {
    switch (arrowType) {
      case ArrowType.none:
        return Path();
      case ArrowType.arrow:
        return getArrowPath(arrowSize, point1, point2, scale, 1.5);
      case ArrowType.pointedArrow:
        return getArrowPath(arrowSize, point1, point2, scale, 2.5);
      case ArrowType.pointedArrow1:
        return getPointedArrow(arrowSize, point1, point2, scale);
      case ArrowType.pointedArrow2:
        return getPointedArrow(arrowSize, point1, point2, scale);
      case ArrowType.circle:
        return getCirclePath(arrowSize, point1, point2, scale, false);
      case ArrowType.centerCircle:
        return getCirclePath(arrowSize, point1, point2, scale, true);
      case ArrowType.semiCircle:
        return getSemiCirclePath(arrowSize, point1, point2, scale);
    }
  }

  Path getLinePath(Offset point1, Offset point2, double scale) {
    if (linkType == LinkType.curved) {
      switch (lineType) {
        case LineType.solid:
          return getCurvedLinePath(point1, point2, scale);
        case LineType.dashed:
          return getCurveDashedLinePath(point1, point2, scale);
        case LineType.dotted:
          return getCurveDottedLinePath(point1, point2, scale);
      }
    }

    // linkType == LinkType.straight
    switch (lineType) {
      case LineType.solid:
        return getSolidLinePath(point1, point2);
      case LineType.dashed:
        return getDashedLinePath(point1, point2, scale, 16, 16);
      case LineType.dotted:
        return getDashedLinePath(
            point1, point2, scale, lineWidth, lineWidth * 5);
    }
  }

  Path getArrowPath(double arrowSize, Offset point1, Offset point2,
      double scale, double pointed) {
    Offset left = point2 +
        VectorUtils.normalizeVector(
                VectorUtils.getPerpendicularVector(point1, point2)) *
            arrowSize *
            scale -
        VectorUtils.normalizeVector(
                VectorUtils.getDirectionVector(point1, point2)) *
            pointed *
            arrowSize *
            scale;
    Offset right = point2 -
        VectorUtils.normalizeVector(
                VectorUtils.getPerpendicularVector(point1, point2)) *
            arrowSize *
            scale -
        VectorUtils.normalizeVector(
                VectorUtils.getDirectionVector(point1, point2)) *
            pointed *
            arrowSize *
            scale;

    Path path = new Path();

    path.moveTo(point2.dx, point2.dy);
    path.lineTo(left.dx, left.dy);
    path.lineTo(right.dx, right.dy);
    path.close();

    return path;
  }

  Path getCirclePath(double arrowSize, Offset point1, Offset point2,
      double scale, bool isCenter) {
    Path path = new Path();
    if (isCenter) {
      path.addOval(Rect.fromCircle(center: point2, radius: scale * arrowSize));
    } else {
      Offset circleCenter = point2 -
          VectorUtils.normalizeVector(
                  VectorUtils.getDirectionVector(point1, point2)) *
              arrowSize *
              scale;
      path.addOval(
          Rect.fromCircle(center: circleCenter, radius: scale * arrowSize));
    }
    return path;
  }

  Path getPointedArrow(
    double arrowSize,
    Offset point1,
    Offset point2,
    double scale,
  ) {
    // Path path = new Path();

    // double angle = 30;
    // double length = 10;

    // Offset left = point2 +
    //     VectorUtils.normalizeVector(
    //             VectorUtils.getPerpendicularVector(point1, point2)) *
    //         arrowSize *
    //         scale -
    //     VectorUtils.normalizeVector(
    //             VectorUtils.getDirectionVector(point1, point2)) *
    //         length *
    //         scale;

    // Offset right = point2 -
    //     VectorUtils.normalizeVector(
    //             VectorUtils.getPerpendicularVector(point1, point2)) *
    //         arrowSize *
    //         scale -
    //     VectorUtils.normalizeVector(
    //             VectorUtils.getDirectionVector(point1, point2)) *
    //         length *
    //         scale;

    // Offset middle = point2 -
    //     VectorUtils.normalizeVector(
    //             VectorUtils.getDirectionVector(point1, point2)) *
    //         arrowSize *
    //         scale;

    // path.moveTo(point2.dx, point2.dy);
    // path.lineTo(left.dx, left.dy);
    // path.lineTo(middle.dx, middle.dy);
    // path.lineTo(right.dx, right.dy);
    // path.close();

    Path path = Path();

    // double angle = 30;
    // double length = 10;

    // Offset left = point2 +
    //     VectorUtils.normalizeVector(
    //         VectorUtils.getPerpendicularVector(point1, point2)) *
    //         arrowSize *
    //         scale -
    //     VectorUtils.normalizeVector(
    //         VectorUtils.getDirectionVector(point1, point2)) *
    //         length *
    //         scale;

    // Offset right = point2 -
    //     VectorUtils.normalizeVector(
    //         VectorUtils.getPerpendicularVector(point1, point2)) *
    //         arrowSize *
    //         scale -
    //     VectorUtils.normalizeVector(
    //         VectorUtils.getDirectionVector(point1, point2)) *
    //         length *
    //         scale;

    // Offset middle = point2 -
    //     VectorUtils.normalizeVector(
    //         VectorUtils.getDirectionVector(point1, point2)) *
    //         arrowSize *
    //         scale;

    // // Menambahkan kurva Bezier untuk membuat ujung panah menjadi rounded
    // path.moveTo(point2.dx, point2.dy);
    // path.lineTo(left.dx, left.dy);
    // path.quadraticBezierTo(
    //     middle.dx, middle.dy, right.dx, right.dy); // Menambahkan kurva Bezier
    // path.close();

    double length = 10;

    Offset left = point2 +
        VectorUtils.normalizeVector(
                VectorUtils.getPerpendicularVector(point1, point2)) *
            arrowSize *
            scale -
        VectorUtils.normalizeVector(
                VectorUtils.getDirectionVector(point1, point2)) *
            length *
            scale;

    Offset right = point2 -
        VectorUtils.normalizeVector(
                VectorUtils.getPerpendicularVector(point1, point2)) *
            arrowSize *
            scale -
        VectorUtils.normalizeVector(
                VectorUtils.getDirectionVector(point1, point2)) *
            length *
            scale;

    Offset middle = point2 -
        VectorUtils.normalizeVector(
                VectorUtils.getDirectionVector(point1, point2)) *
            arrowSize *
            scale;

    // Menambahkan kurva Bezier untuk membuat ujung panah menjadi rounded
    path.moveTo(point2.dx, point2.dy);
    path.lineTo(left.dx, left.dy);

    // Membuat kurva Bezier kubik untuk membuat ujung panah menjadi rounded
    path.cubicTo(
        middle.dx + (left.dx - middle.dx) / 2,
        middle.dy + (left.dy - middle.dy) / 2,
        middle.dx + (right.dx - middle.dx) / 2,
        middle.dy + (right.dy - middle.dy) / 2,
        right.dx,
        right.dy);

    path.close();

    return path;
  }

  Path getSemiCirclePath(
      double arrowSize, Offset point1, Offset point2, double scale) {
    Path path = new Path();
    Offset circleCenter = point2 -
        VectorUtils.normalizeVector(
                VectorUtils.getDirectionVector(point1, point2)) *
            arrowSize *
            scale;
    path.addArc(
      Rect.fromCircle(center: circleCenter, radius: scale * arrowSize),
      math.pi - math.atan2(point2.dx - point1.dx, point2.dy - point1.dy),
      -math.pi,
    );
    return path;
  }

  double getEndShortening(ArrowType arrowType) {
    double eps = 0.05;
    switch (arrowType) {
      case ArrowType.none:
        return 0;
      case ArrowType.arrow:
        return arrowSize - eps;
      case ArrowType.pointedArrow:
        return (arrowSize * 2) - eps;
      case ArrowType.pointedArrow1:
        return (arrowSize * 2) - eps;
      case ArrowType.pointedArrow2:
        return (arrowSize * 2) - eps;
      case ArrowType.circle:
        return arrowSize - eps;
      case ArrowType.centerCircle:
        return 0;
      case ArrowType.semiCircle:
        return arrowSize - eps;
    }
  }

  Path getCurvedLinePath(Offset point1, Offset point2, double scale) {
    Path path = new Path();
    path.moveTo(point1.dx, point1.dy);

    Offset middle = point1 + (point2 - point1) * 0.5;
    Offset control1 = Offset(middle.dx, point1.dy);
    Offset control2 = Offset(middle.dx, point2.dy);

    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      point2.dx,
      point2.dy,
    );

    // path = ArrowPath.addTip(
    //   path,
    //   tipLength: 10,
    //   tipAngle: math.pi / 6,
    // );

    return path;
  }

  Path getSolidLinePath(Offset point1, Offset point2) {
    Path path = new Path();
    path.moveTo(point1.dx, point1.dy);
    path.lineTo(point2.dx, point2.dy);
    return path;
  }

  Path getCurveDashedOrDottedLinePath(Offset point1, Offset point2,
      double scale, double dashLength, double dashSpace) {
    var curvePath = getCurvedLinePath(point1, point2, scale);

    Path path = new Path();
    PathMetrics pathMetrics = curvePath.computeMetrics();

    for (PathMetric pathMetric in pathMetrics) {
      double currentDistance = 0;
      while (currentDistance < pathMetric.length) {
        Path extractPath = pathMetric.extractPath(
          currentDistance,
          currentDistance + dashLength * scale,
        );
        path.addPath(extractPath, Offset.zero);
        currentDistance += dashLength * scale + dashSpace * scale;
      }
    }

    return path;
  }

  Path getDashedLinePath(
    Offset point1,
    Offset point2,
    double scale,
    double dashLength,
    double dashSpace,
  ) {
    Path path = new Path();

    Offset normalized = VectorUtils.normalizeVector(
        VectorUtils.getDirectionVector(point1, point2));
    double lineDistance = (point2 - point1).distance;
    Offset currentPoint = Offset(point1.dx, point1.dy);

    double dash = dashLength * scale;
    double space = dashSpace * scale;
    double currentDistance = 0;
    while (currentDistance < lineDistance) {
      path.moveTo(currentPoint.dx, currentPoint.dy);
      currentPoint = currentPoint + normalized * dash;

      if (currentDistance + dash > lineDistance) {
        path.lineTo(point2.dx, point2.dy);
      } else {
        path.lineTo(currentPoint.dx, currentPoint.dy);
      }
      currentPoint = currentPoint + normalized * space;

      currentDistance += dash + space;
    }

    path.moveTo(
      point2.dx - normalized.dx * lineWidth * scale,
      point2.dy - normalized.dy * lineWidth * scale,
    );
    path.lineTo(point2.dx, point2.dy);
    return path;
  }

  Path getCurveDashedLinePath(Offset point1, Offset point2, double scale) {
    return getCurveDashedOrDottedLinePath(point1, point2, scale, 16, 16);
  }

  Path getDottedLinePath(Offset point1, Offset point2, double scale) {
    return getDashedLinePath(point1, point2, scale, lineWidth, lineWidth * 5);
  }

  Path getCurveDottedLinePath(Offset point1, Offset point2, double scale) {
    return getCurveDashedOrDottedLinePath(
        point1, point2, scale, lineWidth, lineWidth * 5);
  }

  LinkStyle.fromJson(Map<String, dynamic> json)
      : linkType = LinkType.values[json['link_type']],
        lineType = LineType.values[json['line_type']],
        arrowType = ArrowType.values[json['arrow_type']],
        backArrowType = ArrowType.values[json['back_arrow_type']],
        arrowSize = json['arrow_size'],
        backArrowSize = json['back_arrow_size'],
        lineWidth = json['line_width'],
        color = Color(int.parse(json['color'], radix: 16));

  Map<String, dynamic> toJson() => {
        'link_type': linkType.index,
        'line_type': lineType.index,
        'arrow_type': arrowType.index,
        'back_arrow_type': backArrowType.index,
        'arrow_size': arrowSize,
        'back_arrow_size': backArrowSize,
        'line_width': lineWidth,
        'color': color.toString().split('(0x')[1].split(')')[0],
      };
}
