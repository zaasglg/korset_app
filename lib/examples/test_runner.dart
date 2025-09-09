import 'package:flutter/material.dart';
import '../examples/category_filtering_test.dart';

/// Simple runner to test category filtering functionality
class TestRunner {
  static Future<void> runCategoryFilteringTests() async {
    print('🚀 Starting Category Filtering Tests...\n');
    
    final tester = CategoryFilteringTest();
    await tester.runAllTests();
  }
  
  static Widget buildDemoApp() {
    return MaterialApp(
      title: 'Category Filtering Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CategoryFilteringDemo(),
    );
  }
}

/// Example of how to use the enhanced ProductService with category filtering
void main() async {
  // Run tests
  await TestRunner.runCategoryFilteringTests();
  
  // Run demo app
  runApp(TestRunner.buildDemoApp());
}
