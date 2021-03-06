part of plotter;

/// A plotter item for points.
class Points extends BasicCoordsItem {
  /// Creates a points plotter item.
  Points() : super._(2);

  List<double> get _x => this._coords[0];
  List<double> get _y => this._coords[1];

  /// Draws the group to the panel.
  void _onDraw(IRenderer r) =>
    r.drawPoints(this._x, this._y);

  /// Gets the bounds for the item.
  Bounds _onGetBounds(Transformer trans) {
    Bounds b = new Bounds.empty();
    for (int i = this.count - 1; i >= 0; --i) b.expand(this._x[i], this._y[i]);
    return trans.transform(b);
  }
}
