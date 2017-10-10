part of plotter;

/// An attribute for setting the point size.
class PointSizeAttr extends IAttribute {
  /// The size of the point to set.
  double _size;

  /// The previous size of the point to store.
  double _last;

  /// Creates a new point size attribute.
  PointSizeAttr(this._size) {
    _last = 0.0;
  }

  /// The size of the point for this attribute.
  double get size => _size;
  set size(double size) => _size = size;

  /// Pushes the attribute to the renderer.
  void _pushAttr(IRenderer r) {
    _last = r.pointSize;
    r.pointSize = _size;
  }

  /// Pops the attribute from the renderer.
  void _popAttr(IRenderer r) {
    r.pointSize = _last;
  }
}
