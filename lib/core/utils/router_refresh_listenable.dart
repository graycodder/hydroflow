import 'package:flutter/material.dart';

class RouterRefreshListenable extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final routerRefreshListenable = RouterRefreshListenable();
