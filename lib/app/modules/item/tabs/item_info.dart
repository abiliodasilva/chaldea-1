import 'package:auto_size_text/auto_size_text.dart';
import 'package:chaldea/generated/l10n.dart';
import 'package:chaldea/models/models.dart';
import 'package:chaldea/utils/utils.dart';
import 'package:chaldea/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ItemInfoTab extends StatefulWidget {
  final int itemId;

  const ItemInfoTab({Key? key, required this.itemId}) : super(key: key);

  @override
  _ItemInfoTabState createState() => _ItemInfoTabState();
}

class _ItemInfoTabState extends State<ItemInfoTab> {
  int get itemId => widget.itemId;

  @override
  Widget build(BuildContext context) {
    final item = db2.gameData.items[itemId];
    if (item == null) {
      return ListTile(
        title: Text('NotFound: $itemId'),
      );
    }
    return SingleChildScrollView(
      child: CustomTable(
        children: <Widget>[
          CustomTableRow(
            children: [
              TableCellData(
                child: db2.getIconImage(item.borderedIcon, height: 72),
                flex: 1,
                padding: const EdgeInsets.all(3),
              ),
              TableCellData(
                flex: 3,
                padding: EdgeInsets.zero,
                child: CustomTable(
                  hideOutline: true,
                  children: <Widget>[
                    CustomTableRow(children: [
                      TableCellData(
                        child: Text(item.lName.l,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        isHeader: true,
                      )
                    ]),
                    if (!Transl.isJP)
                      CustomTableRow.fromTexts(texts: [item.name]),
                    CustomTableRow.fromTexts(texts: [item.lName.na]),
                    CustomTableRow(children: [
                      TableCellData(text: 'ID', isHeader: true),
                      TableCellData(text: item.id.toString(), flex: 2),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          CustomTableRow.fromTexts(
              texts: [S.current.card_description], isHeader: true),
          CustomTableRow(
            children: [
              TableCellData(
                text: item.detail,
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              )
            ],
          ),
          if (item.type == ItemType.svtCoin) ..._svtCoinObtain(),
        ],
      ),
    );
  }

  final validCoins = const [2, 6, 15, 30, 50, 90];
  List<int> bondCoins = <int>[
    ...List.generate(6, (index) => 5),
    ...List.generate(3, (index) => 10),
    ...List.generate(6, (index) => 20),
  ];
  int _summonCoin = 90;
  int _baseNp = 1;

  List<Widget> _svtCoinObtain() {
    return [
      CustomTableRow.fromTexts(
        isHeader: true,
        texts: const ['Table Setting: coins/NP & NP range'],
      ),
      SizedBox(
        height: 36,
        child: CustomTableRow.fromChildren(
          children: List.generate(
            validCoins.length,
            (index) => InkWell(
              onTap: () {
                setState(() {
                  _summonCoin = validCoins[index];
                });
              },
              child: SizedBox.expand(
                child: Center(
                  child: AutoSizeText(
                    '${validCoins[index]}',
                    textAlign: TextAlign.center,
                    style: _summonCoin == validCoins[index]
                        ? TextStyle(
                            color: Theme.of(context).errorColor,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      SizedBox(
        height: 36,
        child: CustomTableRow.fromChildren(
          children: [
            const Text('Range'),
            ...List.generate(
              5,
              (index) {
                int baseNp = 1 + 5 * index;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _baseNp = baseNp;
                    });
                  },
                  child: SizedBox.expand(
                    child: Center(
                      child: AutoSizeText(
                        '$baseNp~${baseNp + 4}',
                        textAlign: TextAlign.center,
                        style: baseNp == _baseNp
                            ? TextStyle(
                                color: Theme.of(context).errorColor,
                                fontWeight: FontWeight.bold,
                              )
                            : null,
                        maxLines: 1,
                      ),
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
      CustomTableRow.fromTexts(
        texts: [
          (S.current.bond),
          for (int np = _baseNp; np < _baseNp + 5; np++) 'NP $np',
        ],
        isHeader: true,
      ),
      for (int index = 0; index < bondCoins.length; index++)
        CustomTableRow(
          children: List.generate(
            6,
            (np) {
              if (np == 0) {
                return TableCellData(text: 'Lv.${index + 1}');
              }
              int coins = Maths.sum(bondCoins.sublist(0, index + 1)) +
                  (np + _baseNp) * _summonCoin;
              return TableCellData(
                text: coins.toString(),
                style: coins > 480
                    ? TextStyle(
                        color: Theme.of(context).hintColor,
                        fontStyle: FontStyle.italic,
                      )
                    : const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
              );
            },
          ),
        ),
    ];
  }
}
