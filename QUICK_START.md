# Quick Start Guide

## 📦 Installation

### Option 1: Run Directly
```bash
cd your_flutter_project/
dart run tools/bin/feature_gen.dart
```

### Option 2: Global Installation (Optional)
```bash
cd tools/
dart pub global activate --source path .

# Then run from anywhere
feature_gen
```

## 🚀 Usage Examples

### Example 1: Product Reviews
Generate a product reviews feature with default columns:

```bash
dart run tools/bin/feature_gen.dart product_reviews product
```

**Generated Structure:**
```
lib/features/product_reviews/
├── domain/
│   ├── entities/
│   │   └── product_review.dart
│   ├── repositories/
│   │   └── product_review_repository.dart
│   └── usecases/
│       ├── create_product_review_usecase.dart
│       ├── update_product_review_usecase.dart
│       ├── delete_product_review_usecase.dart
│       ├── get_all_product_review_usecase.dart
│       ├── get_by_product_id_product_review_usecase.dart
│       ├── get_by_id_product_review_usecase.dart
│       ├── search_product_review_usecase.dart
│       └── sync_pending_product_review_usecase.dart
├── data/
│   ├── models/
│   │   └── product_review_model.dart
│   ├── datasources/
│   │   ├── product_review_local_data_source.dart
│   │   └── product_review_remote_data_source.dart
│   └── repositories/
│       └── product_review_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── product_review_event.dart
    │   ├── product_review_state.dart
    │   └── product_review_bloc.dart
    └── pages/
        ├── product_review_list_page.dart
        ├── product_review_detail_page.dart
        └── product_review_form_page.dart
```

### Example 2: Order Notes with Custom Columns
```bash
dart run tools/bin/feature_gen.dart order_notes order "note:string,priority:int,completed:bool,due_date:DateTime?"
```

**Generated Columns:**
- `id` (auto-increment)
- `orderId` (foreign key)
- `note` (string, required)
- `priority` (int, required)
- `completed` (bool, required)
- `dueDate` (DateTime, nullable)
- `syncStatus` (string, default: 'pending')
- `createdAt` (DateTime, auto)
- `updatedAt` (DateTime, nullable, auto)

### Example 3: Customer Feedback
```bash
dart run tools/bin/feature_gen.dart customer_feedback customer "rating:int,comment:string?,sentiment:string,submitted_at:DateTime"
```

### Example 4: Interactive Mode
```bash
dart run tools/bin/feature_gen.dart

# Prompts:
# 1. Package name: (auto-detected) litro_sales_tracker ✓
# 2. Feature name: product_images
# 3. Parent entity: product
# 4. Columns: url:string,caption:string?,is_primary:bool
```

## 🔧 Post-Generation Setup

### Step 1: Update Database
**File:** `lib/core/database/app_database.dart`

```dart
import 'tables/product_reviews_table.dart';  // Add import

@DriftDatabase(
  tables: [
    // Existing tables...
    Sales,
    Products,
    ProductReviews,  // Add your new table
  ],
  daos: [/* ... */],
)
class AppDatabase extends _$AppDatabase {
  // ... existing code
}
```

### Step 2: Add DAO Methods
**File:** `lib/core/database/app_database.dart`

```dart
// Inside AppDatabase class

// Get all reviews
Future<List<ProductReview>> getAllProductReviews() {
  return select(productReviews).get();
}

// Get reviews for a product
Future<List<ProductReview>> getProductReviewsByProductId(int productId) {
  return (select(productReviews)
    ..where((t) => t.productId.equals(productId)))
    .get();
}

// Get single review
Future<ProductReview?> getProductReviewById(int id) {
  return (select(productReviews)
    ..where((t) => t.id.equals(id)))
    .getSingleOrNull();
}

// Search reviews
Future<List<ProductReview>> searchProductReviews(String query) {
  return (select(productReviews)
    ..where((t) => t.comment.contains(query)))
    .get();
}

// Create review
Future<int> insertProductReview(ProductReviewsCompanion companion) {
  return into(productReviews).insert(companion);
}

// Update review
Future<void> updateProductReview(ProductReview entity) {
  return update(productReviews).replace(entity);
}

// Delete review
Future<void> deleteProductReview(int id) {
  return (delete(productReviews)..where((t) => t.id.equals(id))).go();
}

// Get pending reviews (for sync)
Future<List<ProductReview>> getPendingProductReviews() {
  return (select(productReviews)
    ..where((t) => t.syncStatus.equals('pending')))
    .get();
}

// Mark as synced
Future<void> markAsProductReviewSynced(int id) {
  return (update(productReviews)..where((t) => t.id.equals(id)))
    .write(const ProductReviewsCompanion(syncStatus: Value('synced')));
}
```

