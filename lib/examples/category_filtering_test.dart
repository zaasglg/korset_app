import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product_filters.dart';
import '../models/product.dart';

/// Test class to verify category filtering functionality
class CategoryFilteringTest {
  final ProductService _productService = ProductService();

  /// Test basic category filtering
  Future<void> testBasicCategoryFiltering() async {
    print('🧪 Testing Basic Category Filtering...');
    
    try {
      // Test 1: Get products from a specific category (ID: 1)
      print('\n📋 Test 1: Getting products from category 1...');
      final products1 = await _productService.getProductsByCategory(
        categoryId: 1,
        limit: 5,
      );
      print('✅ Found ${products1.length} products in category 1');
      
      // Test 2: Get products from multiple categories
      print('\n📋 Test 2: Getting products from multiple categories [1, 2]...');
      final productsMultiple = await _productService.getProductsByCategories(
        categoryIds: [1, 2],
        limit: 10,
      );
      print('✅ Found ${productsMultiple.length} products in categories [1, 2]');
      
      // Test 3: Use ProductFilters for advanced filtering
      print('\n📋 Test 3: Using ProductFilters with category and price range...');
      final filters = ProductFilters();
      filters.addCategory(1);
      filters.minPrice = 1000;
      filters.maxPrice = 100000;
      filters.sortBy = ProductSortOptions.priceAsc;
      
      final filteredProducts = await _productService.getProductsWithFilters(
        filters: filters,
        limit: 5,
      );
      print('✅ Found ${filteredProducts.length} products with filters');
      print('   Filters: ${filters.activeFiltersCount} active filters');
      
      // Test 4: Search with category filtering
      print('\n📋 Test 4: Advanced search with category filtering...');
      final searchResults = await _productService.searchProductsAdvanced(
        query: 'iPhone',
        categoryIds: [1],
        minPrice: 10000,
        maxPrice: 500000,
        sortBy: ProductSortOptions.priceDesc,
      );
      print('✅ Found ${searchResults.length} products matching search criteria');
      
      print('\n🎉 All category filtering tests completed successfully!');
      
    } catch (e) {
      print('❌ Test failed with error: $e');
    }
  }

  /// Test ProductFilters functionality
  Future<void> testProductFilters() async {
    print('\n🧪 Testing ProductFilters Class...');
    
    try {
      final filters = ProductFilters();
      
      // Test adding categories
      filters.addCategory(1);
      filters.addCategory(2);
      filters.addCategory(2); // Should not add duplicate
      print('✅ Categories: ${filters.categoryIds}');
      
      // Test removing categories
      filters.removeCategory(2);
      print('✅ After removal: ${filters.categoryIds}');
      
      // Test price range
      filters.minPrice = 5000;
      filters.maxPrice = 50000;
      print('✅ Price range: ${filters.minPrice} - ${filters.maxPrice}');
      
      // Test search term
      filters.search = 'test product';
      print('✅ Search term: ${filters.search}');
      
      // Test sort option
      filters.sortBy = ProductSortOptions.popularityDesc;
      print('✅ Sort by: ${filters.sortBy}');
      
      // Test active filters count
      print('✅ Active filters count: ${filters.activeFiltersCount}');
      
      // Test conversion to map
      final filterMap = filters.toMap();
      print('✅ Filter map: $filterMap');
      
      // Test copying filters
      final filtersCopy = filters.copy();
      print('✅ Filters copied successfully. Copy has ${filtersCopy.activeFiltersCount} filters');
      
      // Test clearing filters
      filters.clear();
      print('✅ Filters cleared. Active count: ${filters.activeFiltersCount}');
      
      print('\n🎉 ProductFilters tests completed successfully!');
      
    } catch (e) {
      print('❌ ProductFilters test failed: $e');
    }
  }

  /// Test sort options
  void testSortOptions() {
    print('\n🧪 Testing ProductSortOptions...');
    
    print('Available sort options:');
    for (final option in ProductSortOptions.allOptions) {
      print('  - $option: ${ProductSortOptions.getDisplayName(option)}');
    }
    
    print('\n🎉 Sort options test completed!');
  }

  /// Run all tests
  Future<void> runAllTests() async {
    print('🚀 Starting Category Filtering Tests...\n');
    
    testSortOptions();
    await testProductFilters();
    await testBasicCategoryFiltering();
    
    print('\n✨ All tests completed!');
  }
}

/// Widget to demonstrate category filtering in action
class CategoryFilteringDemo extends StatefulWidget {
  const CategoryFilteringDemo({Key? key}) : super(key: key);

  @override
  State<CategoryFilteringDemo> createState() => _CategoryFilteringDemoState();
}

class _CategoryFilteringDemoState extends State<CategoryFilteringDemo> {
  final ProductService _productService = ProductService();
  final ProductFilters _filters = ProductFilters();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDemoData();
  }

  Future<void> _loadDemoData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Configure demo filters
      _filters.addCategory(1);
      _filters.sortBy = ProductSortOptions.dateDesc;
      
      final products = await _productService.getProductsWithFilters(
        filters: _filters,
        limit: 10,
      );

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Filtering Demo'),
        backgroundColor: const Color(0xff183B4E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Filters:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Categories: ${_filters.categoryIds}'),
                  Text('Sort: ${_filters.sortBy}'),
                  Text('Active filters: ${_filters.activeFiltersCount}'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Results
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text('Error: $_error', style: const TextStyle(color: Colors.red))
            else ...[
              Text(
                'Found ${_products.length} products:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text('${product.price} ₸ • ${product.city.name}'),
                        trailing: Text(product.category.name),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadDemoData,
        backgroundColor: const Color(0xff183B4E),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
