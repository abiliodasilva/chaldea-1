import 'package:chaldea/components/components.dart';
import 'package:chaldea/modules/item/item_list_page.dart';

abstract class CommonBuilder {
  /// build a grid view with [ImageWithText] as its children.
  /// The key and value of [data] are Servant/Item icon name and its' num or text
  /// for image and text in [ImageWithText].
  static Widget buildIconGridView({
    required Map<String, dynamic> data,
    int crossCount = 7,
    void Function(String key)? onTap,
    double childAspectRatio = 132 / 144,
    bool scrollable = false,
  }) {
    return GridView.count(
      childAspectRatio: childAspectRatio,
      crossAxisCount: crossCount,
      shrinkWrap: true,
      physics: scrollable ? null : const NeverScrollableScrollPhysics(),
      children: data.entries
          .map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                child: ImageWithText(
                  onTap: onTap == null ? null : () => onTap(entry.key),
                  image: db.getIconImage(entry.key),
                  text: entry.key == Items.qp && entry.value is int
                      ? formatNumber(entry.value, compact: true)
                      : entry.value.toString(),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                ),
              ))
          .toList(),
    );
  }

  static Widget priorityIcon({required BuildContext context}) {
    return db.streamBuilder(
      (context) => IconButton(
        icon: Icon(
          Icons.low_priority,
          color: db.userData.svtFilter.priority.isEmpty('12345'.split(''))
              ? null
              : Colors.yellowAccent,
        ),
        tooltip: S.of(context).priority,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => ItemFilterDialog(),
          );
        },
      ),
    );
  }

  static Widget buildSwitchPlanButton(
      {required BuildContext context, ValueChanged<int>? onChange}) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: () {
        FocusScope.of(context).unfocus();
        showSwitchPlanDialog(context: context, onChange: onChange);
      },
      tooltip: '${S.current.plan_title} ${db.curUser.curSvtPlanNo + 1}',
      icon: Center(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            const Icon(Icons.list),
            ImageWithText.paintOutline(
              text: (db.curUser.curSvtPlanNo + 1).toString(),
              shadowSize: 5,
              shadowColor: colorScheme.brightness == Brightness.light
                  ? colorScheme.primary
                  : colorScheme.surface,
            )
          ],
        ),
      ),
    );
  }

  static Future showSwitchPlanDialog(
      {required BuildContext context, ValueChanged<int>? onChange}) {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(S.current.select_plan),
        children: List.generate(db.curUser.servantPlans.length, (index) {
          return ListTile(
            title: Text(S.current.plan_x(index + 1)),
            selected: index == db.curUser.curSvtPlanNo,
            onTap: () {
              Navigator.of(context).pop();
              if (onChange != null) {
                onChange(index);
              }
            },
          );
        }),
      ),
    );
  }
}

Widget buildClassifiedItemList({
  required BuildContext context,
  required Map<String, int> data,
  bool divideCategory = true,
  bool divideRarity = true,
  bool divideClassItem = true,
  bool responsive = true,
  int? minCrossCount,
  bool compactNum = true,
}) {
  final divided = divideItemsToGroups(data.keys.toList(),
      divideCategory: divideCategory,
      divideRarity: divideRarity,
      divideClassItem: divideClassItem);
  List<Widget> children = [];
  for (var key in divided.keys) {
    final gridChildren = divided[key]!.map((item) {
      return ImageWithText(
        image: Item.iconBuilder(context: context, itemKey: item.name),
        text: formatNumber(data[item.name]!, compact: compactNum),
        padding: const EdgeInsets.only(right: 3),
      );
    }).toList();
    children.add(LayoutBuilder(builder: (context, constraints) {
      int crossCount = constraints.maxWidth == double.infinity
          ? 7
          : constraints.maxWidth ~/ 48;
      if (minCrossCount != null && crossCount < minCrossCount) {
        crossCount = minCrossCount;
      }
      return TileGroup(
        header: Item.getNameOfCategory(key ~/ 10, key % 10),
        padding: const EdgeInsets.only(bottom: 0),
        children: <Widget>[
          buildGridIcons(
            context: context,
            children: gridChildren,
            crossCount: crossCount,
          ),
        ],
      );
    }));
  }
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}

Widget buildGridIcons({
  required BuildContext context,
  required List<Widget> children,
  double minWidth = 56,
  int? crossCount,
}) {
  if (children.isEmpty) return Container();
  children = children
      .map((e) => Padding(padding: const EdgeInsets.all(2), child: e))
      .toList();
  if (crossCount == null) {
    return LayoutBuilder(builder: (context, constraints) {
      int count = constraints.maxWidth == double.infinity
          ? 7
          : constraints.maxWidth ~/ minWidth;
      return GridView.count(
        padding: const EdgeInsets.only(left: 16, top: 3, bottom: 3, right: 10),
        childAspectRatio: 132 / 144,
        crossAxisCount: count,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      );
    });
  } else {
    return GridView.count(
      padding: const EdgeInsets.only(left: 16, top: 3, bottom: 3, right: 10),
      childAspectRatio: 132 / 144,
      crossAxisCount: crossCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

/// Divide list of items into groups according to [category] and/or [rarity].
/// If [divideRarity] is set to false, only divide into [category] groups.
/// The key of returned Map is [category] if [divideRarity], else [category]*10+[rarity]
Map<int, List<Item>> divideItemsToGroups(
  List<String> items, {
  bool divideCategory = true,
  bool divideRarity = true,
  bool divideClassItem = true,
}) {
  Map<int, List<Item>> groups = {};
  for (String itemKey in items) {
    final item = db.gameData.items[itemKey];
    if (item != null) {
      int groupKey;
      if ((item.category == ItemCategory.gem ||
              item.category == ItemCategory.ascension) &&
          !divideClassItem &&
          divideCategory) {
        groupKey = item.category * 10;
      } else {
        groupKey = (divideCategory ? item.category * 10 : 0) +
            (divideRarity ? item.rarity : 0);
      }
      groups[groupKey] ??= [];
      groups[groupKey]!.add(item);
    }
  }
  final sortedKeys = groups.keys.toList()..sort();
  return Map.fromEntries(sortedKeys.map((key) {
    return MapEntry(key, groups[key]!..sort((a, b) => a.id - b.id));
  }));
}