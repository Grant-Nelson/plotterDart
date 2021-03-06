part of plotSvg;

/// A renderer for drawing SVG plots.
class Renderer extends IRenderer {
  /// SVG validator for adding HTML.
  html.NodeValidatorBuilder _svgValidator;

  /// SVG tree sanitizer for adding HTML.
  html.NodeTreeSanitizer _treeSanitizer;

  /// The element to add graphics to.
  svg.SvgSvgElement _svg;

  /// The buffer to temporarily store SVG while drawing.
  StringBuffer _sout;

  /// The bounds of the panel.
  Bounds _window;

  /// The bounds of the data.
  Bounds _dataBounds;

  /// The current transformer for the plot.
  Transformer _trans;

  /// The current point size.
  double _pointSize;

  /// The current background color.
  Color _backClr;

  /// The current line color.
  Color _lineClr;

  /// The CSS draw color currently set.
  String _lineClrStr;

  /// The CSS draw color currently set.
  String _pointClrStr;

  /// The current fill color or null for no fill.
  Color _fillClr;

  /// The CSS fill color currently set.
  String _fillClrStr;
  
  /// The current font to draw text with.
  String _font;

  /// The flag indicating if lines should be drawn directed.
  bool _lineDir;

  /// Creates a new renderer.
  Renderer._(this._svg, [bool validateSVG = false]) {
    if (validateSVG) {
      this._svgValidator = new html.NodeValidatorBuilder()..allowSvg();
      this._treeSanitizer = null;
    } else {
      this._svgValidator = null;
      this._treeSanitizer = html.NodeTreeSanitizer.trusted;
    }
    this._sout = new StringBuffer();
    this._dataBounds = new Bounds.empty();
    this._pointSize = 0.0;
    this._backClr = new Color(1.0, 1.0, 1.0);
    this.color = new Color(0.0, 0.0, 0.0);
    this.fillColor = null;
    this._font = "Verdana";
    this._lineDir = false;
  }

  /// Reset the renderer and clears the panel to white.
  void reset(Bounds window, Transformer trans) {
    this._window = window;
    this._trans = trans;
    this._svg.nodes.clear();
    this._svg.attributes["viewBox"] = "0 0 ${this._window.width} ${this._window.height}";
    this._svg.style.backgroundColor = this._getColorString(this._backClr);
    this._sout.clear();
  }

  /// The data bounds.
  Bounds get dataBounds => this._dataBounds;
  set dataBounds(Bounds dataBounds) => this._dataBounds = dataBounds;

  /// Gets the bounds of the panel being drawn on.
  Bounds get window => this._window;

  /// Gets the viewport into the window with the given transformation.
  Bounds get viewport => this._trans.untransform(this._window);

  /// The transformer for the current data.
  Transformer get transform => this._trans;
  set transform(Transformer trans) => this._trans = trans;

  /// The point size to draw points with.
  double get pointSize => this._pointSize;
  set pointSize(double size) => this._pointSize = size;

  /// The background color to clear to.
  Color get backgroundColor => this._backClr;
  void set backgroundColor(Color color) => this._backClr = color;

  /// The color to draw lines with.
  Color get color => this._lineClr;
  void set color(Color color) {
    this._lineClr = color;
    String drawClr = this._getColorString(color);
    this._lineClrStr = "stroke=\"$drawClr\" stroke-opacity=\"${color.alpha}\" ";
    this._pointClrStr = "fill=\"$drawClr\" fill-opacity=\"${color.alpha}\" ";
  }

  /// The color to fill shapes with.
  Color get fillColor => this._fillClr;
  void set fillColor(Color color) {
    this._fillClr = color;
    if (color != null) {
      String fillClr = this._getColorString(color);
      this._fillClrStr = "fill=\"$fillClr\" fill-opacity=\"${color.alpha}\" ";
    } else this._fillClrStr = "fill=\"none\" ";
  }

  /// The font to draw text with.
  String get font => this._font;
  void set font(String font) => this._font = font;

