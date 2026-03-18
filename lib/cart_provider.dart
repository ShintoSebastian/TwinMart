import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'image': image,
      'category': category,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0.0).toDouble(),
      image: map['image'] ?? '',
      category: map['category'] ?? 'Others',
    );
  }
}

class CartProvider with ChangeNotifier {
  // Internal state using a Map for O(1) lookups by Product ID
  Map<String, CartItem> _items = {};
  StreamSubscription? _authSubscription;
  StreamSubscription? _cartSubscription;

  CartProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startCartSync(user.uid);
      } else {
        _stopCartSync();
        _items = {};
        notifyListeners();
      }
    });
  }

  void _startCartSync(String uid) {
    _cartSubscription?.cancel();
    _cartSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      _items = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _items[doc.id] = CartItem.fromMap(data);
      }
      notifyListeners();
    });
  }

  void _stopCartSync() {
    _cartSubscription?.cancel();
    _cartSubscription = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cartSubscription?.cancel();
    super.dispose();
  }

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

  // Helper to get Firestore cart reference
  CollectionReference? get _cartRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('cart');
  }

  // 3. Add to Cart with Cloud Sync (Optimistic UI)
  Future<void> addToCart(Map<String, dynamic> product) async {
    final String productId = product['id']?.toString() ?? '';
    if (productId.isEmpty) return;

    // 1. Optimistic Update (Update local state immediately for Premium feel)
    _updateLocalCart(product, productId);

    final ref = _cartRef;
    if (ref == null) return; // If guest mode, we're done after local update

    try {
      if (_items[productId]!.quantity > 1) {
        // Document exists in local state with qty > 1, so update in Cloud
        await ref.doc(productId).update({
          'quantity': _items[productId]!.quantity,
        });
      } else {
        // New item, set in Cloud
        await ref.doc(productId).set(_items[productId]!.toMap());
      }
    } catch (e) {
      debugPrint("❌ [CartProvider] Error adding to Cloud: $e");
      // Rollback or handle error if needed, but keeping local state usually feels better
    }
  }

  void _updateLocalCart(Map<String, dynamic> product, String productId) {
    if (_items.containsKey(productId)) {
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
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          name: product['name'] ?? 'Unknown Product',
          price: (product['price'] ?? 0.0).toDouble(),
          image: product['image'] ?? product['imageUrl'] ?? '🛍️',
          category: product['category'] ?? 'Miscellaneous',
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  // 4. Decrement Quantity or Remove Item
  Future<void> removeSingleItem(String productId) async {
    if (!_items.containsKey(productId)) return;

    // 1. Optimistic Update
    _removeSingleItemLocal(productId);

    final ref = _cartRef;
    if (ref == null) return;

    try {
      if (_items.containsKey(productId)) {
        await ref.doc(productId).update({
          'quantity': _items[productId]!.quantity,
        });
      } else {
        await ref.doc(productId).delete();
      }
    } catch (e) {
      debugPrint("❌ [CartProvider] Error removing from Cloud: $e");
    }
  }

  void _removeSingleItemLocal(String productId) {
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          image: existing.image,
          category: existing.category,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  // 5. Utility: Remove entire line item
  Future<void> removeItemCompletely(String productId) async {
    final ref = _cartRef;
    if (ref != null) {
      await ref.doc(productId).delete();
    } else {
      _items.remove(productId);
      notifyListeners();
    }
  }

  // 6. Utility: Wipe cart
  Future<void> clearCart() async {
    final ref = _cartRef;
    if (ref != null) {
      final snapshot = await ref.get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } else {
      _items = {};
      notifyListeners();
    }
  }
}