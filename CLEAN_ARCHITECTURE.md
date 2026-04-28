# Clean Architecture - Flutter với GetX

Dự án đã được refactor để tuân theo **Clean Architecture** với 3 layers chính:

## 📁 Cấu trúc thư mục

```
lib/
├── core/                          # Shared code
│   ├── base/                      # Base classes
│   ├── config/                    # App configuration
│   ├── constants/                 # Constants
│   ├── di/                        # Dependency Injection
│   ├── extensions/                # Extension methods
│   ├── network/                   # Network utilities
│   ├── routes/                    # Route management
│   ├── services/                  # Services
│   ├── storage/                    # Local storage
│   ├── theme/                     # Theme configuration
│   ├── utils/                     # Utilities
│   └── widgets/                   # Common widgets
│
└── features/                      # Feature modules
    └── sample_api/
        ├── data/                  # Data Layer
        │   ├── datasources/       # Data sources (Remote, Local)
        │   ├── models/            # Data Models (DTOs)
        │   └── repositories/     # Repository Implementations
        │
        ├── domain/                # Domain Layer (Business Logic)
        │   ├── entities/          # Business Entities
        │   ├── repositories/      # Repository Interfaces
        │   └── usecases/         # Use Cases
        │
        └── presentation/         # Presentation Layer (UI)
            └── controllers/       # Controllers (ViewModels)
```

## 🏗️ Các Layers

### 1. **Domain Layer** (Business Logic)
**Không phụ thuộc vào framework, pure Dart code**

- **Entities**: Business objects thuần túy
  ```dart
  // lib/features/sample_api/domain/entities/sample_entity.dart
  class SampleEntity {
    final String value;
    // Pure business object, không có JsonSerializable
  }
  ```

- **Repository Interfaces**: Định nghĩa contract
  ```dart
  // lib/features/sample_api/domain/repositories/sample_repository.dart
  abstract class SampleRepository {
    Future<Either<AppError, SampleEntity>> getSample();
  }
  ```

- **Use Cases**: Business logic
  ```dart
  // lib/features/sample_api/domain/usecases/get_sample_usecase.dart
  class GetSampleUseCase {
    final SampleRepository repository;
    
    Future<Either<AppError, SampleEntity>> call() {
      return repository.getSample();
    }
  }
  ```

### 2. **Data Layer** (Data Management)
**Phụ thuộc vào Domain Layer**

- **Models**: DTOs cho API (có JsonSerializable)
  ```dart
  // lib/features/sample_api/data/models/sample_model.dart
  @JsonSerializable()
  class SampleModel {
    // Convert Model <-> Entity
    SampleEntity toEntity();
    factory SampleModel.fromEntity(SampleEntity entity);
  }
  ```

- **Data Sources**: Giao tiếp với API và Local Storage
  ```dart
  // Remote Data Source
  abstract class SampleRemoteDataSource {
    Future<Either<AppError, SampleModel>> getSample();
  }
  
  // Local Data Source
  abstract class SampleLocalDataSource {
    Future<Either<AppError, SampleModel?>> getCachedSample();
    Future<Either<AppError, void>> cacheSample(SampleModel model);
  }
  ```

- **Repository Implementations**: Kết hợp Remote và Local
  ```dart
  // lib/features/sample_api/data/repositories/sample_repository_impl.dart
  class SampleRepositoryImpl implements SampleRepository {
    // 1. Thử lấy từ cache
    // 2. Lấy từ API
    // 3. Cache lại nếu thành công
    // 4. Trả về cache nếu API lỗi
  }
  ```

### 3. **Presentation Layer** (UI)
**Phụ thuộc vào Domain Layer**

- **Controllers**: Sử dụng Use Cases
  ```dart
  // lib/features/sample_api/presentation/controllers/sample_controller.dart
  class SampleController extends BaseController {
    final GetSampleUseCase getSampleUseCase;
    
    Future<void> fetch() async {
      await execute(() async {
        final result = await getSampleUseCase();
        return result.fold(
          (error) => setError(error),
          (entity) => result.value = entity.value,
        );
      });
    }
  }
  ```

- **Pages**: UI components sử dụng Controllers

## 🔄 Dependency Flow

```
Presentation Layer
       ↓
Domain Layer (Use Cases, Repository Interfaces)
       ↓
Data Layer (Repository Implementations, Data Sources)
       ↓
External (API, Local Storage)
```

**Quy tắc**: 
- Inner layers không phụ thuộc vào outer layers
- Domain Layer không phụ thuộc vào bất kỳ layer nào
- Data Layer phụ thuộc vào Domain Layer
- Presentation Layer phụ thuộc vào Domain Layer

## 🔌 Dependency Injection

Tất cả dependencies được inject qua `InjectionContainer`:

```dart
// lib/core/di/injection_container.dart
class InjectionContainer {
  static void init() {
    // 1. Data Sources
    Get.lazyPut<SampleRemoteDataSource>(...);
    Get.lazyPut<SampleLocalDataSource>(...);
    
    // 2. Repositories
    Get.lazyPut<SampleRepository>(...);
    
    // 3. Use Cases
    Get.lazyPut<GetSampleUseCase>(...);
    
    // 4. Controllers
    Get.lazyPut<SampleController>(...);
  }
}
```

## 📝 Ví dụ Flow

1. **User clicks button** → `HomePage` gọi `sampleController.fetch()`
2. **Controller** → Gọi `GetSampleUseCase()`
3. **Use Case** → Gọi `SampleRepository.getSample()`
4. **Repository** → 
   - Gọi `RemoteDataSource.getSample()` (API)
   - Nếu lỗi, lấy từ `LocalDataSource.getCachedSample()`
   - Cache lại nếu API thành công
5. **Repository** → Convert `SampleModel` → `SampleEntity`
6. **Use Case** → Trả về `Either<AppError, SampleEntity>`
7. **Controller** → Update UI state
8. **Page** → Hiển thị data hoặc error

## ✅ Lợi ích của Clean Architecture

1. **Separation of Concerns**: Mỗi layer có trách nhiệm riêng
2. **Testability**: Dễ test từng layer độc lập
3. **Maintainability**: Dễ maintain và mở rộng
4. **Independence**: Domain layer không phụ thuộc framework
5. **Flexibility**: Dễ thay đổi data source (API, Local) mà không ảnh hưởng business logic

## 🎯 Best Practices

1. **Entities**: Pure Dart objects, không có annotations
2. **Models**: Có JsonSerializable, convert sang Entity
3. **Use Cases**: Mỗi use case chỉ làm 1 việc
4. **Repository**: Kết hợp Remote và Local data sources
5. **Controllers**: Chỉ gọi Use Cases, không gọi trực tiếp API

## 📚 Tài liệu tham khảo

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)

