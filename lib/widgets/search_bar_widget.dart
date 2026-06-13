import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/gpkg_service.dart';
import '../services/location_service.dart';
import '../services/search_service.dart';
import '../theme/app_theme.dart';

/// שורת חיפוש עם תוצאות
class DerSearchBar extends StatefulWidget {
  final ValueChanged<SearchResult> onResultSelected;

  const DerSearchBar({
    super.key,
    required this.onResultSelected,
  });

  @override
  State<DerSearchBar> createState() => _DerSearchBarState();
}

class _DerSearchBarState extends State<DerSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<SearchResult> _results = [];
  bool _isExpanded = false;
  bool _showCategories = false;
  bool _hasSearched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isExpanded = true;
          _showCategories = _controller.text.isEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.length < 2) {
        setState(() {
          _results = [];
          _showCategories = true;
          _hasSearched = false;
        });
        return;
      }

      final gpkg = context.read<GpkgService>();
      final location = context.read<LocationService>();
      final searchService = SearchService(gpkg);
      final results = searchService.search(
        query,
        nearLocation: location.currentLocation,
      );

      setState(() {
        _results = results;
        _showCategories = false;
        _hasSearched = true;
      });
    });
  }

  void _onCategoryTap(QuickCategory category) {
    final gpkg = context.read<GpkgService>();
    final location = context.read<LocationService>();
    final searchService = SearchService(gpkg);
    final center = location.currentLocation ?? LocationService.defaultLocation;

    final results = searchService.searchByCategory(
      category.fclass,
      center,
      radiusDeg: 0.1,
    );

    setState(() {
      _results = results;
      _showCategories = false;
      _hasSearched = true;
      _controller.text = category.name;
    });
  }

  void _selectResult(SearchResult result) {
    widget.onResultSelected(result);
    _controller.text = result.name;
    _focusNode.unfocus();
    setState(() {
      _isExpanded = false;
      _results = [];
      _hasSearched = false;
    });
  }

  void _close() {
    _focusNode.unfocus();
    setState(() {
      _isExpanded = false;
      _results = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // שורת חיפוש
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: AppTheme.glassDecoration,
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search, color: Colors.white54, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'לאן נוסעים?',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.white54,
                  onPressed: () {
                    _controller.clear();
                    _onSearchChanged('');
                  },
                ),
              if (_isExpanded)
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  color: Colors.white54,
                  onPressed: _close,
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        // תוצאות / קטגוריות
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(maxHeight: 350),
            decoration: AppTheme.glassDecoration,
            child: _showCategories ? _buildCategories() : _buildResults(),
          ),
        ],
      ],
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 4, bottom: 8),
            child: Text(
              'קטגוריות',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QuickCategory.categories.map((cat) {
              return InkWell(
                onTap: () => _onCategoryTap(cat),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withAlpha(10),
                    border: Border.all(
                      color: Colors.white.withAlpha(38),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            _hasSearched ? 'לא נמצאו תוצאות' : 'התחל להקליד כדי לחפש',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: Colors.white.withAlpha(13),
        indent: 56,
      ),
      itemBuilder: (context, index) {
        final result = _results[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(result.icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          title: Text(
            result.name,
            style: const TextStyle(fontSize: 14),
            textDirection: TextDirection.rtl,
          ),
          subtitle: Text(
            result.category +
                (result.distanceMeters != null
                    ? ' · ${result.formattedDistance}'
                    : ''),
            style: TextStyle(
              color: Colors.white.withAlpha(128),
              fontSize: 12,
            ),
            textDirection: TextDirection.rtl,
          ),
          dense: true,
          onTap: () => _selectResult(result),
        );
      },
    );
  }
}
