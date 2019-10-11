import 'package:cached_network_image/cached_network_image.dart';
import 'package:chaldea/components/components.dart';
import 'package:chaldea/modules/home/subpage/edit_gallery_page.dart';
import 'package:chaldea/modules/item/item_list_page.dart';
import 'package:chaldea/modules/servant/servant_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';

class Gallery extends StatefulWidget {
  @override
  GalleryState createState() => GalleryState();
}

class GalleryState extends State<Gallery> {
  String selectedItem;
  Map<String, GalleryItem> kAllGalleryItems;
  List<String> shownGalleryItems;

  @override
  void initState() {
    super.initState();
    // here db.data has not fully loaded. (loading)
    if (db.appData.galleries == null) {
      // set default value
      print('why galleries=null ????');
      db.appData.galleries = {};
    }
  }

  void _getAllGalleries(BuildContext context) {
    GalleryItem.allItems = {
      GalleryItem.servant: GalleryItem(
          title: S.of(context).servant_title,
          icon: Icons.people,
          routeName: '/servant',
          builder: (context) => ServantListPage()),
      GalleryItem.item: GalleryItem(
          title: S.of(context).item_title,
          icon: Icons.category,
          routeName: '/item',
          builder: (context) => ItemListPage()),
      GalleryItem.more: GalleryItem(
          title: S.of(context).more,
          icon: Icons.add,
          routeName: '/more',
          builder: (context) => EditGalleryPage())
    };
    db.appData.galleries = GalleryItem.allItems.map((key, item) {
      return MapEntry<String, bool>(key, db.appData.galleries[key] ?? true);
    });
    db.appData.galleries[GalleryItem.more] = true;
  }

  @override
  Widget build(BuildContext context) {
    _getAllGalleries(context);
    List<Widget> gridItems = [];
    db.appData.galleries.forEach((v, isShown) {
      if (isShown || v == GalleryItem.more) {
        final item = GalleryItem.allItems[v];
        gridItems.add(DecoratedBox(
          decoration: BoxDecoration(),
          child: FlatButton(
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        size: 45.0,
                        color: Theme.of(context).primaryColor,
                      )
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        style: TextStyle(fontSize: 15.0),
                      )
                    ],
                  ),
                )
              ],
            ),
            onPressed: () {
              SplitRoute.popAndPush(context,
                  builder: item.builder,
                  settings: RouteSettings(
                      isInitialRoute: item.isInitialRoute ?? true));
            },
          ),
        ));
      }
    });

    return Scaffold(
        appBar: AppBar(
          title: Text("Chaldea"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.accessibility),
              onPressed: () async {},
            ),
          ],
        ),
        body: ListView(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 8.0 / 3.0,
              child: Slider(<String>[
//                "https://fgo.wiki/images/7/7d/Saber_Wars%E5%A4%8D%E5%88%BB.png",
//                "https://fgo.wiki/images/e/ec/%E5%94%A0%E5%94%A0%E5%8F%A8%E5%8F%A8%E5%B8%9D%E9%83%BD%E5%9C%A3%E6%9D%AF%E5%A5%87%E8%B0%AD%E5%A4%8D%E5%88%BB_jp.png",
              ]),
            ),
            GridView.count(
              crossAxisCount: isTablet(context)
                  ? (MediaQuery.of(context).size.width / 768.0 * 3).floor()
                  : 4,
              physics: ScrollPhysics(),
              shrinkWrap: true,
              childAspectRatio: 1.0,
              children: gridItems,
            ),
            Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                        heightFactor: 1,
                        child: Text(
                          'Test Info Pad',
                          style: TextStyle(fontSize: 18),
                        )),
                    Divider(thickness: 1),
                    Text('Screen size: ${MediaQuery.of(context).size}')
                  ],
                ),
              ),
            )
          ],
        ));
  }
}

class Slider extends StatefulWidget {
  final List<String> imgUrls;

  const Slider(this.imgUrls);

  @override
  State<StatefulWidget> createState() => _SliderState();
}

class _SliderState extends State<Slider> {
  @override
  Widget build(BuildContext context) {
    if (null == widget.imgUrls) return null;
    return Swiper(
      itemBuilder: (BuildContext context, int index) {
        return CachedNetworkImage(
          imageUrl: widget.imgUrls[index],
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Icon(Icons.error),
        );
      },
      itemCount: widget.imgUrls.length,
      autoplay: true,
      pagination: SwiperPagination(margin: const EdgeInsets.all(1.0)),
      autoplayDelay: 5000,
    );
  }
}