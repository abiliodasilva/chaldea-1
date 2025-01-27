library ffo;

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:catcher/core/catcher.dart';
import 'package:chaldea/components/components.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

part 'ffo_data.dart';
part 'ffo_download_dialog.dart';
part 'ffo_summon_page.dart';

String get _baseDir => join(db.paths.appPath, 'ffo');

class FreedomOrderPage extends StatefulWidget {
  FreedomOrderPage({Key? key}) : super(key: key);

  @override
  _FreedomOrderPageState createState() => _FreedomOrderPageState();
}

class _FreedomOrderPageState extends State<FreedomOrderPage> {
  Map<int, FFOPart> parts = {};

  FFOParams params = FFOParams();
  bool sameSvt = false;

  @override
  void initState() {
    super.initState();
    loadCSV();
  }

  @override
  void dispose() {
    super.dispose();
    params.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const AutoSizeText('Fate/Freedom Order', maxLines: 1),
        centerTitle: false,
        actions: [
          MarkdownHelpPage.buildHelpBtn(context, 'freedom_order.md'),
          importButton,
        ],
      ),
      body: Column(
        children: [
          if (parts.isEmpty)
            Expanded(
              child: Center(
                child: Text(S.current.ffo_missing_data_hint),
              ),
            ),
          if (parts.isNotEmpty)
            Expanded(
              child: Center(
                child: params.buildCard(context, true),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                partChooser(0),
                partChooser(1),
                partChooser(2),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                CheckboxWithLabel(
                  value: params.cropNormalizedSize,
                  label: Text(S.current.ffo_crop),
                  onChanged: (v) async {
                    if (v != null) {
                      params.cropNormalizedSize = v;
                    }
                    setState(() {});
                  },
                ),
                CheckboxWithLabel(
                  value: sameSvt,
                  label: Text(S.current.ffo_same_svt),
                  onChanged: (v) async {
                    if (v == null) return;
                    sameSvt = v;
                    if (sameSvt) {
                      FFOPart? _part =
                          params.parts.firstWhereOrNull((e) => e != null);
                      await params.setPart(_part);
                    }
                    setState(() {});
                  },
                ),
                ElevatedButton(
                  onPressed: params.isEmpty
                      ? null
                      : () => params.showSaveShare(context: context),
                  child: Text(S.current.save),
                ),
                ElevatedButton(
                  onPressed: () {
                    SplitRoute.push(
                      context,
                      FFOSummonPage(partsDta: parts),
                      detail: true,
                    );
                  },
                  child: Text(S.current.summon_simulator),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get importButton {
    return IconButton(
      tooltip: 'Import FFO data',
      onPressed: () async {
        showDialog(
          context: context,
          builder: (context) => FfoDownloadDialog(
            onSuccess: () => loadCSV(),
          ),
        );
      },
      icon: const Icon(Icons.download_sharp),
    );
  }

  Widget partChooser(int where) {
    assert(where >= 0 && where < 3);
    final FFOPart? _part = params.parts[where];
    String partName = [
      S.current.ffo_head,
      S.current.ffo_body,
      S.current.ffo_background
    ][where];
    File iconFile = File(join(
        _baseDir,
        'UI',
        [
          'icon_servant_head_on.png',
          'icon_servant_body_on.png',
          'icon_servant_bg_on.png'
        ][where]));
    return InkWell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _part == null
              ? db.getIconImage(null, height: 72)
              : Image.file(
                  File(join(_baseDir, 'Sprite',
                      'icon_servant_${padSvtId(_part.svtId)}.png')),
                  height: 72),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(
                iconFile,
                width: 16,
                height: 16,
                errorBuilder: (context, e, s) => Container(),
              ),
              Text(partName),
            ],
          ),
        ],
      ),
      onTap: () {
        SplitRoute.push(
          context,
          _PartChooserPage(
            title: 'Choose $partName',
            parts: parts,
            onChanged: (svt) async {
              await params.setPart(svt, sameSvt ? null : where);
              setState(() {});
            },
          ),
          detail: true,
        );
      },
    );
  }

