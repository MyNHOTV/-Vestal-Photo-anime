import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/connectivity_service.dart';
import 'package:flutter_quick_base/core/services/daily_generation_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/scan_line_image_widget.dart';
import 'package:get/get.dart';

import '../../../../core/constants/export_constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/export_widgets.dart';
import '../controllers/image_generation_controller.dart';

/// Màn hình loading khi đang generate ảnh
class ImageGeneratingScreen extends StatefulWidget {
  const ImageGeneratingScreen({super.key});

  @override
  State<ImageGeneratingScreen> createState() => _ImageGeneratingScreenState();
}

class _ImageGeneratingScreenState extends State<ImageGeneratingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _scannerAnimationController;
  late Animation<double> _scannerAnimation;

  Timer? _progressTimer;
  double _progress = 0.0;
  bool _isGenerating = false;
  bool _hasError = false;
  bool _isErrorDialogShowing = false;
  bool _isAppInBackground = false;
  bool _isDisposed = false;
  bool _hasNavigated = false;
  bool _isManualBack =
      false; // Flag để phân biệt back thủ công vs generation hoàn thành

  ImageGenerationController? _controller;
  StreamSubscription? _connectivitySubscription;

  // Thời gian random cho giai đoạn 61-99%
  late Duration _randomDuration;

  // Thêm biến để lưu progress khi pause
  double _savedProgress = 0.0;
  bool _isPaused = false;
  int _savedPhase1Step = 0;
  int _savedPhase2Step = 0;
  bool _wasInPhase2 = false;
  bool _hasStartedProgress = false;
  bool _fastMode = false;

  @override
  void initState() {
    super.initState();
    try {
      WidgetsBinding.instance.addObserver(this);

      _scannerAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1), // Thời gian 1 chiều
      )..repeat(reverse: true); // Lật lại khi đến cuối

      // Animation với curve để có hiệu ứng "lật" mượt hơn
      _scannerAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _scannerAnimationController,
        curve: Curves.easeInOutCubic, // Curve mượt hơn, giống camera
      ));

      // Random thời gian từ 1-2 phút cho giai đoạn 61-99%
      final remoteConfig = RemoteConfigService.shared;
      final phase2Min = remoteConfig.generatePhase2MinDuration;
      final phase2Max = remoteConfig.generatePhase2MaxDuration;
      final random = Random();
      final randomSeconds =
          phase2Min + random.nextInt(phase2Max - phase2Min + 1);
      _randomDuration = Duration(seconds: randomSeconds);
      // Đọc fastMode từ arguments
      final args = Get.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _fastMode = args['fastMode'] as bool? ?? false;
      }
      // Reset progress về 0% khi bắt đầu mới (sau khi ad đóng)
      _progress = 0.0;
      _savedProgress = 0.0;
      _isPaused = false;
      _savedPhase1Step = 0;
      _savedPhase2Step = 0;
      _wasInPhase2 = false;
      _hasStartedProgress = false;

      //TODO: Bỏ comment để kích hoạt
      _setupController();
      AnalyticsService.shared.screenProcessingShow();

      // Bắt đầu progress ngay lập tức
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isDisposed && !_hasStartedProgress) {
          _hasStartedProgress = true;
          _startProgress();
        }
      });
    } catch (e) {
      print('Error in initState: $e');
      // Fallback: navigate back nếu có lỗi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.back();
        }
      });
    }
  }

  void _setupController() {
    try {
      _controller = Get.find<ImageGenerationController>();
      // Listen connectivity changes với error handling
      _connectivitySubscription =
          ConnectivityService.shared.connectivityStatus.listen(
        (results) {
          if (!mounted || _isDisposed) return;
          try {
            final isConnected = ConnectivityService.shared.isConnected;

            if (!isConnected && _isGenerating) {
              // Mất mạng khi đang generate - reset về 0% và dừng hoàn toàn
              _progressTimer?.cancel();
              _progressTimer = null;
              setState(() {
                _progress = 0.0; // Reset progress về 0%
                _hasError = true;
                _isErrorDialogShowing = false; // Không show dialog khi mất mạng
                // Giữ _isGenerating = true để biết đang trong quá trình generate
              });
            } else if (isConnected && _hasError && _isGenerating) {
              // Mạng trở lại khi có error và đang generate - tự động restart
              setState(() {
                _hasError = false;
                _isErrorDialogShowing = false;
              });
              // Reset controller state và restart
              if (_controller != null) {
                _controller!.error.value = null;
                _controller!.isGenerating.value = true;
              }
              _restart();
            } else if (isConnected && _hasError) {
              // Mạng trở lại nhưng không đang generate - chỉ reset flag
              setState(() {
                _hasError = false;
                _isErrorDialogShowing = false;
              });
            }
          } catch (e) {
            print('Error in connectivity listener: $e');
          }
        },
        onError: (error) {
          print('Connectivity stream error: $error');
        },
      );
      // Kiểm tra trạng thái hiện tại
      if (_controller != null && _controller!.isGenerating.value) {
        _isGenerating = true;
      }

      // Listen generation state với null check
      if (_controller != null) {
        ever(_controller!.isGenerating, (bool isGenerating) {
          if (!mounted || _isDisposed || _hasNavigated) {
            return; // Thêm check _hasNavigated
          }
          try {
            if (!isGenerating && _isGenerating) {
              _isGenerating = false;

              // Nếu là back thủ công, không gọi _completeProgress()
              if (_isManualBack) {
                debugPrint(
                    '⏸️ Manual back detected, saving progress: ${_progress.toStringAsFixed(1)}%');
                // Lưu progress hiện tại
                _savedProgress = _progress;
                _isPaused = true;
                _progressTimer?.cancel();

                // Xác định phase hiện tại để lưu
                if (_progress >= 61.0) {
                  _wasInPhase2 = true;
                  const phase2Steps = 38;
                  _savedPhase2Step =
                      (((_progress - 61.0) / 38.0) * phase2Steps).floor();
                  _savedPhase1Step = 0;
                } else {
                  _wasInPhase2 = false;
                  const phase1Steps = 60;
                  _savedPhase1Step = ((_progress / 60.0) * phase1Steps).floor();
                  _savedPhase2Step = 0;
                }
                return; // Không gọi _completeProgress()
              }

              // Chỉ gọi _completeProgress() khi generation thực sự hoàn thành
              if (_controller?.error.value != null) {
                _handleError(_controller!.error.value!.message);
              } else {
                // Success - đẩy progress lên 100%
                _completeProgress();
              }
            } else if (isGenerating && !_isGenerating) {
              _isGenerating = true;
            }
          } catch (e) {
            print('Error in isGenerating listener: $e');
          }
        });

        // Listen error với null check
        ever(_controller!.error, (error) {
          if (!mounted || _isDisposed || _hasNavigated) return; // Thêm check
          try {
            if (error != null && _isGenerating) {
              _handleError(error.message);
            }
          } catch (e) {
            print('Error in error listener: $e');
          }
        });
      }
    } catch (e) {
      // Retry sau 100ms
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_isDisposed) {
          _setupController();
        }
      });
    }
  }

  void _startProgress() {
    if (!mounted || _isDisposed) return;

    // Nếu đã có saved progress, resume từ đó
    if (_savedProgress > 0.0 && _isPaused) {
      _resumeFromSavedProgress();
      return;
    }
    // Nếu fastMode được bật, chạy fast progress (0->99% trong 15s)
    if (_fastMode) {
      _startFastProgress();
      return;
    }

    // Reset nếu bắt đầu mới
    _savedProgress = 0.0;
    _savedPhase1Step = 0;
    _savedPhase2Step = 0;
    _wasInPhase2 = false;
    _isPaused = false;

    // Giai đoạn 1: 0% -> 60% trong 3 giây
    const phase1Duration = Duration(seconds: 30);
    const phase1Steps = 60;
    final phase1StepDuration = Duration(
      milliseconds: phase1Duration.inMilliseconds ~/ phase1Steps,
    );

    int phase1Step = 0;
    _progressTimer = Timer.periodic(phase1StepDuration, (timer) {
      if (!mounted ||
          _isDisposed ||
          _hasError ||
          _isPaused ||
          !ConnectivityService.shared.isConnected) {
        if (_isPaused) {
          timer.cancel();
          // Lưu progress khi pause trong phase 1
          _savedProgress = _progress;
          _savedPhase1Step = phase1Step;
          _savedPhase2Step = 0;
          _wasInPhase2 = false;
          print(
              '⏸️ Paused in phase 1: progress=${_progress.toStringAsFixed(1)}%, step=$phase1Step');
        } else if (!ConnectivityService.shared.isConnected && _isGenerating) {
          timer.cancel();
          setState(() {
            _progress = 0.0;
            _hasError = true;
          });
        }
        return;
      }
      try {
        phase1Step++;
        if (phase1Step <= phase1Steps) {
          if (mounted && !_isDisposed) {
            setState(() {
              _progress = (phase1Step / phase1Steps) * 60.0;
            });
          }
        } else {
          // Chuyển sang giai đoạn 2: 61% -> 99%
          timer.cancel();
          _startPhase2();
        }
      } catch (e) {
        print('Error in progress timer: $e');
        timer.cancel();
      }
    });
  }

  /// Fast progress: 0% -> 99% trong 15 giây (cho quick generate)
  void _startFastProgress() {
    if (!mounted || _isDisposed) return;

    // Reset nếu bắt đầu mới
    _savedProgress = 0.0;
    _savedPhase1Step = 0;
    _savedPhase2Step = 0;
    _wasInPhase2 = false;
    _isPaused = false;

    const fastDuration = Duration(seconds: 15); // 15 giây
    const fastSteps = 99; // Từ 0% đến 99%
    final fastStepDuration = Duration(
      milliseconds: fastDuration.inMilliseconds ~/ fastSteps,
    );

    int fastStep = 0;
    _progressTimer = Timer.periodic(fastStepDuration, (timer) {
      if (!mounted ||
          _isDisposed ||
          _hasError ||
          _isPaused ||
          !ConnectivityService.shared.isConnected) {
        if (_isPaused) {
          timer.cancel();
          _savedProgress = _progress;
          print(
              '⏸️ Paused in fast mode: progress=${_progress.toStringAsFixed(1)}%');
        } else if (!ConnectivityService.shared.isConnected && _isGenerating) {
          timer.cancel();
          setState(() {
            _progress = 0.0;
            _hasError = true;
          });
        }
        return;
      }

      try {
        fastStep++;
        if (fastStep <= fastSteps) {
          if (mounted && !_isDisposed) {
            setState(() {
              _progress = fastStep.toDouble(); // 0 -> 99
            });
          }
        } else {
          // Đến 99%, gọi API
          timer.cancel();
          if (mounted && !_isDisposed) {
            setState(() {
              _progress = 99.0;
            });
            // Gọi API khi đến 99%
            _callGenerateAPI();
          }
        }
      } catch (e) {
        print('Error in fast progress timer: $e');
        timer.cancel();
      }
    });
  }

  void _startPhase2() {
    if (!mounted || _isDisposed) return;

    // Giai đoạn 2: 61% -> 99% trong thời gian random
    const phase2Steps = 38; // 99 - 61 = 38
    final phase2StepDuration = Duration(
      milliseconds: _randomDuration.inMilliseconds ~/ phase2Steps,
    );

    int phase2Step = _wasInPhase2 ? _savedPhase2Step : 0;
    _progressTimer = Timer.periodic(phase2StepDuration, (timer) {
      if (!mounted ||
          _isDisposed ||
          _hasError ||
          _isPaused ||
          !ConnectivityService.shared.isConnected) {
        if (_isPaused) {
          timer.cancel();
          _savedProgress = _progress;
          _savedPhase2Step = phase2Step;
          _wasInPhase2 = true;
        } else if (!ConnectivityService.shared.isConnected && _isGenerating) {
          timer.cancel();
          setState(() {
            _progress = 0.0;
            _hasError = true;
          });
        }
        return;
      }

      try {
        phase2Step++;
        if (phase2Step <= phase2Steps) {
          if (mounted && !_isDisposed) {
            setState(() {
              _progress = 61.0 + (phase2Step / phase2Steps) * 38.0;
            });
          }
        } else {
          // Đến 99%, gọi API
          timer.cancel();
          if (mounted && !_isDisposed) {
            setState(() {
              _progress = 99.0;
            });
            // Gọi API khi đến 99%
            _callGenerateAPI();
          }
        }
      } catch (e) {
        print('Error in phase2 timer: $e');
        timer.cancel();
      }
    });
  }

  void _resumeFromSavedProgress() {
    if (!mounted || _isDisposed) return;

    print(
        '▶️ Resuming from saved progress: ${_savedProgress.toStringAsFixed(1)}%, wasInPhase2=$_wasInPhase2');

    _isPaused = false;

    // Set lại progress từ saved value
    setState(() {
      _progress = _savedProgress;
    });

    // Nếu đã ở phase 2, resume phase 2
    if (_wasInPhase2 && _savedProgress >= 61.0) {
      print('▶️ Resuming phase 2 from step $_savedPhase2Step');
      _resumePhase2();
    } else if (_savedProgress < 60.0) {
      // Resume phase 1
      print('▶️ Resuming phase 1 from step $_savedPhase1Step');
      _resumePhase1();
    } else {
      // Chuyển sang phase 2
      print('▶️ Starting phase 2 (progress >= 60%)');
      _startPhase2();
    }
  }

  void _resumePhase1() {
    if (!mounted || _isDisposed) return;

    const phase1Duration = Duration(seconds: 30);
    const phase1Steps = 60;
    final phase1StepDuration = Duration(
      milliseconds: phase1Duration.inMilliseconds ~/ phase1Steps,
    );

    // Tính toán lại phase1Step từ saved progress, đảm bảo không giảm
    int phase1Step = ((_savedProgress / 60.0) * phase1Steps).floor();
    // Đảm bảo progress không giảm
    if (_progress > _savedProgress) {
      phase1Step = ((_progress / 60.0) * phase1Steps).floor();
    }

    if (phase1Step >= phase1Steps) {
      // Nếu đã vượt quá, chuyển sang phase 2
      _startPhase2();
      return;
    }

    _progressTimer = Timer.periodic(phase1StepDuration, (timer) {
      if (!mounted ||
          _isDisposed ||
          _hasError ||
          _isPaused ||
          !ConnectivityService.shared.isConnected) {
        if (_isPaused) {
          timer.cancel();
          _savedProgress = _progress;
          _savedPhase1Step = phase1Step;
          _wasInPhase2 = false;
        } else if (!ConnectivityService.shared.isConnected && _isGenerating) {
          timer.cancel();
          setState(() {
            _progress = 0.0;
            _hasError = true;
          });
        }
        return;
      }
      try {
        phase1Step++;
        if (phase1Step <= phase1Steps) {
          final newProgress = (phase1Step / phase1Steps) * 60.0;
          // Đảm bảo progress chỉ tăng, không giảm
          if (mounted && !_isDisposed && newProgress >= _progress) {
            setState(() {
              _progress = newProgress;
            });
          }
        } else {
          timer.cancel();
          _startPhase2();
        }
      } catch (e) {
        print('Error in resume phase1 timer: $e');
        timer.cancel();
      }
    });
  }

  void _resumePhase2() {
    if (!mounted || _isDisposed) return;

    _isPaused = false;
    const phase2Steps = 38;
    final phase2StepDuration = Duration(
      milliseconds: _randomDuration.inMilliseconds ~/ phase2Steps,
    );

    // Tính toán lại phase2Step từ saved progress, đảm bảo không giảm
    int phase2Step = (((_savedProgress - 61.0) / 38.0) * phase2Steps).floor();
    if (phase2Step < 0) phase2Step = 0;

    // Đảm bảo progress không giảm
    if (_progress > _savedProgress) {
      phase2Step = (((_progress - 61.0) / 38.0) * phase2Steps).floor();
      if (phase2Step < 0) phase2Step = 0;
    }

    if (phase2Step >= phase2Steps) {
      // Nếu đã vượt quá, gọi API luôn
      _callGenerateAPI();
      return;
    }

    _progressTimer = Timer.periodic(phase2StepDuration, (timer) {
      if (!mounted ||
          _isDisposed ||
          _hasError ||
          _isPaused ||
          !ConnectivityService.shared.isConnected) {
        if (_isPaused) {
          timer.cancel();
          _savedProgress = _progress;
          _savedPhase2Step = phase2Step;
          _savedPhase1Step = 0;
          _wasInPhase2 = true;
          print(
              '⏸️ Paused in phase 2 (resume): progress=${_progress.toStringAsFixed(1)}%, step=$phase2Step');
        } else if (!ConnectivityService.shared.isConnected && _isGenerating) {
          timer.cancel();
          setState(() {
            _progress = 0.0;
            _hasError = true;
          });
        }
        return;
      }

      try {
        phase2Step++;
        if (phase2Step <= phase2Steps) {
          final newProgress = 61.0 + (phase2Step / phase2Steps) * 38.0;
          // Đảm bảo progress chỉ tăng, không giảm
          if (mounted && !_isDisposed && newProgress >= _progress) {
            setState(() {
              _progress = newProgress;
            });
          }
        } else {
          timer.cancel();
          if (mounted && !_isDisposed) {
            setState(() {
              _progress = 99.0;
            });
            _callGenerateAPI();
          }
        }
      } catch (e) {
        print('Error in resume phase2 timer: $e');
        timer.cancel();
      }
    });
  }

  void _callGenerateAPI() {
    if (_controller == null || !mounted || _isDisposed) return;

    // Đảm bảo controller state đúng trước khi gọi API
    if (_controller!.isGenerating.value == false) {
      print(
          '⚠️ Warning: isGenerating is false when calling API, setting to true');
      _controller!.isGenerating.value = true;
    }

    try {
      // Thêm timeout và retry logic
      _controller!.executeGenerateAPI().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          print('⏱️ API call timeout');
          if (mounted && !_isDisposed) {
            _handleError(tr('session_expired'));
          }
        },
      ).catchError((error) {
        print('Error calling generate API: $error');
        if (mounted && !_isDisposed) {
          // Kiểm tra nếu là session expired error
          final errorMessage = error.toString().toLowerCase();
          if (errorMessage.contains('session') ||
              errorMessage.contains('expired') ||
              errorMessage.contains('timeout')) {
            _handleError(tr('session_expired'));
          } else {
            _handleError(tr('error_calling_api',
                namedArgs: {'error': error.toString()}));
          }
        }
      });
    } catch (e) {
      print('Error in _callGenerateAPI: $e');
      if (mounted && !_isDisposed) {
        _handleError(
            tr('error_starting_generate', namedArgs: {'error': e.toString()}));
      }
    }
  }

  void _completeProgress() {
    if (!mounted || _isDisposed || _hasNavigated) return; // Check flag

    // Reset flag khi generation thực sự hoàn thành
    _isManualBack = false;

    try {
      setState(() {
        _progress = 100.0;
      });

      // 100% navigate
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted || _isDisposed || _hasNavigated) return; // Check lại

        try {
          // Kiểm tra route hiện tại trước khi navigate
          if (Get.currentRoute != AppRoutes.imageGenerating) {
            return;
          }

          // Set flag để tránh navigate lại
          _hasNavigated = true;

          final latestGenerated = _controller?.latestGenerated;
          if (latestGenerated != null) {
            // Sử dụng 1 lượt generate
            await DailyGenerationService.shared.useGeneration();
            AnalyticsService.shared.actionGenerateSuccess();
            Get.offNamed(AppRoutes.imageDetail, arguments: latestGenerated);
          } else {
            Get.back();
          }
        } catch (e) {
          print('Error navigating after completion: $e');
          // Fallback: quay lại màn trước
          try {
            Get.back();
          } catch (_) {
            // Ignore nếu không thể back
          }
        }
      });
    } catch (e) {
      print('Error in _completeProgress: $e');
    }
  }

  void _handleError(String message) {
    if (!mounted ||
        _isDisposed ||
        _hasError ||
        _hasNavigated ||
        _isErrorDialogShowing) return;

    try {
      setState(() {
        _hasError = true;
        _isGenerating = false;
        _isErrorDialogShowing = true;
      });

      _progressTimer?.cancel();

      // Kiểm tra context trước khi show dialog
      if (!mounted || context.mounted == false) return;
      // Kiểm tra kết nối mạng của máy
      final isDeviceConnected = ConnectivityService.shared.isConnected;

      if (!isDeviceConnected) {
        // Chỉ reset flag, không show dialog
        setState(() {
          _isErrorDialogShowing = false;
        });
        return;
      }
      // Show simple error dialog without ad confirmation
      showDialog(
        context: Get.context!,
        builder: (ctx) => AlertDialog(
          title: Text(tr('session_expired')),
          actions: [
            TextButton(
              onPressed: () {
                try {
                  setState(() {
                    _isErrorDialogShowing = false;
                  });
                  Navigator.pop(ctx);
                  Get.back();
                } catch (e) {
                  print('Error in dialog cancel: $e');
                }
              },
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () {
                try {
                  setState(() {
                    _isErrorDialogShowing = false;
                  });
                  Navigator.pop(ctx);
                  _retryAPI();
                } catch (e) {
                  print('Error in dialog confirm: $e');
                }
              },
              child: Text(tr('retry')),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isErrorDialogShowing = false; // Reset flag nếu có lỗi
      });
      print('Error in _handleError: $e');
      // Fallback: quay lại màn trước
      try {
        Get.back();
      } catch (_) {
        // Ignore
      }
    }
  }

  /// Retry API khi có lỗi - giữ progress ở 99%, không chạy lại từ đầu
  void _retryAPI() async {
    if (!mounted || _isDisposed) return;

    try {
      // Dừng timer nếu đang chạy
      _progressTimer?.cancel();
      _progressTimer = null;

      // Giữ progress ở 99%, không reset về 0%
      setState(() {
        _hasError = false;
        _isGenerating = true;
        _hasNavigated = false;
        _isErrorDialogShowing = false;
        _progress = 99.0; // Giữ ở 99%
      });

      // Reset controller state trước khi retry
      if (_controller != null) {
        _controller!.isGenerating.value = true;
        _controller!.error.value = null;
      }

      // Đợi một chút rồi gọi lại API (không chạy lại progress)
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted || _isDisposed) return;

      // Gọi lại API trực tiếp, không chạy lại progress
      _callGenerateAPI();
    } catch (e) {
      print('Error in _retryAPI: $e');
      _handleError(tr('error_restarting', namedArgs: {'error': e.toString()}));
    }
  }

  void _restart() async {
    if (!mounted || _isDisposed) return;

    try {
      _progressTimer?.cancel();
      _progressTimer = null;
      _isPaused = false;
      _savedProgress = 0.0;
      _savedPhase1Step = 0;
      _savedPhase2Step = 0;
      _wasInPhase2 = false;
      _hasStartedProgress = false; // Reset flag để có thể start progress lại

      setState(() {
        _progress = 0.0;
        _hasError = false;
        _isGenerating = true;
        _hasNavigated = false;
        _isErrorDialogShowing = false;
      });

      // Reset controller state trước khi retry
      if (_controller != null) {
        _controller!.isGenerating.value = true;
        _controller!.error.value = null;
      }

      // Random lại thời gian
      final random = Random();
      final randomSeconds = 60 + random.nextInt(60);
      _randomDuration = Duration(seconds: randomSeconds);

      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted || _isDisposed) return;
      _startProgress();
    } catch (e) {
      print('Error in _restart: $e');
      _handleError(tr('error_restarting', namedArgs: {'error': e.toString()}));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!mounted || _isDisposed) return;

    try {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        _isAppInBackground = true;
        // Pause progress khi app vào background
        if (_isGenerating && !_isPaused) {
          _isPaused = true;
          _progressTimer?.cancel();

          // Lưu progress và xác định phase hiện tại
          _savedProgress = _progress;

          // Xác định phase dựa trên progress
          if (_progress >= 61.0) {
            // Đang ở phase 2
            _wasInPhase2 = true;
            // Tính toán lại phase2Step từ progress
            const phase2Steps = 38;
            _savedPhase2Step =
                (((_progress - 61.0) / 38.0) * phase2Steps).floor();
            _savedPhase1Step = 0;
            print(
                '⏸️ Progress paused in phase 2: ${_progress.toStringAsFixed(1)}%, step=$_savedPhase2Step');
          } else {
            // Đang ở phase 1
            _wasInPhase2 = false;
            // Tính toán lại phase1Step từ progress
            const phase1Steps = 6;
            _savedPhase1Step = ((_progress / 60.0) * phase1Steps).floor();
            _savedPhase2Step = 0;
            print(
                '⏸️ Progress paused in phase 1: ${_progress.toStringAsFixed(1)}%, step=$_savedPhase1Step');
          }
        }
      } else if (state == AppLifecycleState.resumed) {
        if (_isAppInBackground && _isGenerating) {
          _isAppInBackground = false;
          // Resume progress directly (no ads)
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && !_isDisposed && _isGenerating) {
              _resumeFromSavedProgress();
            }
          });
        } else {
          _isAppInBackground = false;
        }
      }
    } catch (e) {
      print('Error in lifecycle state change: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (e) {
      print('Error removing observer: $e');
    }

    try {
      _scannerAnimationController.dispose();
    } catch (e) {
      print('Error disposing animation controller: $e');
    }

    try {
      _progressTimer?.cancel();
    } catch (e) {
      print('Error canceling progress timer: $e');
    }

    try {
      _connectivitySubscription?.cancel();
    } catch (e) {
      print('Error canceling connectivity subscription: $e');
    }

    super.dispose();
  }

  Future<bool> _handleBackDuringGeneration() async {
    // Nếu không đang generating, thoát bình thường
    if (!_isGenerating || _isPaused) {
      if (_fastMode) {
        await DailyGenerationService.shared.useGeneration();
      }
      _isManualBack = true;
      if (_controller != null) {
        _controller!.isGenerating.value = false;
      }
      return true;
    }

    // Pause generation khi show dialog
    _isPaused = true;
    _progressTimer?.cancel();

    // Lưu progress hiện tại
    _savedProgress = _progress;

    // Xác định phase hiện tại để lưu
    if (_progress >= 61.0) {
      _wasInPhase2 = true;
      const phase2Steps = 38;
      _savedPhase2Step = (((_progress - 61.0) / 38.0) * phase2Steps).floor();
      _savedPhase1Step = 0;
    } else {
      _wasInPhase2 = false;
      const phase1Steps = 60;
      _savedPhase1Step = ((_progress / 60.0) * phase1Steps).floor();
      _savedPhase2Step = 0;
    }

    debugPrint(
        '⏸️ Back pressed during generation - pausing: ${_progress.toStringAsFixed(1)}%');

    // Show simple confirm dialog (no ads)
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('image_being_created')),
        content: Text(tr('canceling_will_stop_image_creation_are_you_sure')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (_fastMode) {
                DailyGenerationService.shared.useGeneration();
              }
              _isManualBack = true;
              if (_controller != null) {
                _controller!.isGenerating.value = false;
              }
              Get.back();
            },
            child: Text(tr('stop')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted && !_isDisposed) {
                _isPaused = false;
                _isManualBack = false;
                if (_controller != null) {
                  _controller!.isGenerating.value = true;
                }
                _resumeFromSavedProgress();
                debugPrint('▶️ Resuming generation after confirm');
              }
            },
            child: Text(tr('keep_generating')),
          ),
        ],
      ),
    );

    return false; // Không thoát ngay, đợi user chọn
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _controller?.selectedImagePath.value ?? '';
    return WillPopScope(
      onWillPop: () async {
        final hasNet = await NetworkService.to.checkNetworkForInAppFunction();
        if (!hasNet) return false;
        return await _handleBackDuringGeneration();
      },
      child: Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/icons/image_generating_screen.png',
                  fit: BoxFit.fill,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 16,
                            ),
                            GestureDetector(
                                onTap: () async {
                                  final hasNet = await NetworkService.to
                                      .checkNetworkForInAppFunction();
                                  if (!hasNet) return;
                                  final shouldExit =
                                      await _handleBackDuringGeneration();
                                  if (shouldExit) {
                                    Get.back();
                                  }
                                },
                                child: Container(
                                    color: Colors.transparent,
                                    padding: const EdgeInsets.only(
                                        right: 10, top: 10, bottom: 10),
                                    child: const SvgIcon(
                                      name: "ic_close",
                                      height: 18,
                                      width: 18,
                                    ))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('your_image_is_being_generated'),
                          style: kBricolageBoldStyle.copyWith(
                            color: AppColors.color121212,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('please_stay_on_this_screen'),
                          style: kBricolageRegularStyle.copyWith(
                            color: AppColors.color434343,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppProgressBar(
                                  progress: (_progress / 100.0).clamp(0.0, 1.0),
                                  height: 8.0,
                                  gradient: const LinearGradient(colors: [
                                    AppColors.color6657F0,
                                    AppColors.color6657F0,
                                  ]),
                                  backgroundColor: AppColors.colorD8D8D8,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                '${_progress.clamp(0.0, 100.0).toInt()}%',
                                style: kBricolageBoldStyle.copyWith(
                                  color: AppColors.color6657F0,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 16, right: 16),
                              child: ScannerLineImageWidget(
                                scannerColor: AppColors.color4A11C4,
                                imagePath: imagePath,
                                width: double.infinity,
                                height:
                                    MediaQuery.of(Get.context!).size.height /
                                        2.8,
                                borderRadius: BorderRadius.circular(16.0),
                                overlayOpacity: 0.7,
                                cornerLength: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
