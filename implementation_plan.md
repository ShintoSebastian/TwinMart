# Implementation Plan - Display Product Description in Product Card

## Problem
The user reported that the product description they added in the admin panel was not visible in the "Browse Products" (Shop) screen.

## Solution
Update the `_ProductCard` widget in `lib/shop_screen.dart` to check for and render the `description` field from Firestore.

## Changes
### `lib/shop_screen.dart`
- **Component**: `_ProductCard`
- **Change**: 
  - Added a conditional check for `product['description']`.
  - Added a `Text` widget to display the description below the product name.
  - Styled with smaller grey text and limited to 2 lines (`maxLines: 2`, `overflow: TextOverflow.ellipsis`) to preserve the card layout.

## Verification
1. Navigate to the Admin Dashboard > Products.
2. Edit a product and ensure it has a description.
3. Switch to the User Dashboard > Browse Products.
4. Verify the description text appears below the product name in the grid card.
