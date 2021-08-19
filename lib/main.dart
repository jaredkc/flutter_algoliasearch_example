import 'package:algolia/algolia.dart';
import 'package:flutter/material.dart';

// Initiate static Algolia once in your project.
// Be sure to replace the 'applicationId' and 'apiKey' with your own.
class Application {
  static const Algolia algolia = Algolia.init(
    applicationId: 'latency',
    apiKey: '1f6fd3a6fb973cb08419fe7d288fa4db',
  );
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Algolia Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Initiate Algolia in your project
  Algolia algolia = Application.algolia;

  final String _indexName = 'bestbuy'; // Set your index name you want to search
  String _searchText = "";
  int _searchPage = 0;
  List<SearchHit> _hitsList = [];

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchFieldController = TextEditingController();

  Future<void> _getSearchResult(String query, {bool append = false}) async {
    AlgoliaQuery response = algolia.instance
        .index(_indexName)
        .setPage(_searchPage)
        .setHitsPerPage(15)
        .query(query);

    AlgoliaQuerySnapshot snap = await response.getObjects();

    if (!snap.hasHits) {
      debugPrint('No more results');
      return;
    }

    var hitsList = snap.hits.map((hit) {
      return SearchHit.fromMap(hit);
    }).toList();

    setState(() {
      append ? _hitsList.addAll(hitsList) : _hitsList = hitsList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Algolia Search Example'),
      ),
      body: Column(
        children: <Widget>[
          Container(
            height: 47,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: TextField(
              controller: _searchFieldController,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter a search term',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              _searchFieldController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null),
            ),
          ),
          Expanded(
            child: _hitsList.isEmpty
                ? const Center(child: Text('No results'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 64),
                    itemCount: _hitsList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        height: 70,
                        padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                            child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                              SizedBox(
                              width: 50,
                              child: Image.network(_hitsList[index].image),
                            ),
                              const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _hitsList[index].name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              )
                            ],
                        ),
                        );
                    },
                  ),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _searchFieldController.addListener(() {
      if (_searchText != _searchFieldController.text) {
        setState(() {
          _searchPage = 0; // Reset page to 0, it's a new search
          _searchText = _searchFieldController.text;
        });
        _getSearchResult(_searchText);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _searchPage++; // Increment page to load the next results
        });
        _getSearchResult(_searchText, append: true);
      }
    });

    _getSearchResult('');
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class SearchHit {
  final String name;
  final String image;

  SearchHit(this.name, this.image);

  static SearchHit fromJson(Map<String, dynamic> json) {
    return SearchHit(json['name'], json['image']);
  }

  static SearchHit fromMap(AlgoliaObjectSnapshot hit) {
    return SearchHit(hit.data['name'], hit.data['image']);
  }
}