  /// Indicates if the lines should be drawn directed (with arrows), or not.
  bool get directedLines => this._lineDir;
  set directedLines(bool directed) => this._lineDir = directed;

  /// Draws text to the viewport.
  void drawText(double x, double y, double size, String text, bool scale) {
    if (scale) {
      double x2 = this._transX(x + size);
      x = this._transX(x);
      y = this._transY(y);
      size = (x2 - x).abs();
    }

    this._sout.write("<text x=\"$x\" y=\"$y\" style=\"font-family: ${this._font}; font-size: ${size}px;\" ");
    this._sout.writeln("${this._lineClrStr}${this._fillClrStr}>${text}</text>");
  }

  /// Draws a point to the viewport.
  void drawPoint(double x, double y) {
    x = this._transX(x);
    y = this._transY(y);
    double r = (this._pointSize <= 1.0) ? 1.0 : this._pointSize;
    this._writePoint(x, y, r);
  }

  /// Draws a set of points to the viewport.
  void drawPoints(List<double> xCoords, List<double> yCoords) {
    assert(xCoords.length == yCoords.length);
    for (int i = xCoords.length - 1; i >= 0; --i)
      this.drawPoint(xCoords[i], yCoords[i]);
  }

  /// Draws a line to the viewport.
  void drawLine(double x1, double y1, double x2, double y2) {
    double tx1 = this._transX(x1);
    double ty1 = this._transY(y1);
    double tx2 = this._transX(x2);
    double ty2 = this._transY(y2);
    this._drawTransLine(x1, y1, x2, y2, tx1, ty1, tx2, ty2);

    if (_pointSize > 1.0) {
      this.drawPoint(x1, y1);
      this.drawPoint(x2, y2);
    }
  }

  /// Draws a line to the viewport with pre-translated coordinates.
  void _drawTransLine(double x1, double y1, double x2, double y2, double tx1, double ty1, double tx2, double ty2) {
    this._writeLine(tx1, ty1, tx2, ty2);
    if (this._lineDir) {
      double dx = x2 - x1;
      double dy = y2 - y1;
      double length = math.sqrt((dx * dx) + (dy * dy));
      if (length > 1.0e-12) {
        dx /= length;
        dy /= length;
        double width = 6.0;
        double height = 4.0;
        double tx3 = tx2 - dx * width;
        double dx3 = dy * height;
        double ty3 = ty2 + dy * width;
        double dy3 = dx * height;
        this._writeLine(tx2, ty2, tx3 + dx3, ty3 + dy3);
        this._writeLine(tx2, ty2, tx3 - dx3, ty3 - dy3);
      }
    }
  }

  /// Draws a set of lines to the viewport.
  void drawLines(List<double> x1Coords, List<double> y1Coords, List<double> x2Coords, List<double> y2Coords) {
    assert(x1Coords.length == y1Coords.length);
    assert(x1Coords.length == x2Coords.length);
    assert(x1Coords.length == y2Coords.length);
    for (int i = x1Coords.length - 1; i >= 0; --i)
      this.drawLine(x1Coords[i], y1Coords[i], x2Coords[i], y2Coords[i]);
  }

  /// Draws a rectangle to the viewport.
  void drawRect(double x1, double y1, double x2, double y2) {
    x1 = this._transX(x1);
    y1 = this._transY(y1);
    x2 = this._transX(x2);
    y2 = this._transY(y2);
    double width  = x2 - x1;
    double height = y1 - y2;
    this._writeRect(x1, y2, width, height);
  }

  /// Draws a set of rectangles to the viewport.
  void drawRects(List<double> xCoords, List<double> yCoords, List<double> widths, List<double> heights) {
    assert(xCoords.length == yCoords.length);
    assert(xCoords.length == widths.length);
    assert(xCoords.length == heights.length);
    for (int i = xCoords.length - 1; i >= 0; --i) {
      double x = xCoords[i];
      double y = yCoords[i];
      this.drawRect(x, y, x + widths[i], y + heights[i]);
    }
  }

