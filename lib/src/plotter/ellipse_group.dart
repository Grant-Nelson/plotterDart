part of plotter;

/// A plotter item for drawing ellipses.
class EllipseGroup extends PlotterItem {
  /// The x value for the top-left corner points.
  List<double> _xCoords;

  /// The y value for the top-left corner points.
  List<double> _yCoords;

  /// The width of all the ellipses.
  double _width;

  /// The height of all the ellipses.
  double _height;

  /// Creates a new ellipse plotter item.
  EllipseGroup(this._width, this._height) {
    _xCoords = new List<double>();
    _yCoords = new List<double>();
  }

  /// The width for all the ellipses.
  double get width => _width;
  set width(double width) => _width = width;

  /// The height for all the ellipses.
  double get height => _height;
  set height(double height) => _height = height;

  /// Adds ellipses to this plotter item.
  void add(List<double> val) {
    int count = val.length;
    for (int i = 0; i < count; i += 2) {
      _xCoords.add(val[i]);
      _yCoords.add(val[i + 1]);
    }
  }

  /// The number of ellipses in this item.
  int get count => _xCoords.length;

  /// Draws the group to the panel.
  void _onDraw(IRenderer r) {
    r.drawEllipsSet(_xCoords, _yCoords, _width, _height);
  }

  /// Gets the bounds for the item.
  Bounds _onGetBounds(Transformer trans) {
    Bounds b = new Bounds.empty();
    for (int i = count - 1; i >= 0; --i) b.expand(_xCoords[i], _yCoords[i]);
    if (!b.isEmpty) b.expand(b.xmax + _width, b.ymax + _height);
    return trans.transform(b);
  }
}