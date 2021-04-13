import 'dart:convert';
import 'dart:io';

import 'package:chaldea/components/components.dart';
import 'package:chaldea/components/git_tool.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as pathlib;
import 'package:url_launcher/url_launcher.dart';

class GameDataPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GameDataPageState();
}

class _GameDataPageState extends State<GameDataPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).gamedata),
        leading: BackButton(),
      ),
      body: ListView(
        children: [
          // TileGroup(
          //   children: [
          //     SwitchListTile.adaptive(
          //       value: false,
          //       onChanged: (v){
          //         // db.userData;
          //       },
          //       title: Text('Auto Update'),
          //       subtitle: Text('only dataset'),
          //       controlAffinity: ListTileControlAffinity.trailing,
          //     ),
          //   ],
          // ),
          TileGroup(
            children: [
              ListTile(
                title: Text(S.current.version),
                subtitle: Text(S.current.gamedata),
                trailing: Text(db.gameData.version),
              )
            ],
          ),
          TileGroup(
            header: S.current.download_source,
            children: [
              sourceAccordion(
                source: GitSource.server,
                subtitle: 'Chaldea server',
                hideContent: true,
              ),
              sourceAccordion(
                source: GitSource.github,
                subtitle: S.current.github_source_hint,
              ),
              sourceAccordion(
                source: GitSource.gitee,
                subtitle: S.current.gitee_source_hint,
              ),
            ],
          ),

          TileGroup(
            header: S.of(context).gamedata,
            children: <Widget>[
              SwitchListTile.adaptive(
                value: db.userData.autoUpdateDataset,
                title: Text(S.current.auto_update),
                onChanged: (v) {
                  setState(() {
                    db.userData.autoUpdateDataset = v;
                  });
                },
              ),
              ListTile(
                title: Text(S.of(context).download_latest_gamedata),
                subtitle: Text(S.current.download_latest_gamedata_hint),
                onTap: downloadGamedata,
              ),
              ListTile(
                title: Text(S.of(context).reload_default_gamedata),
                onTap: () {
                  SimpleCancelOkDialog(
                    title: Text(S.of(context).reload_default_gamedata),
                    onTapOk: () async {
                      EasyLoading.show(status: 'reloading');
                      await db.loadZipAssets(kDatasetAssetKey);
                      if (db.loadGameData()) {
                        EasyLoading.showSuccess(
                            S.of(context).reload_data_success);
                      } else {
                        EasyLoading.showError('Failed');
                      }
                    },
                  ).showDialog(context);
                },
              ),
              ListTile(
                title:
                    Text('${S.of(context).import_data} (dataset*.zip/.json)'),
                onTap: importGamedata,
              ),
              ListTile(
                title: Text(S.of(context).clear_cache),
                subtitle: Text(S.of(context).clear_cache_hint),
                onTap: clearCache,
              ),
            ],
          ),
          TileGroup(
            header: 'TEMP',
            footer: 'Installer for Android/Windows/macOS.',
            children: [
              ListTile(
                leading: Icon(Icons.cloud_circle, size: 28),
                title: Text('Lanzou/woozooo'),
                subtitle: RichText(
                  text: TextSpan(
                    text: 'https://wws.lanzous.com/b01tuahmf\n',
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'password: chaldea',
                        style: TextStyle(color: Colors.redAccent[100]),
                      )
                    ],
                  ),
                ),
                horizontalTitleGap: 0,
                onTap: () {
                  jumpToExternalLinkAlert(
                      url: 'https://wws.lanzous.com/b01tuahmf');
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget sourceAccordion(
      {required GitSource source, String? subtitle, bool hideContent = false}) {
    final gitTool = GitTool(source);
    Widget radio = RadioListTile<int>(
      value: source.toIndex(),
      groupValue: db.userData.downloadSource,
      title: Text(source.toTitleString()),
      subtitle: subtitle == null ? null : Text(subtitle),
      onChanged: (v) {
        setState(() {
          if (v != null) {
            db.userData.downloadSource = v;
            db.notifyDbUpdate();
          }
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
    if (hideContent) return radio;
    return SimpleAccordion(
      canTapOnHeader: false,
      headerBuilder: (context, expanded) => radio,
      contentBuilder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(source == GitSource.github
                  ? FontAwesomeIcons.github
                  : FontAwesomeIcons.git),
              dense: true,
              contentPadding: EdgeInsets.only(left: 20, right: 8),
              // horizontalTitleGap: 0,
              title: Text('Chaldea app'),
              subtitle: Text(gitTool.appReleaseUrl),
              onTap: () {
                jumpToExternalLinkAlert(url: gitTool.appReleaseUrl);
              },
            ),
            ListTile(
              leading: Icon(source == GitSource.github
                  ? FontAwesomeIcons.github
                  : FontAwesomeIcons.git),
              dense: true,
              contentPadding: EdgeInsets.only(left: 20, right: 8),
              // horizontalTitleGap: 0,
              title: Text('Dataset'),
              subtitle: Text(gitTool.datasetReleaseUrl),
              onTap: () {
                jumpToExternalLinkAlert(url: gitTool.datasetReleaseUrl);
              },
            ),
            ListTile(
              leading: Icon(source == GitSource.github
                  ? FontAwesomeIcons.github
                  : FontAwesomeIcons.git),
              dense: true,
              contentPadding: EdgeInsets.only(left: 20, right: 8),
              // horizontalTitleGap: 0,
              title: Text('FFO data'),
              subtitle: Text(gitTool.ffoDataReleaseUrl),
              onTap: () {
                jumpToExternalLinkAlert(url: gitTool.ffoDataReleaseUrl);
              },
            ),
          ],
        );
      },
    );
  }

  void downloadGamedata() {
    final gitTool = GitTool.fromDb();
    void _downloadAsset(bool icons) async {
      final release = await gitTool.latestDatasetRelease(icons: icons);
      Navigator.of(context).pop();
      String fp = pathlib.join(
          db.paths.tempDir, '${release?.name}-${release?.targetAsset?.name}');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DownloadDialog(
          url: release?.targetAsset?.browserDownloadUrl ?? '',
          savePath: fp,
          notes: release?.body,
          confirmText: S.of(context).import_data.toUpperCase(),
          onComplete: () async {
            EasyLoading.show(status: 'loading');
            try {
              await db.extractZip(fp: fp, savePath: db.paths.gameDir);
              db.loadGameData();
              Navigator.of(context).pop();
              EasyLoading.showSuccess(S.of(context).import_data_success);
            } catch (e) {
              EasyLoading.showError(S.of(context).import_data_error(e));
            } finally {}
          },
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(S.of(context).dataset_type_text),
              subtitle: Text(S.of(context).dataset_type_text_hint),
              onTap: () => _downloadAsset(false),
            ),
            ListTile(
              title: Text(S.of(context).dataset_type_image),
              subtitle: Text(S.of(context).dataset_type_image_hint),
              onTap: () => _downloadAsset(true),
            ),
            ListTile(
              title: Text(S.of(context).dataset_goto_download_page),
              subtitle: Text(S.of(context).dataset_goto_download_page_hint),
              onTap: () {
                launch(gitTool.datasetReleaseUrl);
              },
            )
          ],
        );
      },
    );
  }

  Future<void> importGamedata() async {
    try {
      // final result = await FilePicker.platform.pickFiles();
      final result = await FilePickerCross.importFromStorage(
          type: FileTypeCross.custom, fileExtension: 'zip,json');
      final file = File(result.path);
      if (file.path.toLowerCase().endsWith('.zip')) {
        EasyLoading.show(status: 'loading');
        await db.extractZip(fp: file.path, savePath: db.paths.gameDir);
        db.loadGameData();
      } else if (file.path.toLowerCase().endsWith('.json')) {
        final newData = GameData.fromJson(jsonDecode(file.readAsStringSync()));
        if (newData.version != '0') {
          db.gameData = newData;
        } else {
          throw FormatException('Invalid json contents');
        }
      } else {
        throw FormatException('unsupported file type');
      }
      EasyLoading.showSuccess(S.of(context).import_data_success);
    } on FileSelectionCanceledError {} catch (e) {
      EasyLoading.dismiss();
      showInformDialog(context,
          title: 'Import gamedata failed!', content: e.toString());
    }
  }

  Future<void> clearCache() async {
    await DefaultCacheManager().emptyCache();
    Directory(db.paths.tempDir)
      ..deleteSync(recursive: true)
      ..createSync(recursive: true);
    imageCache?.clear();
    EasyLoading.showToast(S.current.clear_cache_finish);
  }
}