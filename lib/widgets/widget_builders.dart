import 'package:flutter/material.dart';

typedef ValueStatefulWidgetBuilder<T> = Widget Function(
    BuildContext context, _ValueStatefulBuilderState<T> state);

class ValueStatefulBuilder<T> extends StatefulWidget {
  final T initValue;
  final ValueStatefulWidgetBuilder<T> builder;

  const ValueStatefulBuilder(
      {Key? key, required this.initValue, required this.builder})
      : super(key: key);

  @override
  _ValueStatefulBuilderState<T> createState() =>
      _ValueStatefulBuilderState<T>(initValue);
}

class _ValueStatefulBuilderState<T> extends State<ValueStatefulBuilder<T>> {
  T value;

  _ValueStatefulBuilderState(this.value);

  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, this);
}

/// Make sure all keep-alive widgets won't share the [PrimaryScrollController]
/// If will, assign a unique [ScrollController] to every (at least n-1)
/// scrollable widget who will use [PrimaryScrollController] by default
class KeepAliveBuilder extends StatefulWidget {
  final WidgetBuilder builder;
  final bool wantKeepAlive;

  const KeepAliveBuilder(
      {Key? key, required this.builder, this.wantKeepAlive = true})
      : super(key: key);

  @override
  _KeepAliveBuilderState createState() => _KeepAliveBuilderState(wantKeepAlive);
}

class _KeepAliveBuilderState extends State<KeepAliveBuilder>
    with AutomaticKeepAliveClientMixin {
  bool _wantKeepAlive;

  _KeepAliveBuilderState(this._wantKeepAlive);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.builder(context);
  }

  @override
  bool get wantKeepAlive => _wantKeepAlive;
}

class AutoUnfocusBuilder extends StatelessWidget {
  final WidgetBuilder builder;

  AutoUnfocusBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: builder(context),
    );
  }
}