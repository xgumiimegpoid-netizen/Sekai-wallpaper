import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/wallpaper.dart';
import '../services/wallpaper_service.dart';
import '../services/favorites_service.dart';
import '../services/offline_cache.dart';
import '../services/update_checker.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_grid.dart';
import '../widgets/search_results.dart';
import '../widgets/wallpaper_image.dart';
import 'preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const int _initialLoadCount = 12;
  static const int _loadMoreIncrement = 8;
  void _navigateToCategory(int categoryIndex) {
    setState(() => _searching = false);
    _searchController.clear();
    _tabController.animateTo(categoryIndex + 1);
  }

  final _service = WallpaperService();
  final _connectivity = Connectivity();
  final _favoritesService = FavoritesService();
  late TabController _tabController;
  Map<String, List<Wallpaper>> _wallpapers = {};
  final Map<String, int> _displayCount = {};
  List<Wallpaper> _searchResults = [];
  bool _loading = true;
  bool _searching = false;
  bool _hasError = false;
  bool _isOffline = false;
  bool _checkedForUpdate = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  int _favoritesCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: CategoryData.categories.length + 1, vsync: this);
    _checkConnectionAndLoad();
    _listenConnectivity();
    _favoritesService.addListener(_onFavoritesChanged);
    _initFavorites();
  }

  Future<void> _initFavorites() async {
    await _favoritesService.ensureLoaded();
    _updateFavoritesCount();
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _onFavoritesChanged() {
    _updateFavoritesCount();
  }

  void _updateFavoritesCount() {
    final count = _favoritesService.favorites.length;
    if (count != _favoritesCount) {
      setState(() => _favoritesCount = count);
    }
  }

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  void _listenConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none) && (_hasError || _isOffline)) {
        _load();
      }
    });
  }

  Future<void> _checkConnectionAndLoad() async {
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      final cached = await OfflineCache.load();
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _wallpapers = cached;
          _loading = false;
          _isOffline = true;
          _hasError = false;
        });
        return;
      }
      setState(() {
        _loading = false;
        _hasError = true;
        _isOffline = true;
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
      _isOffline = false;
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

      await OfflineCache.save(data);

      setState(() {
        _wallpapers = data;
        _loading = false;
        _hasError = false;
      });
      if (!_checkedForUpdate) {
        _checkedForUpdate = true;
        _checkForUpdate();
      }
    } catch (e) {
      final cached = await OfflineCache.load();
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _wallpapers = cached;
          _loading = false;
          _isOffline = true;
          _hasError = false;
        });
        return;
      }
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await UpdateChecker.fetchUpdateInfo();
      if (info == null || !mounted) return;
      if (!await UpdateChecker.hasUpdate(info)) return;
      if (!await UpdateChecker.shouldShowUpdate(info)) return;
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.system_update, color: Colors.blue),
              SizedBox(width: 8),
              Text('Actualización disponible'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Versión ${info.latestVersion} disponible'),
              const SizedBox(height: 8),
              Text(
                info.releaseNotes,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                UpdateChecker.markSkipped(info.latestVersion);
              },
              child: const Text('Omitir esta versión'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                UpdateChecker.launchDownload(info.downloadUrl);
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      debugPrint('HomeScreen._checkForUpdate error: $e\n$stack');
    }
  }

  Future<void> _reloadCategory(String categoryName) async {
    try {
      final wallpapers = await _service.loadCategory(categoryName);
      setState(() {
        _wallpapers[categoryName] = wallpapers;
        _displayCount[categoryName] = _initialLoadCount;
      });
    } catch (e, stack) {
      debugPrint('HomeScreen._reloadCategory error: $e\n$stack');
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
    if (!mounted) return;
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
      drawer: AppDrawer(
        wallpapers: _wallpapers,
        onCategoryTap: _navigateToCategory,
      ),
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
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 18, color: Colors.red),
                        const SizedBox(width: 6),
                        const Text('Favoritos'),
                        if (_favoritesCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_favoritesCount',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ...CategoryData.categories.map((c) {
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
                  }),
                ],
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildFavoritesGrid() {
    final favorites = _favoritesService.favorites;

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Sin favoritos aún',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade wallpapers como favoritos desde la vista previa',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _updateFavoritesCount(),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.6,
        ),
        itemCount: favorites.length,
        itemBuilder: (ctx, i) {
          final w = favorites[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => PreviewScreen(wallpaper: w)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: WallpaperImage(wallpaper: w),
            ),
          );
        },
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
      return SearchResults(
        results: _searchResults,
        query: _searchController.text.trim(),
      );
    }

    return Column(
      children: [
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade800,
            child: const Row(
              children: [
                Icon(Icons.wifi_off, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modo offline — mostrando datos cacheados',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFavoritesGrid(),
              ...CategoryData.categories.map((cat) {
                final fullList = _wallpapers[cat.name] ?? [];
                final displayLimit = _displayCount[cat.name] ?? _initialLoadCount;
                final displayedList = fullList.take(displayLimit).toList();
                final hasMore = displayLimit < fullList.length;

                return CategoryGrid(
                  categoryName: cat.name,
                  displayedList: displayedList,
                  totalCount: fullList.length,
                  hasMore: hasMore,
                  onLoadMore: () => _loadMore(cat.name),
                  onRefresh: () => _reloadCategory(cat.name),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}