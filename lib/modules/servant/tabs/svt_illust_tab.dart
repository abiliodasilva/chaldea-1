import 'package:cached_network_image/cached_network_image.dart';
import 'package:chaldea/components/components.dart';

import '../servant_detail_page.dart';
import 'svt_tab_base.dart';

class SvtIllustTab extends SvtTabBaseWidget {
  SvtIllustTab(
      {Key key, ServantDetailPageState parent, Servant svt, ServantPlan plan})
      : super(key: key, parent: parent, svt: svt, plan: plan);

  @override
  _SvtIllustTabState createState() =>
      _SvtIllustTabState(parent: parent, svt: svt, plan: plan);
}

class _SvtIllustTabState extends SvtTabBaseState<SvtIllustTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  TabController _tabController;

  _SvtIllustTabState(
      {ServantDetailPageState parent, Servant svt, ServantPlan plan})
      : super(parent: parent, svt: svt, plan: plan);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: svt.info.illust.length, vsync: this);
    db.checkNetwork();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: <Widget>[
        TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: svt.info.illust
                .map((v) => Tab(
                        child: Text(
                      v['name'],
                      style: TextStyle(color: Colors.black87),
                    )))
                .toList()),
        Expanded(
          child: TabBarView(
              controller: _tabController,
              children: List.generate(svt.info.illust.length, (i) {
                final url = svt.info.illust[i]['url'];
                return MyCachedImage(
                  url: url,
                  enableDownload: db.enableDownload,
                  imageBuilder: (context, url) => GestureDetector(
                    onTap: () async {
                      int newIndex =
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => FullScreenImageSlider(
                                    imgUrls: svt.info.illust
                                        .map((e) => e['url'])
                                        .toList(),
                                    initialPage: i,
                                    enableDownload: db.enableDownload,
                                  ),
                              fullscreenDialog: true));
                      setState(() {
                        _tabController.animateTo(newIndex);
                      });
                    },
                    child: CachedNetworkImage(
                      imageUrl: url,
                      placeholder: MyCachedImage.defaultPlaceholder,
                    ),
                  ),
                );
              })),
        )
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }
}