import 'package:flutter/material.dart';

// 1. Model for items stored in the cart
class CartItem {
  final String id; // Alphanumeric ID for Firebase compatibility
  final String name;
  final int quantity;
  final double price;
  final String image;
  final String category;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
    this.category = 'Others',
  });
}

class CartProvider with ChangeNotifier {
  // Internal state using a Map for O(1) lookups by Product ID
  Map<String, CartItem> _items = {};

  // Getter to provide a copy of items to prevent external mutation
  Map<String, CartItem> get items => {..._items};

  // Total unique items in the cart
  int get itemCount => _items.length;

  // 2. Calculated Total Amount
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // 3. Add to Cart with Robust ID and Price Parsing
  void addToCart(Map<String, dynamic> product) {
    // Force ID to String and handle potential nulls safely
    final String productId = product['id']?.toString() ?? '';
    if (productId.isEmpty) return;

    if (_items.containsKey(productId)) {
      // Update quantity if item already exists
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          image: existingItem.image,
          category: existingItem.category,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      // Add new item with safe fallbacks and explicit double conversion
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          name: product['name'] ?? 'Unknown Product',
          // Firebase might send ints or doubles; .toDouble() prevents crashes
          price: (product['price'] ?? 0.0).toDouble(), 
          // Handle both 'image' and admin panel 'imageUrl' fields
          image: product['image'] ?? product['imageUrl'] ?? '🛍️',
          category: product['category'] ?? 'Others',
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  // 4. Decrement Quantity or Remove Item
  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          image: existing.image,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  // 5. Utility: Remove entire line item regardless of quantity
  void removeItemCompletely(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // 6. Utility: Wipe cart after successful checkout
  void clearCart() {
    _items = {};
    notifyListeners();
  }
}