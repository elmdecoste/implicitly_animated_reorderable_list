import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src.dart';

/// A `Widget` that is used to initiate a drag/reorder of a [Reorderable] inside an
/// [ImplicitlyAnimatedReorderableList].
///
/// A `Handle` must have a [Reorderable] and an [ImplicitlyAnimatedReorderableList]
/// as its ancestor.
class Handle extends StatefulWidget {
  /// The child of this Handle that can initiate a reorder.
  ///
  /// This might for instance be an [Icon] or a [ListTile].
  final Widget child;

  /// The delay between when a pointer touched the [child] and
  /// when the drag is initiated.
  ///
  /// If the Handle wraps the whole item, the delay should be greater
  /// than the default `Duration.zero` as otherwise the list might become unscrollable.
  ///
  /// When the [ImplicitlyAnimatedReorderableList] was scrolled in the mean time,
  /// the reorder will be canceled.
  /// If the [ImplicitlyAnimatedReorderableList] uses a `NeverScrollableScrollPhysics`
  /// the Handle will instead use a parent `Scrollable` if there is one.
  final Duration delay;

  /// Whether to vibrate when a drag has been initiated.
  final bool vibrate;

  /// Whether the handle should capture the pointer event of the drag.
  ///
  /// When this is set to `true`, the `Hanlde` is not allowed to change
  /// the parent between normal and dragged state.
  final bool capturePointer;

  /// Creates a widget that can initiate a drag/reorder of an item inside an
  /// [ImplicitlyAnimatedReorderableList].
  ///
  /// A Handle must have a [Reorderable] and an [ImplicitlyAnimatedReorderableList]
  /// as its ancestor.
  const Handle({
    Key key,
    @required this.child,
    this.delay = Duration.zero,
    this.capturePointer = true,
    this.vibrate = true,
  })  : assert(delay != null),
        assert(child != null),
        assert(vibrate != null),
        super(key: key);

  @override
  _HandleState createState() => _HandleState();
}

class _HandleState extends State<Handle> {
  // A custom handler used to cancel the pending onDragStart callbacks.
  Handler _handler;
  // The parent Reorderable item.
  ReorderableState _reorderable;
  // The parent list.
  ImplicitlyAnimatedReorderableListState _list;
  // Whether the ImplicitlyAnimatedReorderableList has a
  // scrollDirection of Axis.vertical.
  bool get _isVertical => _list?.isVertical ?? true;

  Offset _pointer;
  double _downOffset;
  double _startOffset;
  double _currentOffset;
  double get _delta => (_currentOffset ?? 0) - (_startOffset ?? 0);

  // Use flags from the list as this State object is being
  // recreated between dragged and normal state.
  bool get _inDrag => _list.inDrag ?? false;
  bool get _inReorder => _list.inReorder ?? false;

  void _onDragStarted() {
    // If the list is already in drag we dont want to
    // initiate a new reorder.
    if (_inReorder) return;

    final moveDelta = (_downOffset - _currentOffset).abs();
    if (moveDelta > 10.0) {
      return;
    }

    _disposeParentDrag();
    _startOffset = _currentOffset;

    _list?.onDragStarted(_reorderable?.key);
    _reorderable.rebuild();

    _vibrate();
  }

  void _onDragUpdated(Offset pointer) {
    _list?.onDragUpdated(_delta);
  }

  void _onDragEnded() {
    _handler?.cancel();
    _list?.onDragEnded();
  }

  void _vibrate() {
    if (widget.vibrate) HapticFeedback.mediumImpact();
  }

  void _disposeParentDrag() {
    final parent = Scrollable.of(_list.context);

    // Listener does not capture the drag of this Handle
    // however we also cannot use GestureDetector to capture
    // the drag on the Handle, as this might make the whole
    // list unscrollable (e.g. when the Handle wraps a whole ListTile).
    parent?.position?.jumpTo(parent.position.pixels);
  }

  @override
  Widget build(BuildContext context) {
    _list ??= ImplicitlyAnimatedReorderableList.of(context);
    assert(_list != null,
        'No ancestor ImplicitlyAnimatedReorderableList was found in the hierarchy!');
    _reorderable ??= Reorderable.of(context);
    assert(_reorderable != null, 'No ancestor Reorderable was found in the hierarchy!');

    // Sometimes the cancel callbacks of the GestureDetector
    // are erroneously invoked. Use a plain Listener instead
    // for now.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _onDown(event.localPosition),
      onPointerMove: (event) => _onUpdate(event.localPosition),
      onPointerUp: (_) => _onUp(),
      onPointerCancel: (_) => _onUp(),
      child: widget.capturePointer
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              // Vertical
              onVerticalDragDown: _isVertical && _inDrag ? (_) {} : null,
              onVerticalDragUpdate: _isVertical && _inDrag ? (_) {} : null,
              onVerticalDragEnd: _isVertical && _inDrag ? (_) {} : null,
              onVerticalDragCancel: _isVertical && _inDrag ? () {} : null,
              // Horizontal
              onHorizontalDragDown: !_isVertical && _inDrag ? (_) {} : null,
              onHorizontalDragUpdate: !_isVertical && _inDrag ? (_) {} : null,
              onHorizontalDragEnd: !_isVertical && _inDrag ? (_) {} : null,
              onHorizontalDragCancel: !_isVertical && _inDrag ? () {} : null,
              child: widget.child,
            )
          : widget.child,
    );
  }

  void _onDown(Offset pointer) {
    _pointer = pointer;
    _currentOffset = _offset(_pointer);
    _downOffset = _offset(_pointer);

    // Ensure the list is not already in a reordering
    // state when initiating a new reorder operation.
    if (!_inDrag) {
      _onUp();

      _handler = postDuration(
        widget.delay,
        _onDragStarted,
      );
    }
  }

  void _onUpdate(Offset pointer) {
    _pointer = pointer;
    _currentOffset = _offset(_pointer);

    if (_inDrag && _inReorder) {
      _onDragUpdated(pointer);
    }
  }

  void _onUp() {
    _handler?.cancel();
    if (_inDrag) _onDragEnded();
  }

  double _offset(Offset offset) => _isVertical ? offset.dy : offset.dx;
}
