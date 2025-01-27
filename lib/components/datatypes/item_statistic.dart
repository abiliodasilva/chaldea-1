/// statistics of items
part of datatypes;

class ItemStatistics {
  bool includingEvent = true;

  SvtCostItems svtItemDetail = SvtCostItems();
  Map<String, int> eventItems = {};
  Map<String, int> leftItems = {};

  Map<String, int> get svtItems => svtItemDetail.planItemCounts.summation!;

  final User? user;

  User get curUser => user ?? db.curUser;

  ItemStatistics({this.user});

  /// Clear statistic data, all data will be calculated again next calling.
  /// After importing dataset, we should call this to clear, then call
  /// [update] to refresh data.
  void clear() {
    svtItemDetail = SvtCostItems();
    eventItems = {};
    leftItems = {};
  }

  Timer? _topTimer;
  Timer? _svtTimer;
  Timer? _eventTimer;
  Timer? _leftTimer;

  Timer? _setTimer(Duration? lapse, VoidCallback callback) {
    if (lapse == null || lapse.inMilliseconds <= 0) {
      callback();
    } else {
      return Timer(lapse, callback);
    }
    return null;
  }

  /// Update [itemState] after duration [lapse]
  ///
  Future<void> update(
      {bool shouldBroadcast = true, Duration? lapse, bool withFuture = false}) {
    db.notifyDbUpdate();
    void callback() {
      updateSvtItems(shouldBroadcast: false);
      updateEventItems(shouldBroadcast: false);
      updateLeftItems(shouldBroadcast: shouldBroadcast);
    }

    // usually await this future to notify app update
    if (lapse != null && withFuture) {
      return Future.delayed(lapse, callback);
    } else {
      _topTimer?.cancel();
      _svtTimer?.cancel();
      _eventTimer?.cancel();
      _topTimer = _setTimer(lapse, callback);
      return Future.value();
    }
  }

  void updateSvtItems({bool shouldBroadcast = true, Duration? lapse}) {
    if (shouldBroadcast) {
      // db.notifyDbUpdate();
    } else {
      lapse ??= const Duration();
    }
    void callback() {
      // priority is shared cross users!
      final Map<int, ServantStatus> priorityFiltered = Map.fromEntries(curUser
          .servants.entries
          .where((entry) => db.userData.svtFilter.priority
              .singleValueFilter(entry.value.priority.toString())));
      svtItemDetail.update(
          curStat: priorityFiltered, targetPlan: curUser.curSvtPlan);
      updateLeftItems(
          shouldBroadcast: shouldBroadcast, lapse: const Duration());
    }

    _svtTimer?.cancel();
    _leftTimer?.cancel();
    _svtTimer = _setTimer(lapse, callback);
  }

  void updateEventItems({bool shouldBroadcast = true, Duration? lapse}) {
    if (shouldBroadcast) {
      // db.notifyDbUpdate();
    } else {
      lapse ??= const Duration();
    }
    void callback() {
      if (includingEvent) {
        eventItems = db.gameData.events.getAllItems(curUser.events);
      } else {
        eventItems = {};
      }
      updateLeftItems(
          shouldBroadcast: shouldBroadcast, lapse: const Duration());
    }

    _eventTimer?.cancel();
    _leftTimer?.cancel();
    _eventTimer = _setTimer(lapse, callback);
  }

  void updateLeftItems({bool shouldBroadcast = true, Duration? lapse}) {
    void callback() {
      leftItems = Maths.sumDict(
          [eventItems, curUser.items, Maths.multiplyDict(svtItems, -1)]);
      if (shouldBroadcast) {
        db.notifyDbUpdate();
      }
    }

    _leftTimer?.cancel();
    _leftTimer = _setTimer(lapse, callback);
  }
}

class SvtCostItems {
  //Map<SvtNo, List<Map<ItemKey,num>>>
  SvtParts<Map<int, Map<String, int>>> planCountBySvt = SvtParts(k: () => {}),
      allCountBySvt = SvtParts(k: () => {});

  SvtParts<Map<int, Map<String, int>>> getCountBySvt([bool planned = true]) =>
      planned ? planCountBySvt : allCountBySvt;

  // Map<ItemKey, List<Map<SvtNo, num>>>
  SvtParts<Map<String, Map<int, int>>> planCountByItem = SvtParts(k: () => {}),
      allCountByItem = SvtParts(k: () => {});

  SvtParts<Map<String, Map<int, int>>> getCountByItem([bool planned = true]) =>
      planned ? planCountByItem : allCountByItem;

  // Map<ItemKey, num>
  SvtParts<Map<String, int>> planItemCounts = SvtParts(k: () => {}),
      allItemCounts = SvtParts(k: () => {});

  SvtParts<Map<String, int>> getItemCounts([bool planned = true]) =>
      planned ? planItemCounts : allItemCounts;
  bool _needUpdateAll = true;

