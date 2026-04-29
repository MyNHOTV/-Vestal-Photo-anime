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
    if (index != currentIndex.value && index >= 0 && index < 2) {
      currentIndex.value = index;
      _initializeTab(index);
    }
  }

  void navigateToLibrary() {
    changeTab(1); // Tab 1 is LibraryScreen
  }

  void _initializeTab(int index) {
    if (!_initializedTabs.contains(index)) {
      _initializedTabs.add(index);
    }
  }
}