  // load and save
  void loadCSV() {
    final csvFile = File(join(_baseDir, 'CSV', 'ServantDB-Parts.csv'));
    if (!csvFile.existsSync()) return;
    try {
      parts.clear();
      const CsvToListConverter(eol: '\n')
          .convert(csvFile.readAsStringSync().replaceAll('\r\n', '\n'))
          .forEach((row) {
        if (row[0] == 'id') {
          assert(row.length == 10, row.toString());
          return;
        }
        final item = FFOPart.fromList(row);
        parts[item.id] = item;
      });
      print('loaded csv: ${parts.length}');
    } catch (e, s) {
      logger.e('load FFO data failed', e, s);
      logger.e(csvFile.readAsStringSync());
      SimpleCancelOkDialog(
        title: const Text('Load FFO data error'),
        content: Text('$e\nTry to import data again'),
      ).showDialog(context);
      Catcher.reportCheckedError(e, s);
    }
  }
}

class _PartChooserPage extends StatefulWidget {
  final String title;
  final Map<int, FFOPart> parts;
  final ValueChanged<FFOPart?> onChanged;

  const _PartChooserPage({
    Key? key,
    required this.title,
    required this.parts,
    required this.onChanged,
  }) : super(key: key);

  @override
  _PartChooserPageState createState() => _PartChooserPageState();
}

class _PartChooserPageState extends State<_PartChooserPage> {
  late List<FFOPart> parts;
  int sortType = 0;

  @override
  void initState() {
    super.initState();
    final _sortType = db.cfg.ffoSort.get();
    if (_sortType is int && sortType >= 0 && sortType <= 2) {
      sortType = _sortType;
    }
    parts = widget.parts.values.toList();
    sort();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    parts.forEach((svt) {
      String idString = svt.svtId.toString().padLeft(3, '0');
      File file = File(join(
          db.paths.appPath, 'ffo', 'Sprite', 'icon_servant_$idString.png'));
      if (!file.existsSync()) return;

      Widget child = ImageWithText(
        width: 54,
        text: idString,
        image: SizedBox(
          width: 54,
          height: 54,
          child: Image.file(file, fit: BoxFit.contain),
        ),
        textStyle: const TextStyle(fontSize: 12),
      );
      child = GestureDetector(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: child,
        ),
        onTap: () {
          widget.onChanged(svt);
          Navigator.pop(context);
        },
      );
      children.add(child);
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            return GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              crossAxisCount: constraints.maxWidth ~/ 56,
              children: children,
            );
          })),
          kDefaultDivider,
          buttonBar,
        ],
      ),
    );
  }

  Widget get buttonBar {
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      children: [
        Text(S.current.filter_sort),
        DropdownButton<int>(
          value: sortType,
          items: [
            const DropdownMenuItem(value: 0, child: Text('ID')),
            DropdownMenuItem(value: 1, child: Text(S.current.rarity)),
            DropdownMenuItem(
                value: 2, child: Text(S.current.filter_sort_class)),
          ],
          onChanged: (v) {
            if (v != null) {
              sortType = v;
              sort();
              setState(() {});
              db.cfg.ffoSort.set(sortType);
            }
          },
        ),
        TextButton(
          onPressed: () async {
            widget.onChanged(null);
            Navigator.of(context).pop();
          },
          child: Text(S.current.clear),
        ),
      ],
    );
  }

  void sort() {
    parts.sort((a, b) {
      if (sortType == 0) {
        return a.id - b.id;
      }
      final sa = db.gameData.servants[a.id], sb = db.gameData.servants[b.id];
      if (sa != null && sb != null) {
        if (sortType == 1) {
          return Servant.compare(sa, sb,
              keys: [SvtCompare.rarity, SvtCompare.className, SvtCompare.no],
              reversed: [true, false, false]);
        } else if (sortType == 2) {
          return Servant.compare(sa, sb,
              keys: [SvtCompare.className, SvtCompare.rarity, SvtCompare.no],
              reversed: [false, true, false]);
        }
      }
      return a.id - b.id;
    });
  }
}