  void update(
      {required Map<int, ServantStatus> curStat,
      required Map<int, ServantPlan> targetPlan}) {
    planCountBySvt = SvtParts(k: () => {});
    planCountByItem = SvtParts(k: () => {});
    planItemCounts = SvtParts(k: () => {});
    if (_needUpdateAll) {
      allCountBySvt = SvtParts(k: () => {});
      allCountByItem = SvtParts(k: () => {});
      allItemCounts = SvtParts(k: () => {});
    }
    // bySvt
    db.gameData.servantsWithUser.forEach((no, svt) {
      final status = curStat[no], target = targetPlan[no];
      // planned
      SvtParts<Map<String, int>> a, b;
      if (status?.curVal.favorite == true) {
        a = svt.getAllCostParts(status: status, target: target);
      } else {
        a = SvtParts(k: () => {});
      }
      a.summation = Maths.sumDict(a.values);
      a.summation![Items.servantCoin] =
          max(0, (a.summation![Items.servantCoin] ?? 0) - (status?.coin ?? 0));
      b = svt.getAllCostParts(all: true);
      b.summation = Maths.sumDict(b.values);
      for (var i = 0; i < planCountBySvt.valuesWithSum.length; i++) {
        planCountBySvt.valuesWithSum[i][no] = a.valuesWithSum[i];
        if (_needUpdateAll) {
          allCountBySvt.valuesWithSum[i][no] = b.valuesWithSum[i];
        }
      }
    });

    // byItem
    for (String itemKey in db.gameData.items.keys) {
      for (var i = 0; i < planCountBySvt.values.length; i++) {
        planCountBySvt.values[i].forEach((svtNo, cost) {
          int n = cost[itemKey] ?? 0;
          // if (itemKey == Items.servantCoin) {
          //   n = max(0, n - (curStat[svtNo]?.coin ?? 0));
          // }
          planCountByItem.values[i].putIfAbsent(itemKey, () => {})[svtNo] = n;
        });
        if (_needUpdateAll) {
          allCountBySvt.values[i].forEach((svtNo, cost) {
            allCountByItem.values[i].putIfAbsent(itemKey, () => {})[svtNo] =
                cost[itemKey] ?? 0;
          });
        }
      }
      planCountByItem.summation![itemKey] =
          Maths.sumDict(planCountByItem.values.map((e) => e[itemKey]));
      if (itemKey == Items.servantCoin) {
        final svtCosts = planCountByItem.summation![itemKey]!;
        svtCosts.updateAll(
            (svtNo, count) => max(0, count - (curStat[svtNo]?.coin ?? 0)));
      }
      if (_needUpdateAll) {
        allCountByItem.summation![itemKey] =
            Maths.sumDict(allCountByItem.values.map((e) => e[itemKey]));
      }
    }

    // itemCounts
    for (var i = 0; i < planItemCounts.valuesWithSum.length; i++) {
      for (String itemKey in db.gameData.items.keys) {
        planItemCounts.valuesWithSum[i][itemKey] = Maths.sum(
            planCountByItem.valuesWithSum[i][itemKey]?.values ?? <int>[]);
        allItemCounts.valuesWithSum[i][itemKey] = Maths.sum(
            allCountByItem.valuesWithSum[i][itemKey]?.values ?? <int>[]);
      }
    }
    _needUpdateAll = false;
  }
}

/// replace with List(3)
class SvtParts<T> {
  /// used only if [T] extends [num]
  T? summation;

  T ascension;
  T skill;
  T dress;
  T appendSkill;
  T extra;

  SvtParts({
    T? ascension,
    T? skill,
    T? dress,
    T? appendSkill,
    T? extra,
    T? summation,
    T Function()? k,
  })  : assert(ascension != null &&
                skill != null &&
                dress != null &&
                appendSkill != null &&
                extra != null ||
            k != null),
        ascension = ascension ?? k!(),
        skill = skill ?? k!(),
        dress = dress ?? k!(),
        appendSkill = appendSkill ?? k!(),
        extra = extra ?? k!(),
        summation = summation ?? k?.call();

  SvtParts<T2> copyWith<T2>([T2 Function(T e)? f]) {
    return SvtParts<T2>(
      ascension: f == null ? ascension as T2 : f(ascension),
      skill: f == null ? skill as T2 : f(skill),
      dress: f == null ? dress as T2 : f(dress),
      appendSkill: f == null ? appendSkill as T2 : f(skill),
      extra: f == null ? extra as T2 : f(extra),
      summation: f == null
          ? summation as T2?
          : summation != null
              ? f(summation!)
              : null,
    );
  }

  List<T> get values => [ascension, skill, dress, appendSkill, extra];

  List<T> valuesIfExtra(String key) {
    return Items.extraPlanningItems.contains(key)
        ? [extra]
        : [ascension, skill, dress, appendSkill];
  }

  /// calculate [summation] before using!!!
  List<T> get valuesWithSum =>
      [ascension, skill, dress, appendSkill, extra, summation!];

  @override
  String toString() {
    return '$runtimeType<$T>(\n  ascension:$ascension,\n  skill:$skill,\n'
        '  dress:$dress,\n  appendSkill:$appendSkill,\n  extra:$extra)';
  }
}
