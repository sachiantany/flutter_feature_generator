# Flutter Feature Generator v2.0

A modular, maintainable code generator for Flutter features following Clean Architecture and BLoC pattern.

## 🏗️ Architecture

The generator is built with clean, modular architecture:

```
tools/
├── bin/
│   └── feature_gen.dart           # Entry point (50 lines)
│
├── lib/
│   ├── models/
│   │   ├── column.dart            # Column model (90 lines)
│   │   └── generation_config.dart # Configuration (90 lines)
│   │
│   ├── utils/
│   │   ├── naming_converter.dart  # Naming utilities (90 lines)
│   │   ├── type_mapper.dart       # Type mapping (110 lines)
│   │   ├── validators.dart        # Input validation (90 lines)
│   │   └── file_writer.dart       # File operations (90 lines)
│   │
│   ├── generators/
│   │   ├── base_generator.dart          # Abstract base (30 lines)
│   │   ├── infrastructure_generator.dart # Directories & core files (180 lines)
│   │   ├── database_generator.dart      # Drift tables (40 lines)
│   │   ├── domain_generator.dart        # Entities & repos (100 lines)
│   │   ├── usecase_generator.dart       # Use cases (170 lines)
│   │   ├── data_generator.dart          # Models & data sources (480 lines)
│   │   └── presentation_generator.dart  # BLoC & UI (580 lines)
│   │
│   ├── modes/
│   │   ├── interactive_mode.dart   # Interactive prompts (180 lines)
│   │   └── command_line_mode.dart  # CLI argument parsing (100 lines)
│   │
│   └── orchestrator.dart           # Coordinates generation (60 lines)
│
└── pubspec.yaml
```

**Total: ~2,400 lines** (vs 4,200 lines in monolithic version)

## ✨ Benefits of Modular Architecture

### 1. **Maintainability**
- Each file has a single responsibility
- Easy to find and fix bugs
- Changes are localized

### 2. **Testability**
- Each component can be unit tested
- Mock dependencies easily
- TDD-friendly structure

### 3. **Extensibility**
- Add new generators without touching existing code
- Support multiple output formats
- Easy to add features

### 4. **Reusability**
- Utilities shared across all generators
- No code duplication
- Consistent behavior

### 5. **Readability**
- Files are 30-580 lines (vs 1,420+ lines)
- Clear naming and organization
- Self-documenting structure

## 🚀 Usage

### Interactive Mode
```bash
dart run tools/bin/feature_gen.dart
```

Prompts you for:
- Package name (auto-detected from pubspec.yaml)
- Feature name (e.g., `product_reviews`)
- Parent entity (e.g., `product`)
- Columns (optional, uses defaults if empty)

### Command-Line Mode
```bash
# Basic usage (default columns)
dart run tools/bin/feature_gen.dart product_reviews product

# With custom columns
dart run tools/bin/feature_gen.dart order_notes order "note:string,priority:int"

# With nullable columns
dart run tools/bin/feature_gen.dart customer_feedback customer "rating:int,comment:string?,date:DateTime"
```

## 📦 What Gets Generated

### 1. **Database Layer**
- Drift table definition
- Auto-increment ID
- Foreign keys
- Sync status tracking
- Timestamps

### 2. **Domain Layer**
- Entity with Equatable
- Repository interface
- 8 use cases:
  - Create, Update, Delete
  - Get All, Get By Parent ID, Get By ID
  - Search
  - Sync Pending

### 3. **Data Layer**
- Model with conversions (fromDatabase, fromJson, toJson)
- Local data source (Drift with full CRUD)
- Remote data source (API placeholder)
- Repository implementation with offline-first logic

### 4. **Presentation Layer**
- BLoC (Events, States, Bloc)
- List page with:
  - Pull-to-refresh
  - Sync status indicators
  - Empty state
- Detail page with:
  - View entity details
  - Edit/delete actions
  - Sync status chip
- Form page:
  - Create/edit modes
  - Validation ready
  - Loading states

### 5. **Core Infrastructure**
- Failures (7 types)
- Network info (connectivity checking)
- Dependency injection setup

## 🎯 Column Types

Supported types:
- `string` → String
- `int` → int
- `datetime` → DateTime
- `double` → double
- `bool` → bool

Add `?` for nullable:
- `comment:string?` → nullable String
- `rating:int` → required int

## 📝 Column Definition Examples

```bash
# Rating system
"rating:int,review:string?,date:DateTime"

# Order notes
"note:string,priority:int,completed:bool"

# Customer feedback
"score:int,comment:string?,sentiment:string,submitted_at:DateTime"

# Product metadata
"sku:string,quantity:int,price:double,available:bool"
```

## 🔧 Post-Generation Steps

1. **Update `lib/core/database/app_database.dart`**
   ```dart
   @DriftDatabase(
     tables: [
       // ... existing tables
       ProductReviews,  // Add your new table
     ],
     daos: [/* ... */],
   )
   ```

