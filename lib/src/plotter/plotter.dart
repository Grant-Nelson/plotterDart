library plotter;

import 'dart:math' as math;

part 'attributes/color_attr.dart';
part 'attributes/directed_line_attr.dart';
part 'attributes/fill_color_attr.dart';
part 'attributes/font_attr.dart';
part 'attributes/point_size_attr.dart';
part 'attributes/trans_attr.dart';

part 'items/base_coords_item.dart';
part 'items/circle_group.dart';
part 'items/circles.dart';
part 'items/data_bounds.dart';
part 'items/ellipse_group.dart';
part 'items/ellipses.dart';
part 'items/grid.dart';
part 'items/lines.dart';
part 'items/line_strip.dart';
part 'items/points.dart';
part 'items/polygon.dart';
part 'items/rectangle_group.dart';
part 'items/rectangles.dart';
part 'items/text.dart';

part 'mouse/coords.dart';
part 'mouse/crosshairs.dart';
part 'mouse/pan.dart';

part 'iplot.dart';
part 'bounds.dart';
part 'color.dart';
part 'group.dart';
part 'iattribute.dart';
part 'imouse_handle.dart';
part 'irenderer.dart';
part 'plotter_item.dart';
part 'transformer.dart';

/// minimum plotter zoom value.
const double _minZoom = 1.0e-6;

/// maximum plotter zoom value.
const double _maxZoom = 1.0e+6;

/// The plotter to quickly draw 2D plots.
/// Great for reviewing data and debugging 2D algorithms.
///
/// Example:
///   Plotter plot = new Plotter();
///   plot.addLines([12.1, 10.1, 10.9, 10.1,
///                  10.9, 11.1,  6.9, 10.9,
///                  10.9, 10.9, 10.1, 13.9,
///                  10.1,  4.9, 10.1, 10.1]);
///   plot.addPoints([12.1, 10.1,   10.9, 10.1,
///                   10.9, 11.1,    6.9, 10.9,
///                   10.9, 10.9,   10.1, 13.9,
///                   10.1,  4.9,   10.1, 10.1])
///                 ..addPointSize(4.0);
///   plot.updateBounds();
///   plot.focusOnData();
class Plotter extends Group {
  /// The data bounds for the item's data.
  Bounds _bounds;

  /// The transformer from the window to the view.
  Transformer _viewTrans;

  /// The set of mouse handles.
  List<IMouseHandle> _msHndls;

  /// Creates a new plotter.
  Plotter([String label = ""]) : super(label) {
    this._bounds = new Bounds.empty();
    this._viewTrans = new Transformer.identity();
    this.add([new Grid(), new DataBounds()]);
    this._msHndls = new List<IMouseHandle>()
      ..add(new MousePan(this, new MouseButtonState(0)));
    this.addColor(0.0, 0.0, 0.0);
  }

  /// Focuses on the data.
  /// Note: May need to call updateBounds before this if the data has changed.
  void focusOnData() => this.focusOnBounds(this._bounds);

  /// Focuses the view to the given bounds.
  void focusOnBounds(Bounds bounds, [double scalar = 0.95]) {
    this._viewTrans.reset();
    if (!bounds.isEmpty) {
      double scale = scalar / math.max(bounds.width, bounds.height);
      this._viewTrans.setScale(scale, scale);
      this._viewTrans.setOffset(-0.5 * (bounds.xmin + bounds.xmax) * scale,
                                -0.5 * (bounds.ymin + bounds.ymax) * scale);
    }
  }

  /// Updates the bounds of the data.
  /// This should be called whenever the data has changed.
  void updateBounds() {
    this._bounds = _onGetBounds(this._viewTrans);
  }

  /// Renders the plot with the given renderer.
  void render(IRenderer r) {
    r.dataBounds = this._bounds;
    Transformer trans = r.transform;
    trans = trans.mul(this._viewTrans);
    r.transform = trans;
    this.draw(r);
  }

  /// Gets the list of mouse handles,
  List<IMouseHandle> get MouseHandles => this._msHndls;

  /// The transformation from window space to view space.
  Transformer get view => this._viewTrans;
  set view(Transformer view) => this._viewTrans = view;

  /// Sets the offset of the view transformation.
  void setViewOffset(double x, double y) => this._viewTrans.setOffset(x, y);

  /// Sets the view transformation zoom.
  /// Note: This is 10 to the power of the given value, such that 0 is x1.0 zoom.
  void setViewZoom(double pow) {
    double scale = math.pow(10.0, pow);
    this._viewTrans.setScale(scale, scale);
  }

  /// Handles mouse down events.
  void onMouseDown(MouseEvent e) {
    for (IMouseHandle hndl in this._msHndls) hndl.mouseDown(e);
  }

  /// Handles mouse move events.
  void onMouseMove(MouseEvent e) {
    for (IMouseHandle hndl in this._msHndls) hndl.mouseMove(e);
  }

  /// Handles mouse up events.
  void onMouseUp(MouseEvent e) {
    for (IMouseHandle hndl in this._msHndls) hndl.mouseUp(e);
  }

  /// Handles mouse wheel move events.
  void onMouseWheel(MouseEvent e, double dw) {
    double prev = math.max(this._viewTrans.xScalar, this._viewTrans.yScalar);
    double scale = math.pow(10.0, math.log(prev) / math.ln10 - dw);

    if (scale < _minZoom)      scale = _minZoom;
    else if (scale > _maxZoom) scale = _maxZoom;

    double x = e.px;
    double y = e.py;
    double dx = (this._viewTrans.dx - x) * (scale / prev) + x;
    double dy = (this._viewTrans.dy - y) * (scale / prev) + y;

    this._viewTrans.setOffset(dx, dy);
    this._viewTrans.setScale(scale, scale);
    e.redraw = true;
  }
}