### Step 3: Update Database Version
**File:** `lib/core/config/constants.dart` (or wherever you define version)

```dart
static const int databaseVersion = 2;  // Increment from 1 to 2
```

### Step 4: Add Migration
**File:** `lib/core/database/app_database.dart`

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Create product_reviews table in version 2
        await m.createTable(productReviews);
      }
      // Add more migrations as needed
    },
  );
}
```

### Step 5: Run Build Runner
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 6: Use in Your App

**Navigate to list:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProductReviewListPage(productId: product.id),
  ),
);
```

**Or use as a tab:**
```dart
DefaultTabController(
  length: 3,
  child: Column(
    children: [
      TabBar(tabs: [
        Tab(text: 'Details'),
        Tab(text: 'Reviews'),  // Your new feature
        Tab(text: 'Images'),
      ]),
      Expanded(
        child: TabBarView(children: [
          ProductDetailTab(),
          ProductReviewListPage(productId: widget.productId),  // Your new feature
          ProductImagesTab(),
        ]),
      ),
    ],
  ),
)
```

## 🎨 Customization Examples

### Add Custom Form Fields

**File:** `lib/features/product_reviews/presentation/pages/product_review_form_page.dart`

```dart
class _ProductReviewFormPageState extends State<ProductReviewFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _ratingController = TextEditingController();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    if (widget.entity != null) {
      _ratingController.text = widget.entity!.rating?.toString() ?? '';
      _titleController.text = widget.entity!.title ?? '';
      _commentController.text = widget.entity!.comment ?? '';
    }
  }
  
  @override
  void dispose() {
    _ratingController.dispose();
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }
  
  Widget _buildFormFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Rating field
            TextFormField(
              controller: _ratingController,
              decoration: const InputDecoration(
                labelText: 'Rating (1-5)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                final rating = int.tryParse(value!);
                if (rating == null || rating < 1 || rating > 5) {
                  return 'Must be between 1 and 5';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Comment field
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleSubmit(BuildContext context, bool isEdit) {
    if (!_formKey.currentState!.validate()) return;
    
    final entity = ProductReviewEntity(
      id: widget.entity?.id ?? 0,
      productId: widget.productId,
      rating: int.parse(_ratingController.text),
      title: _titleController.text,
      comment: _commentController.text.isEmpty ? null : _commentController.text,
      timestamp: DateTime.now(),
      syncStatus: 'pending',
      createdAt: widget.entity?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    if (isEdit) {
      context.read<ProductReviewBloc>().add(UpdateProductReview(entity));
    } else {
      context.read<ProductReviewBloc>().add(CreateProductReview(entity));
    }
  }
}
```

### Customize Detail Page

**File:** `lib/features/product_reviews/presentation/pages/product_review_detail_page.dart`

```dart
Widget _buildDetailsCard(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details', style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          const SizedBox(height: 8),
          
          // Rating with stars
          _buildDetailRow(
            'Rating',
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < entity.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
          ),
          
          // Title
          _buildDetailRow('Title', entity.title ?? 'N/A'),
          
          // Comment
          _buildDetailRow('Comment', entity.comment ?? 'No comment'),
          
          // Date
          _buildDetailRow(
            'Date',
            DateFormat.yMMMd().add_jm().format(entity.timestamp),
          ),
        ],
      ),
    ),
  );
}
```

## 📱 Example: Complete Integration

Here's how to integrate the generated feature into your app:

```dart
// In your product detail page
class ProductDetailPage extends StatelessWidget {
  final Product product;
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(product.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProductDetailsTab(product: product),
            ProductReviewListPage(productId: product.id),  // ← Your generated feature
          ],
        ),
      ),
    );
  }
}
```

## 🐛 Troubleshooting

### Build Runner Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Import Errors
Make sure all generated files are imported correctly:
```dart
import 'package:your_app/features/product_reviews/...';
```

### Database Errors
If you get database errors, try:
```bash
# Uninstall app
# Then reinstall to recreate database
flutter run
```

## 📚 Additional Resources

- [README.md](README.md) - Full documentation
- [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Architecture details
- [Drift Documentation](https://drift.simonbinder.eu/)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## 🎉 Success!

You now have a complete, production-ready feature with:
- ✅ Clean Architecture
- ✅ BLoC State Management
- ✅ Offline-First Support
- ✅ Type-Safe Database
- ✅ Full CRUD Operations
- ✅ Sync Capabilities
- ✅ Professional UI

Happy coding! 🚀