  /// Draws a set of rectangles to the viewport.
  void drawRectSet(List<double> xCoords, List<double> yCoords, double width, double height) {
    assert(xCoords.length == yCoords.length);
    for (int i = xCoords.length - 1; i >= 0; --i) {
      double x = xCoords[i];
      double y = yCoords[i];
      this.drawRect(x, y, x + width, y + height);
    }
  }

  /// Draws an ellipse to the viewport.
  void _drawEllipse(double x1, double y1, double x2, double y2) {
    x1 = this._transX(x1);
    y1 = this._transY(y1);
    x2 = this._transX(x2);
    y2 = this._transY(y2);
    if (x1 > x2) {
      double temp = x1;
      x1 = x2;
      x2 = temp;
    }
    if (y1 > y2) {
      double temp = y1;
      y1 = y2;
      y2 = temp;
    }
    double rx = (x2 - x1).abs() * 0.5;
    double ry = (y2 - y1).abs() * 0.5;
    double cx = x1 + rx;
    double cy = y1 + ry;
    this._writeEllipse(cx, cy, rx, ry);
  }

  /// Draws a set of ellipses to the viewport.
  void drawEllipse(List<double> xCoords, List<double> yCoords, List<double> xRadii, List<double> yRadii) {
    assert(xCoords.length == yCoords.length);
    assert(xCoords.length == xRadii.length);
    assert(xCoords.length == yRadii.length);
    for (int i = xCoords.length - 1; i >= 0; --i) {
      double xr = xRadii[i];
      double yr = yRadii[i];
      double x = xCoords[i];
      double y = yCoords[i];
      this._drawEllipse(x - xr, y - yr, x + xr, y + yr);
    }
  }

  /// Draws a set of ellipses to the viewport.
  void drawEllipseSet(List<double> xCoords, List<double> yCoords, double xRadius, double yRadius) {
    assert(xCoords.length == yCoords.length);
    for (int i = xCoords.length - 1; i >= 0; --i) {
      double x = xCoords[i];
      double y = yCoords[i];
      this._drawEllipse(x - xRadius, y - yRadius, x + xRadius, y + yRadius);
    }
  }

  /// Draws a set of circles to the viewport.
  void drawCircs(List<double> xCoords, List<double> yCoords, List<double> radii) {
    assert(xCoords.length == yCoords.length);
    assert(xCoords.length == radii.length);
    for (int i = xCoords.length - 1; i >= 0; --i) {
      double r = radii[i];
      double cx = xCoords[i];
      double cy = yCoords[i];
      double x2 = this._transX(cx + r);
      double y2 = this._transY(cy + r);
      cx = this._transX(cx);
      cy = this._transY(cy);
      double rx = (x2 - cx).abs();
      double ry = (y2 - cy).abs();
      this._writeEllipse(cx, cy, rx, ry);
    }
  }

  /// Draws a set of circles to the viewport.
  void drawCircSet(List<double> xCoords, List<double> yCoords, double radius) {
    assert(xCoords.length == yCoords.length);
    for (int i = xCoords.length - 1; i >= 0; --i) {
      double cx = xCoords[i];
      double cy = yCoords[i];
      double x2 = this._transX(cx + radius);
      double y2 = this._transY(cy + radius);
      cx = this._transX(cx);
      cy = this._transY(cy);
      double rx = (x2 - cx).abs();
      double ry = (y2 - cy).abs();
      this._writeEllipse(cx, cy, rx, ry);
    }
  }

