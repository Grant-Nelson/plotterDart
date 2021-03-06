part of plotter;

/// The plotter item for plotting a polygon.
class Polygon extends BasicCoordsItem {
  /// Creates a polygon plotter item.
  Polygon() : super._(2);

  List<double> get _x => this._coords[0];
  List<double> get _y => this._coords[1];

  /// Called when the polygon is to be draw.
  void _onDraw(IRenderer r) =>
    r.drawPoly(this._x, this._y);

  /// Gets the bounds for the polygon.
  Bounds _onGetBounds(Transformer trans) {
    Bounds b = new Bounds.empty();
    for (int i = this.count - 1; i >= 0; --i) b.expand(this._x[i], this._y[i]);
    return trans.transform(b);
  }
}
