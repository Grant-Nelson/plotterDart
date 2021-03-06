part of plotter;

/// A plotter item to draw a grid.
class Grid extends PlotterItem {
  /// The closest grid color to the background color.
  Color _backClr;

  /// The heaviest grid color.
  Color _foreClr;

  /// The axis grid color.
  Color _axisClr;

  /// Creates a grid item.
  Grid() {
    this._backClr = new Color(0.9, 0.9, 1.0);
    this._foreClr = new Color(0.5, 0.5, 1.0);
    this._axisClr = new Color(1.0, 0.7, 0.7);
    this.addColor(0.0, 0.0, 0.0);
  }

  /// Gets the smallest power of 10 which is greater than the given value.
  int _getMaxPow(double value) =>
    (math.log(value) / math.ln10).ceil();

  /// Gets the number above the given value in multiples of the given power value.
  double _getUpper(double value, double pow) =>
    (value / pow).ceilToDouble() * pow;

  /// Gets the number below the given value in multiples of the given power value.
  double _getLower(double value, double pow) =>
    (value / pow).floorToDouble() * pow;

  /// Adds a horizontal line at the given offset to the given group.
  void _addHorz(List<double> group, double offset, Bounds window, Bounds view) {
    double y = (offset - view.ymin) * window.height / view.height;
    if ((y > 0.0) && (y < window.height)) group.add(y);
  }

  /// The recursive method used to get a horizontal grid line and children grid lines.
  /// [groups] is the group of horizontal line groups.
  /// [window] is the window being drawn into.
  /// [view] is the viewport of the render space.
  /// [pow] is the minimum power to draw at.
  /// [minOffset] is the minimum offset into the view.
  /// [maxOffset] is the maximum offset into the view.
  /// [rmdPow] is the current offset of the power to get the lines for.
  void _getHorzs(List<List<double>> groups, Bounds window, Bounds view,
      double pow, double minOffset, double maxOffset, int rmdPow) {
    if (rmdPow <= 0) return;
    double lowPow = pow / 10.0;
    double offset = minOffset;
    this._getHorzs(groups, window, view, lowPow, offset, offset + pow, rmdPow - 1);

    if (offset + pow == offset) return;
    List<double> group = groups[rmdPow - 1];
    for (offset += pow; offset < maxOffset; offset += pow) {
      this._addHorz(group, offset, window, view);
      this._getHorzs(groups, window, view, lowPow, offset, offset + pow, rmdPow - 1);
    }
  }

  /// Adds a vertical line at the given offset to the given group.
  void _addVert(List<double> group, double offset, Bounds window, Bounds view) {
    double x = (offset - view.xmin) * window.width / view.width;
    if ((x > 0.0) && (x < window.width)) group.add(x);
  }

  /// The recursive method used to get a vertical grid line and children grid lines.
  /// [groups] is the group of vertical line groups.
  /// [window] is the window being drawn into.
  /// [view] is the viewport of the render space.
  /// [pow] is the minimum power to draw at.
  /// [minOffset] is the minimum offset into the view.
  /// [maxOffset] is the maximum offset into the view.
  /// [rmdPow] is the current offset of the power to get the lines for.
  void _getVerts(List<List<double>> groups, Bounds window, Bounds view,
      double pow, double minOffset, double maxOffset, int rmdPow) {
    if (rmdPow <= 0) return;
    double lowPow = pow / 10.0;
    double offset = minOffset;
    List<double> group = groups[rmdPow - 1];
    this._getVerts(groups, window, view, lowPow, offset, offset + pow, rmdPow - 1);
    for (offset += pow; offset < maxOffset; offset += pow) {
      this._addVert(group, offset, window, view);
      this._getVerts(groups, window, view, lowPow, offset, offset + pow, rmdPow - 1);
    }
  }

  /// Sets the linearly interpolated color used for the grid lines to the renderer.
  void _setColor(IRenderer r, int rmdPow, int diff) {
    double fraction = rmdPow / diff;
    double red   = this._backClr.red   + fraction * (this._foreClr.red   - this._backClr.red);
    double green = this._backClr.green + fraction * (this._foreClr.green - this._backClr.green);
    double blue  = this._backClr.blue  + fraction * (this._foreClr.blue  - this._backClr.blue);
    r.color = new Color(red, green, blue);
  }

  /// Draws the grid lines.
  void _drawGrid(IRenderer r, Bounds window, Bounds view) {
    double minSpacing = 5.0;
    int maxPow = math.max(this._getMaxPow(view.width), this._getMaxPow(view.height));
    int minPow = math.min(this._getMaxPow(view.width  * minSpacing / window.width),
                          this._getMaxPow(view.height * minSpacing / window.height));

    int diff = maxPow - minPow;
    if (diff <= 0) {
      diff = 1;
      maxPow = 1;
      minPow = 0;
    }
    double pow = math.pow(10, maxPow - 1);
    double maxXOffset = this._getUpper(view.xmax, pow);
    double minXOffset = this._getLower(view.xmin, pow);
    double maxYOffset = this._getUpper(view.ymax, pow);
    double minYOffset = this._getLower(view.ymin, pow);

    List<List<double>> horzs = new List<List<double>>();
    List<List<double>> verts = new List<List<double>>();
    for (int i = 0; i < diff; ++i) {
      horzs.add(new List<double>());
      verts.add(new List<double>());
    }
    this._getHorzs(horzs, window, view, pow, minYOffset, maxYOffset, diff);
    this._getVerts(verts, window, view, pow, minXOffset, maxXOffset, diff);

    for (int i = 0; i < diff; ++i) {
      this._setColor(r, i, diff);
      for (double y in horzs[i]) {
        r.drawLine(window.xmin, y, window.xmax, y);
      }
      for (double x in verts[i]) {
        r.drawLine(x, window.ymin, x, window.ymax);
      }
    }
  }

  /// Draws the axis grid lines.
  void _drawAxis(IRenderer r, Bounds window, Bounds view) {
    if ((view.xmin <= 0.0) && (view.xmax >= 0.0)) {
      List<double> group = new List<double>();
      this._addVert(group, 0.0, window, view);
      if (group.length == 1) {
        r.color = this._axisClr;
        double x = group[0];
        r.drawLine(x, window.ymin, x, window.ymax);
      }
    }

    if ((view.ymin <= 0.0) && (view.ymax >= 0.0)) {
      List<double> group = new List<double>();
      this._addHorz(group, 0.0, window, view);
      if (group.length == 1) {
        r.color = this._axisClr;
        double y = group[0];
        r.drawLine(window.xmin, y, window.xmax, y);
      }
    }
  }

  /// Draws the grid item.
  void _onDraw(IRenderer r) {
    Bounds window = r.window;
    Bounds view = r.viewport;
    if (view.width  <= 0.0) return;
    if (view.height <= 0.0) return;

    Transformer last = r.transform;
    r.transform = new Transformer.identity();

    this._drawGrid(r, window, view);
    this._drawAxis(r, window, view);

    r.transform = last;
  }

  /// Get the bounds for the grid.
  Bounds _onGetBounds(Transformer trans) => new Bounds.empty();
}
