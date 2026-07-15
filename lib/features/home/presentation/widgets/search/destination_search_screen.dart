import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../services/passenger_maps_service.dart';

class DestinationSearchResult {
  final LatLng point;
  final String label;

  const DestinationSearchResult({
    required this.point,
    required this.label,
  });
}

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({
    super.key,
    required this.mapsService,
  });

  final PassengerMapsService mapsService;

  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  static const Color avuxoGreen = Color(0xFF24F877);

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  Timer? debounce;

  bool loading = false;
  bool selectingAddress = false;

  int _searchRequestId = 0;

  List<PassengerPlaceSuggestion> suggestions = [];

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (mounted) {
          searchFocus.requestFocus();
        }
      },
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    suggestions.clear();
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    debounce?.cancel();

    debounce = Timer(
      const Duration(milliseconds: 450),
      () => _search(value),
    );
  }

  Future<void> _search(String value) async {
    final query = value.trim();

    if (query.length < 3) {
      if (!mounted) return;

      setState(() {
        suggestions = [];
        loading = false;
      });

      return;
    }

    final requestId = ++_searchRequestId;

    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final result = await widget.mapsService.searchPlaces(query);

      if (!mounted) return;

      if (requestId != _searchRequestId) {
        return;
      }

      final unique = <String>{};

      final filtered = result.where((item) {
        final key = '${item.title}-${item.subtitle}'.toLowerCase();
        return unique.add(key);
      }).toList();

      setState(() {
        suggestions = filtered;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        suggestions = [];
        loading = false;
      });

      _showMessage('Erro ao buscar destinos.');
    }
  }

  Future<void> _selectSuggestion(
    PassengerPlaceSuggestion suggestion,
  ) async {
    if (selectingAddress) return;

    selectingAddress = true;

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final point = await widget.mapsService.getPlaceLatLng(
        suggestion.placeId,
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      selectingAddress = false;

      if (point == null) {
        _showMessage(
          'Não foi possível localizar esse endereço.',
        );
        return;
      }

      Navigator.pop(
        context,
        DestinationSearchResult(
          point: point,
          label: suggestion.subtitle.isEmpty
              ? suggestion.title
              : '${suggestion.title}, ${suggestion.subtitle}',
        ),
      );
    } catch (_) {
      if (!mounted) return;

      selectingAddress = false;

      setState(() {
        loading = false;
      });

      _showMessage(
        'Erro ao buscar localização.',
      );
    }
  }

  void _clearSearch() {
    searchController.clear();

    _searchRequestId++;

    setState(() {
      suggestions = [];
      loading = false;
    });
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10151E),
        behavior: SnackBarBehavior.floating,
        content: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02040A),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B1117),
                    Color(0xFF02040A),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                _searchBox(),
                _quickPlaces(),
                Expanded(
                  child: suggestions.isEmpty
                      ? _emptyState()
                      : _suggestionsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Row(
        children: [
          _glassIcon(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Para onde você vai?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: avuxoGreen.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: avuxoGreen.withValues(alpha: 0.08),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: avuxoGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: avuxoGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocus,
                    onChanged: _onSearchChanged,
                    cursorColor: avuxoGreen,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Digite rua, bairro ou local',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.36),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (loading || selectingAddress)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: avuxoGreen,
                      strokeWidth: 2.4,
                    ),
                  )
                else if (searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickPlaces() {
    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        children: [
          _quickChip(Icons.home_rounded, 'Casa'),
          _quickChip(Icons.work_rounded, 'Trabalho'),
          _quickChip(Icons.star_rounded, 'Favoritos'),
          _quickChip(Icons.history_rounded, 'Recentes'),
        ],
      ),
    );
  }

  Widget _quickChip(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: avuxoGreen,
            size: 19,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        if (index < 0 || index >= suggestions.length) {
          return const SizedBox.shrink();
        }

        final item = suggestions[index];
        return _suggestionTile(item);
      },
    );
  }

  Widget _suggestionTile(PassengerPlaceSuggestion item) {
    return IgnorePointer(
      ignoring: selectingAddress,
      child: GestureDetector(
        onTap: () => _selectSuggestion(item),
        child: Opacity(
          opacity: selectingAddress ? 0.55 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1117).withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: avuxoGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: avuxoGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.subtitle.isEmpty ? 'Brasil' : item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.48),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.25),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avuxoGreen.withValues(alpha: 0.10),
              border: Border.all(
                color: avuxoGreen.withValues(alpha: 0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: avuxoGreen.withValues(alpha: 0.08),
                  blurRadius: 28,
                ),
              ],
            ),
            child: const Icon(
              Icons.route_rounded,
              color: avuxoGreen,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Busque seu destino',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Digite uma rua, bairro, comércio ou ponto de referência para iniciar sua corrida AVUXO.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: selectingAddress ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: avuxoGreen.withValues(alpha: 0.14),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}