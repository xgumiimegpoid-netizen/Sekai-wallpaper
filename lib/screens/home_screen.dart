import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wallpaper.dart';
import '../services/wallpaper_service.dart';
import '../widgets/wallpaper_image.dart';
import 'preview_screen.dart';
import 'community_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const int _initialLoadCount = 12;
  static const int _loadMoreIncrement = 8;
  static const _donateUrl = 'https://buymeacoffee.com/';

  void _navigateToCategory(int index) {
    setState(() => _searching = false);
    _searchController.clear();
    _tabController.animateTo(index);
    Navigator.pop(context);
  }

  Future<void> _openDonateLink() async {
    final uri = Uri.parse(_donateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  final _service = WallpaperService();
  final _connectivity = Connectivity();
  late TabController _tabController;
  Map<String, List<Wallpaper>> _wallpapers = {};
  final Map<String, int> _displayCount = {};
  List<Wallpaper> _searchResults = [];
  bool _loading = true;
  bool _searching = false;
  bool _hasError = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: CategoryData.categories.length, vsync: this);
    _checkConnectionAndLoad();
    _listenConnectivity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  void _listenConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none) && _hasError) {
        _load();
      }
    });
  }

  Future<void> _checkConnectionAndLoad() async {
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Sin conexión a internet';
      });
      return;
    }
    _load();
  }

  void _resetDisplayCounts() {
    _displayCount.clear();
    for (final cat in CategoryData.categories) {
      _displayCount[cat.name] = _initialLoadCount;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
    });
    _resetDisplayCounts();

    try {
      final data = await _service.loadAll();
      final totalWallpapers = data.values.fold<int>(0, (sum, list) => sum + list.length);

      if (totalWallpapers == 0) {
        setState(() {
          _wallpapers = data;
          _loading = false;
          _hasError = true;
          _errorMessage = 'No se pudieron cargar los wallpapers';
        });
        return;
      }

      setState(() {
        _wallpapers = data;
        _loading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _loadMore(String categoryName) {
    final current = _displayCount[categoryName] ?? _initialLoadCount;
    final totalInCategory = _wallpapers[categoryName]?.length ?? 0;
    final newCount = current + _loadMoreIncrement;

    setState(() {
      _displayCount[categoryName] = newCount.clamp(0, totalInCategory);
    });
  }

  void _search(String query) {
    _searchTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searching = false;
        _searchResults = [];
      });
      return;
    }

    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim().toLowerCase());
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searching = false;
        _searchResults = [];
      });
      return;
    }

    final results = <Wallpaper>[];
    final addedIds = <String>{};

    for (final entry in _wallpapers.entries) {
      for (final w in entry.value) {
        if (addedIds.contains(w.id)) continue;

        final matchesTitle = w.title.toLowerCase().contains(query);
        final matchesAuthor = w.author.toLowerCase().contains(query);
        final matchesCategory = w.category.toLowerCase().contains(query);
        final matchesId = w.id.toLowerCase().contains(query);

        if (matchesTitle || matchesAuthor || matchesCategory || matchesId) {
          results.add(w);
          addedIds.add(w.id);
        }
      }
    }

    setState(() {
      _searching = true;
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar por título, autor, categoría...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                  ),
                ),
                onChanged: _search,
              )
            : const Text('Wallpapers'),
        actions: [
          if (!_searching)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar',
              onPressed: () {
                setState(() => _searching = true);
              },
            ),
          if (!_searching && !_loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recargar',
              onPressed: _load,
            ),
        ],
        bottom: _searching || _hasError
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                dividerColor: Colors.transparent,
                tabs: CategoryData.categories.map((c) {
                  final total = _wallpapers[c.name]?.length ?? 0;
                  final shown = _displayCount[c.name] ?? _initialLoadCount;
                  final displayTotal = shown < total ? '$shown/$total' : (total > 0 ? '$total' : '');
                  
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 18),
                        const SizedBox(width: 6),
                        Text(c.name),
                        if (displayTotal.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              displayTotal,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/banner.gif',
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Wallpapers',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_wallpapers.isNotEmpty)
                          Text(
                            '${_wallpapers.values.fold<int>(0, (sum, list) => sum + list.length)} wallpapers disponibles',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                ...CategoryData.categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cat = entry.value;
                  final count = _wallpapers[cat.name]?.length ?? 0;
                  return ListTile(
                    leading: Icon(cat.icon),
                    title: Text(cat.name),
                    trailing: count > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => _navigateToCategory(index),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.groups),
            title: const Text('Comunidad'),
            subtitle: const Text('Comparte tus wallpapers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommunityScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.local_cafe),
            title: const Text('Invitarme un café'),
            subtitle: const Text('¿Te gusta la app? Apoya el desarrollo'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: _openDonateLink,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando wallpapers...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Error al cargar',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searching) {
      return _buildSearchResults();
    }

    return TabBarView(
      controller: _tabController,
      children: CategoryData.categories.map((cat) {
        final fullList = _wallpapers[cat.name] ?? [];
        final displayLimit = _displayCount[cat.name] ?? _initialLoadCount;
        final displayedList = fullList.take(displayLimit).toList();
        final hasMore = displayLimit < fullList.length;

        if (fullList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text('No wallpapers en ${cat.name}'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final w = displayedList[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PreviewScreen(wallpaper: w)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: WallpaperImage(wallpaper: w),
                        ),
                      );
                    },
                    childCount: displayedList.length,
                  ),
                ),
              ),
              if (hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: () => _loadMore(cat.name),
                        icon: const Icon(Icons.expand_more),
                        label: Text(
                          'Cargar más (${fullList.length - displayLimit} restantes)',
                        ),
                      ),
                    ),
                  ),
                ),
              if (!hasMore && fullList.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Mostrando los ${fullList.length} wallpapers de ${cat.name}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      final query = _searchController.text.trim();
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              query.isEmpty
                  ? 'Escribe para buscar'
                  : 'No se encontraron resultados para "$query"',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Busca por título, autor o categoría',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              Icon(Icons.search, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${_searchResults.length} resultado${_searchResults.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.6,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (ctx, i) {
              final w = _searchResults[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PreviewScreen(wallpaper: w)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: WallpaperImage(wallpaper: w),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.7), Colors.black.withValues(alpha: 0.0)],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          w.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