  /// Draws a polygon to the viewport.
  void drawPoly(List<double> xCoords, List<double> yCoords) {
    assert(xCoords.length == yCoords.length);
    int count = xCoords.length;
    if (count >= 3) {
      double x = this._transX(xCoords[0]);
      double y = this._transY(yCoords[0]);
      this._sout.write("<polygon points=\"$x,$y");
      for (int i = 1; i < count; ++i) {
        x = this._transX(xCoords[i]);
        y = this._transY(yCoords[i]);
        this._sout.write(" $x,$y");
      }
      this._sout.writeln("\" $_fillClrStr$_lineClrStr/>");

      if (this._lineDir) {
        double x1 = xCoords[count - 1];
        double y1 = yCoords[count - 1];
        double tx1 = this._transX(x1);
        double ty1 = this._transY(y1);
        for (int i = 0; i < count; ++i) {
          double x2 = xCoords[i];
          double y2 = yCoords[i];
          double tx2 = this._transX(x2);
          double ty2 = this._transY(y2);
          this._drawTransLine(x1, y1, x2, y2, tx1, ty1, tx2, ty2);
          x1 = x2;
          y1 = y2;
          tx1 = tx2;
          ty1 = ty2;
        }
      }
    }

    if (this._pointSize > 1.0)
      this.drawPoints(xCoords, yCoords);
  }

  /// Draws a line strip to the viewport.
  void drawStrip(List<double> xCoords, List<double> yCoords) {
    assert(xCoords.length == yCoords.length);
    int count = xCoords.length;
    if (count >= 2) {
      double x = this._transX(xCoords[0]);
      double y = this._transY(yCoords[0]);
      this._sout.write("<polyline points=\"$x,$y");
      for (int i = 1; i < count; ++i) {
        x = this._transX(xCoords[i]);
        y = this._transY(yCoords[i]);
        this._sout.write(" $x,$y");
      }
      this._sout.writeln("\" fill=\"none\" $_lineClrStr/>");

      if (this._lineDir) {
        double x1 = xCoords[0];
        double y1 = yCoords[0];
        double tx1 = this._transX(x1);
        double ty1 = this._transY(y1);
        for (int i = 1; i < count; ++i) {
          double x2 = xCoords[i];
          double y2 = yCoords[i];
          double tx2 = this._transX(x2);
          double ty2 = this._transY(y2);
          this._drawTransLine(x1, y1, x2, y2, tx1, ty1, tx2, ty2);
          x1 = x2;
          y1 = y2;
          tx1 = tx2;
          ty1 = ty2;
        }
      }
    }

    if (_pointSize > 1.0)
      this.drawPoints(xCoords, yCoords);
  }

  /// Finishes the render and applies the SVG.
  void finalize() =>
    this._svg.setInnerHtml(_sout.toString(), validator: _svgValidator, treeSanitizer: _treeSanitizer);

  /// Translates the given x value by the current transformer.
  double _transX(double x) =>
    this._trans.transformX(x);

  /// Translates the given y value by the current transformer.
  double _transY(double y) =>
    this._window.ymax - this._trans.transformY(y);

  /// Gets the SVG color string for the given color.
  String _getColorString(Color color) {
    int r = (color.red   * 255.0).floor();
    int g = (color.green * 255.0).floor();
    int b = (color.blue  * 255.0).floor();
    return "rgb($r, $g, $b)";
  }

  /// Writes a point SVG to the buffer.
  void _writePoint(double x, double y, double r) =>
    this._sout.writeln("<circle cx=\"$x\" cy=\"$y\" r=\"$r\" ${this._pointClrStr} />");

  /// Writes a line SVG to the buffer.
  void _writeLine(double x1, double y1, double x2, double y2) =>
    this._sout.writeln("<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" ${this._lineClrStr}/>");

  /// Writes a rectangle SVG to the buffer.
  void _writeRect(double x, double y, double width, double height) =>
    this._sout.writeln("<rect x=\"$x\" y=\"$y\" width=\"$width\" height=\"$height\" ${this._fillClrStr}${this._lineClrStr}/>");

  /// Writes an ellipse SVG to the buffer.
  void _writeEllipse(double cx, double cy, double rx, double ry) =>
    this._sout.writeln("<ellipse cx=\"$cx\" cy=\"$cy\" rx=\"$rx\" ry=\"$ry\" ${this._fillClrStr}${this._lineClrStr}/>");
}