2. **Add DAO methods**
   ```dart
   // In AppDatabase class
   Future<List<ProductReview>> getAllProductReviews() {
     return select(productReviews).get();
   }
   
   Future<List<ProductReview>> getProductReviewsByProductId(int productId) {
     return (select(productReviews)
       ..where((t) => t.productId.equals(productId)))
       .get();
   }
   
   Future<ProductReview?> getProductReviewById(int id) {
     return (select(productReviews)
       ..where((t) => t.id.equals(id)))
       .getSingleOrNull();
   }
   
   Future<List<ProductReview>> searchProductReviews(String query) {
     return (select(productReviews)
       ..where((t) => t.comment.contains(query)))
       .get();
   }
   
   Future<int> insertProductReview(ProductReviewsCompanion companion) {
     return into(productReviews).insert(companion);
   }
   
   Future<void> updateProductReview(ProductReview entity) {
     return update(productReviews).replace(entity);
   }
   
   Future<void> deleteProductReview(int id) {
     return (delete(productReviews)..where((t) => t.id.equals(id))).go();
   }
   
   Future<List<ProductReview>> getPendingProductReviews() {
     return (select(productReviews)
       ..where((t) => t.syncStatus.equals('pending')))
       .get();
   }
   
   Future<void> markAsProductReviewSynced(int id) {
     return (update(productReviews)..where((t) => t.id.equals(id)))
       .write(const ProductReviewsCompanion(syncStatus: Value('synced')));
   }
   ```

3. **Update database version**
   ```dart
   // In constants.dart or database config
   static const int databaseVersion = 2;  // Increment
   ```

4. **Add migration**
   ```dart
   @override
   MigrationStrategy get migration {
     return MigrationStrategy(
       onUpgrade: (m, from, to) async {
         if (from < 2) {
           await m.createTable(productReviews);
         }
       },
     );
   }
   ```

5. **Run build_runner** (if not already run)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. **Register in DI** (if using manual registration)
   ```dart
   // In injection.dart or DI setup
   getIt.registerFactory(() => ProductReviewBloc(...));
   ```

## 🎨 Customization

### Add Custom Fields to Forms

In `*_form_page.dart`:
```dart
// Add controllers
final _titleController = TextEditingController();
final _ratingController = TextEditingController();

// Initialize
@override
void initState() {
  super.initState();
  if (widget.entity != null) {
    _titleController.text = widget.entity!.title ?? '';
    _ratingController.text = widget.entity!.rating?.toString() ?? '';
  }
}

// Add fields
TextFormField(
  controller: _titleController,
  decoration: const InputDecoration(labelText: 'Title'),
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
),

TextFormField(
  controller: _ratingController,
  decoration: const InputDecoration(labelText: 'Rating'),
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Required';
    if (int.tryParse(value!) == null) return 'Must be a number';
    return null;
  },
),
```

### Customize Detail Page

In `*_detail_page.dart`, add to `_buildDetailsCard()`:
```dart
_buildDetailRow('Title', entity.title ?? 'N/A'),
_buildDetailRow('Rating', entity.rating?.toString() ?? 'N/A'),
_buildDetailRow('Date', DateFormat.yMMMd().format(entity.date)),
```

### Add Search to List Page

In `*_list_page.dart`:
```dart
// Add to AppBar
actions: [
  IconButton(
    icon: const Icon(Icons.search),
    onPressed: () => _showSearchDialog(context),
  ),
],

// Add search dialog
void _showSearchDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Search'),
      content: TextField(
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Search...'),
        onSubmitted: (query) {
          context.read<ProductReviewBloc>().add(SearchProductReviews(query));
          Navigator.pop(context);
        },
      ),
    ),
  );
}
```

## 🧪 Testing

Each generator is independently testable:

```dart
test('NamingConverter converts snake_case to PascalCase', () {
  expect(NamingConverter.toPascal('product_review'), 'ProductReview');
});

test('TypeMapper maps string to Dart String', () {
  expect(TypeMapper.toDartType('string'), 'String');
});

test('Column parses definition correctly', () {
  final col = Column.parse('title:string?');
  expect(col.name, 'title');
  expect(col.type, 'string');
  expect(col.isNullable, true);
});
```

## 🔄 Extending the Generator

### Add a New Generator

1. Create `lib/generators/your_generator.dart`:
```dart
import 'base_generator.dart';

class YourGenerator extends BaseGenerator {
  const YourGenerator(super.config);

  @override
  Future<void> generate() async {
    // Your generation logic
    await writeToFile('path/to/file.dart', content);
  }
}
```

2. Add to orchestrator:
```dart
print('   [X/N] Generating your feature...');
await YourGenerator(config).generate();
```

### Add a New Utility

Create `lib/utils/your_utility.dart` with static methods, then import where needed.

### Add a New Column Type

Update `lib/utils/type_mapper.dart`:
```dart
case 'json':
  return 'Map<String, dynamic>';
```

## 📊 Comparison

| Metric | Monolithic | Modular |
|--------|-----------|---------|
| Total Lines | 4,200 | 2,400 |
| Largest File | 1,420 | 580 |
| Files | 3 | 17 |
| Testability | Low | High |
| Maintainability | Low | High |
| Extensibility | Hard | Easy |

## 🤝 Contributing

Contributions welcome! The modular structure makes it easy:

1. Want to add a feature? Add a new generator
2. Want to fix a bug? Find the specific file
3. Want to add tests? Each component is testable
4. Want to improve docs? Each file is self-contained

## 📄 License

MIT License - Feel free to use and modify!

## 🙏 Credits

Built for the litro-sales-tracker project by Finetech/FCPL.