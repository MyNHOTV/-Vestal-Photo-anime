import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:get/get.dart';

class MainTabbarController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final Set<int> _initializedTabs = <int>{};

  @override
  void onInit() {
    super.onInit();
    // Khởi tạo tab đầu tiên (Home) khi app khởi động
    _initializeTab(0);
  }

  bool isTabInitialized(int index) {
    return _initializedTabs.contains(index);
  }

  void changeTab(int index) {
    if (index != currentIndex.value && index >= 0 && index < 4) {
      currentIndex.value = index;
      _initializeTab(index);
    }
  }

  void navigateToGenerate() {
    changeTab(2); // Tab 2 (index 2) is AiToolScreen
  }

  void navigateToLibrary() {
    changeTab(3); // Tab 3 (index 3) is LibraryScreen
  }

  void _initializeTab(int index) {
    if (!_initializedTabs.contains(index)) {
      _initializedTabs.add(index);
    }
  }
}
