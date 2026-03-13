
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  // This script is intended to be run in a way that it can access Firebase.
  // Since I don't have direct access to the user's Firebase config here,
  // I will provide the logic that would be used in a Flutter environment.
  
  print('Starting inventory update...');
  
  final products = await FirebaseFirestore.instance.collection('products').get();
  
  WriteBatch batch = FirebaseFirestore.instance.batch();
  int count = 0;
  
  for (var doc in products.docs) {
    batch.update(doc.reference, {'offlineStock': 50});
    count++;
    
    // Batches are limited to 500 operations
    if (count % 500 == 0) {
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
    }
  }
  
  await batch.commit();
  print('Successfully updated $count products with offlineStock = 50.');
}
