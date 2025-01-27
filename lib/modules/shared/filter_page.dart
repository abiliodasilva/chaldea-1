import 'package:chaldea/components/datatypes/datatypes.dart';
import 'package:chaldea/generated/l10n.dart';
import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';

export 'package:chaldea/app/modules/common/filter_page_base.dart';

// for filter items
typedef FilterCallBack<T> = bool Function(T data);

class FilterGroup extends StatelessWidget {
  final Widget? title;
  final List<String> options;
  final FilterGroupData values;
  final Widget Function(String value)? optionBuilder;
  final bool showMatchAll;
  final bool showInvert;
  final bool useRadio;
  final bool shrinkWrap;
  final void Function(FilterGroupData optionData)? onFilterChanged;

  final bool combined;
  final EdgeInsetsGeometry padding;
  final bool showCollapse;

  const FilterGroup({
    Key? key,
    this.title,
    required this.options,
    required this.values,
    this.optionBuilder,
    this.showMatchAll = false,
    this.showInvert = false,
    this.useRadio = false,
    this.shrinkWrap = false,
    this.onFilterChanged,
    this.combined = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.showCollapse = false,
  }) : super(key: key);

  Widget _buildCheckbox(
      BuildContext context, bool checked, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            color: Colors.grey,
          ),
          Text(text)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _optionChildren = [];
    for (int index = 0; index < options.length; index++) {
      String key = options[index];
      _optionChildren.add(FilterOption(
        selected: values.options[key] ?? false,
        value: key,
        child: optionBuilder == null ? Text(key) : optionBuilder!(key),
        shrinkWrap: shrinkWrap,
        borderRadius: combined
            ? BorderRadius.horizontal(
                left: Radius.circular(index == 0 ? 3 : 0),
                right: Radius.circular(index == options.length - 1 ? 3 : 0),
              )
            : BorderRadius.circular(3),
        onChanged: (v) {
          if (useRadio) {
            values.options.clear();
            values.options[key] = true;
          } else {
            values.options[key] = v;
            values.options.removeWhere((k, v) => v != true);
          }
          if (onFilterChanged != null) {
            onFilterChanged!(values);
          }
        },
      ));
    }

    Widget child = Wrap(
      spacing: combined ? 0 : 6,
      runSpacing: 3,
      children: _optionChildren,
    );

    Widget _getTitle([Widget? expandIcon]) {
      return CustomTile(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: DefaultTextStyle.merge(
              child: title!, style: const TextStyle(fontSize: 14)),
        ),
        contentPadding: EdgeInsets.zero,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (showMatchAll)
              _buildCheckbox(
                  context, values.matchAll, S.current.filter_match_all, () {
                values.matchAll = !values.matchAll;
                if (onFilterChanged != null) {
                  onFilterChanged!(values);
                }
              }),
            if (showInvert)
              _buildCheckbox(context, values.invert, S.current.filter_revert,
                  () {
                values.invert = !values.invert;
                if (onFilterChanged != null) {
                  onFilterChanged!(values);
                }
              }),
            if (expandIcon != null) expandIcon,
          ],
        ),
      );
    }

    Widget _wrapExpandIcon(Widget _child) {
      return ValueStatefulBuilder<bool>(
        initValue: true,
        builder: (context, state) {
          Widget? expandIcon;
          if (showCollapse) {
            expandIcon = ExpandIcon(
              isExpanded: state.value,
              onPressed: (v) {
                state.value = !state.value;
                state.updateState();
              },
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _getTitle(expandIcon),
              if (state.value) _child,
            ],
          );
        },
      );
    }

    if (title != null) {
      if (showCollapse) {
        child = _wrapExpandIcon(child);
      } else {
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _getTitle(),
            child,
          ],
        );
      }
    }

    return Padding(padding: padding, child: child);
  }
}

class FilterOption<T> extends StatelessWidget {
  final bool selected;
  final T value;
  final Widget? child;
  final ValueChanged<bool>? onChanged;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final BorderRadius borderRadius;
  final bool shrinkWrap;

  const FilterOption({
    Key? key,
    required this.selected,
    required this.value,
    this.child,
    this.onChanged,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(3)),
    this.shrinkWrap = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool darkMode = Theme.of(context).brightness == Brightness.dark;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 30),
      child: OutlinedButton(
        onPressed: () {
          if (onChanged != null) {
            onChanged!(!selected);
          }
        },
        style: OutlinedButton.styleFrom(
          primary: selected || darkMode ? Colors.white : Colors.black,
          backgroundColor:
              selected ? selectedColor ?? Colors.blue : unselectedColor,
          minimumSize: shrinkWrap ? const Size(2, 2) : null,
          padding: shrinkWrap ? const EdgeInsets.all(0) : null,
          textStyle: const TextStyle(fontWeight: FontWeight.normal),
          tapTargetSize: shrinkWrap ? MaterialTapTargetSize.shrinkWrap : null,
          shape: ContinuousRectangleBorder(borderRadius: borderRadius),
        ),
        child: child ?? Text(value.toString()),
        // shape: ,
      ),
    );
  }
}
