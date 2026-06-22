import 'package:flutter/material.dart';

import '../models/search_category.dart';

/// Ana sekme (Keşfet / Profil) kontrolü.
class MainTabController {
  MainTabController._();

  static final MainTabController instance = MainTabController._();

  void Function(int)? _switchTab;

  void attach(void Function(int index) switchTab) => _switchTab = switchTab;

  void detach() => _switchTab = null;

  void selectTab(int index) => _switchTab?.call(index);
}

/// Keşfet sekmesindeki kategori seçimini dışarıdan günceller.
class ExploreSearchController {
  ExploreSearchController._();

  static final ExploreSearchController instance = ExploreSearchController._();

  void Function(SearchCategory)? _selectCategory;
  SearchCategory? _pendingCategory;

  void attach(void Function(SearchCategory category) selectCategory) {
    _selectCategory = selectCategory;
    final pending = _pendingCategory;
    if (pending != null) {
      _pendingCategory = null;
      selectCategory(pending);
    }
  }

  void detach() {
    _selectCategory = null;
  }

  void selectCategory(SearchCategory category) {
    if (_selectCategory != null) {
      _selectCategory!(category);
    } else {
      _pendingCategory = category;
    }
  }
}

abstract final class AppNavigation {
  static const exploreTab = 0;
  static const profileTab = 1;

  /// Tüm sayfaları kapatıp Keşfet sekmesine döner.
  static void openExploreTab(
    BuildContext context, {
    SearchCategory? category,
  }) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
    MainTabController.instance.selectTab(exploreTab);
    if (category != null) {
      ExploreSearchController.instance.selectCategory(category);
    }
  }

  /// Bir üst sayfaya döner ve Keşfet sekmesini açar.
  static void popToExplore(
    BuildContext context, {
    SearchCategory? category,
  }) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    MainTabController.instance.selectTab(exploreTab);
    if (category != null) {
      ExploreSearchController.instance.selectCategory(category);
    }
  }
}
