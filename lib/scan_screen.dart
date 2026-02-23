import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';    
import 'payment_methods_screen.dart';
import 'product_details_screen.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;

class ScanScreen extends StatefulWidget {
  final VoidCallback onBackToDashboard; 

  const ScanScreen({super.key, required this.onBackToDashboard});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  // Reverted to default settings for maximum compatibility
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 250, // Ultra-fast detection cycles
    autoStart: true,
    formats: [BarcodeFormat.all],
  );
  
  final GlobalKey _scannerKey = GlobalKey();
  
  final Color twinGreen = TwinMartTheme.brandGreen;
  
  double userBudgetLimit = 0.0;
  double previousSpending = 0.0; 
  double currentSessionTotal = 0.0; 
  bool isDataLoaded = false;

  List<Map<String, dynamic>> currentSessionItems = [];
  bool _isProcessingScan = false; 
  DateTime? _lastScanTime;
  String _lastScannedDisplay = "Ready to scan";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    // Initial spending load
    _updatePreviousSpending();
  }

  Future<void> _updatePreviousSpending() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final transSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .get();

      double tempOfflineSpent = 0;
      for (var doc in transSnapshot.docs) {
        final data = doc.data();
        if ((data['type'] ?? 'offline') == 'offline') {
          tempOfflineSpent += (data['price'] ?? 0.0).toDouble();
        }
      }

      if (mounted) {
        setState(() {
          previousSpending = tempOfflineSpent;
        });
      }
    } catch (e) {
      debugPrint("Error updating spending: $e");
    }
  }

  void _checkBudgetAlert(double itemPrice, String itemName) {
    if (userBudgetLimit <= 0) return; 

    double totalWithItem = previousSpending + currentSessionTotal + itemPrice;
    double progress = totalWithItem / userBudgetLimit;

    if (progress >= 1.0) {
      _showPremiumAlert(
        title: "Limit Exceeded! 🚨",
        msg: "Adding $itemName (₹${itemPrice.toInt()}) puts you at ₹${totalWithItem.toInt()}, which is over your ₹${userBudgetLimit.toInt()} offline budget!",
        isCritical: true,
      );
    } else if (progress >= 0.75) {
      _showPremiumAlert(
        title: "Almost There! ⚠️",
        msg: "You've reached 75% of your offline budget. This $itemName costs ₹${itemPrice.toInt()}.",
        isCritical: false,
      );
    } else if (progress >= 0.50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 10),
              Text("Budget Warning: 50% Used (₹${totalWithItem.toInt()}/₹${userBudgetLimit.toInt()})"),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orangeAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showPremiumAlert({required String title, required String msg, bool isCritical = false}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: isCritical ? Colors.red[50] : Colors.orange[50],
                child: Icon(isCritical ? Icons.report_problem : Icons.warning_amber_rounded, 
                    color: isCritical ? Colors.red : Colors.orange, size: 30),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCritical ? Colors.red : twinGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text("Got it", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateItemQuantity(int index, int delta) {
    setState(() {
      final item = currentSessionItems[index];
      int currentQty = item['quantity'] ?? 1;
      double price = (item['price'] ?? 0.0).toDouble();

      if (currentQty + delta <= 0) {
        currentSessionTotal -= price * currentQty;
        currentSessionItems.removeAt(index);
      } else {
        currentSessionItems[index]['quantity'] = currentQty + delta;
        currentSessionTotal += price * delta;
      }
      
      if (currentSessionTotal < 0) currentSessionTotal = 0;
    });
  }

  Future<void> _handleScannedCode(String code) async {
    // Prevent multiple concurrent scans
    if (_isProcessingScan) return;

    // Basic debounce to prevent immediate double-processing
    if (_lastScanTime != null && 
        DateTime.now().difference(_lastScanTime!) < const Duration(milliseconds: 2000)) {
      return;
    }

    setState(() => _isProcessingScan = true);
    HapticFeedback.mediumImpact();
    debugPrint("🔎 Processing Code: $code");

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: code)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final product = snapshot.docs.first.data();
        product['id'] = snapshot.docs.first.id;
        double price = (product['price'] ?? 0.0).toDouble();
        String name = product['name'] ?? "Item";
        String productId = product['id'];

        _checkBudgetAlert(price, name);

        setState(() {
           int existingIndex = currentSessionItems.indexWhere((item) => item['id'] == productId);
           if (existingIndex != -1) {
             currentSessionItems[existingIndex]['quantity'] = (currentSessionItems[existingIndex]['quantity'] ?? 1) + 1;
           } else {
             product['quantity'] = 1;
             currentSessionItems.add(product);
           }
           currentSessionTotal += price;
           _lastScanTime = DateTime.now();
           _lastScannedDisplay = "✅ Processed: $name";
        });

        // ✅ NEW: Save to Recently Scanned in Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('recently_scanned')
              .doc(productId)
              .set({
                'name': name,
                'price': price,
                'imageUrl': product['imageUrl'],
                'timestamp': FieldValue.serverTimestamp(),
              });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Added $name"), backgroundColor: twinGreen, duration: const Duration(milliseconds: 1000)),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text("❌ Item not found: $code"), 
             backgroundColor: Colors.redAccent, 
             duration: const Duration(seconds: 2)
           ),
         );
         _lastScanTime = DateTime.now(); 
         _lastScannedDisplay = "❌ Not found: $code";
      }
    } catch (e) {
      debugPrint("🔥 Error checking product: $e");
    } finally {
       if (mounted) {
         setState(() => _isProcessingScan = false);
       }
    }
  }

  void _showManualEntryDialog() {
    final TextEditingController _codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Barcode"),
        content: TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "E.g. 8901234567890"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: twinGreen),
            onPressed: () {
              if (_codeController.text.isNotEmpty) {
                Navigator.pop(context);
                _handleScannedCode(_codeController.text.trim());
              }
            }, 
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (currentSessionTotal == 0) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodsScreen(
          amount: currentSessionTotal,
          items: List.from(currentSessionItems),
        ),
      ),
    );

    if (result == true && mounted) {
      // ✅ NEW: Calculate Savings
      double totalAfter = previousSpending + currentSessionTotal;
      if (userBudgetLimit > 0 && totalAfter < userBudgetLimit) {
        double saved = userBudgetLimit - totalAfter;
        _showSavingsAlert(saved);
        _updateSavingsInCloud(saved);
      }

      setState(() {
        previousSpending += currentSessionTotal;
        currentSessionTotal = 0.0;
        currentSessionItems.clear();
      });
    }
  }

  void _showSavingsAlert(double savedAmount) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [Colors.white, twinGreen.withOpacity(0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: twinGreen.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.savings_rounded, color: twinGreen, size: 50),
              ),
              const SizedBox(height: 25),
              const Text("Smart Shopper! 🎉", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 15),
              Text(
                "You stayed under your limit and saved ₹${savedAmount.toInt()} from your budget!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: twinGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text("Awesome!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateSavingsInCloud(double savedAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('budget')
          .doc('settings')
          .set({
            'total_savings': savedAmount, // This updates the home page display
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating savings: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.stop();
    } else if (state == AppLifecycleState.resumed) {
      cameraController.start();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwinMartTheme.bgLight,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -100,
            right: -100,
            size: 300,
            color: TwinMartTheme.brandGreen.withOpacity(0.2),
          ),
          TwinMartTheme.bgBlob(
            bottom: 100,
            left: -80,
            size: 250,
            color: TwinMartTheme.brandBlue.withOpacity(0.15),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: SafeArea(
              child: Column( 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0), 
                    child: _buildHeader(),
                  ),
                  
                  // Re-designed Scanner Box with Manual Entry Option
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                       _buildScannerBox(),
                       Positioned(
                         bottom: 12,
                         child: ClipRRect(
                           borderRadius: BorderRadius.circular(20),
                           child: BackdropFilter(
                             filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                             child: Container(
                               decoration: BoxDecoration(
                                 color: Colors.black.withOpacity(0.3),
                                 borderRadius: BorderRadius.circular(20),
                               ),
                               child: Material(
                                 color: Colors.transparent,
                                 child: InkWell(
                                   onTap: _showManualEntryDialog,
                                   borderRadius: BorderRadius.circular(20),
                                   child: Padding(
                                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                     child: Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         const Icon(Icons.keyboard_outlined, color: Colors.white, size: 18),
                                         const SizedBox(width: 8),
                                         const Text("Enter Manually", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                             ),
                           ),
                         ),
                       )
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    child: _buildInstructionBar(),
                  ),
                  
                  // Live Cart List Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0), 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         const Text("Cart Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (currentSessionItems.isNotEmpty)
                          Text("${currentSessionItems.length} Products", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildCartList(),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), 
                    child: Column(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        _buildBudgetCard(),
                        const SizedBox(height: 2), 
                        _buildPayButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                TwinMartTheme.brandLogo(size: 22),
                const SizedBox(width: 10),
                TwinMartTheme.brandText(fontSize: 22),
              ],
            ),
            GestureDetector(
              onTap: widget.onBackToDashboard, 
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ]
                ),
                child: const Icon(Icons.close_rounded, size: 20, color: TwinMartTheme.darkText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('Scan & Shop', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: TwinMartTheme.darkText)),
        const Text('Scan barcodes to bypass billing counter', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildScannerBox() {
    return Container(
      height: 220, width: double.infinity, 
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(35)),
      clipBehavior: Clip.hardEdge, 
      child: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: cameraController,
            fit: BoxFit.cover, // Reverted to cover for better focus area
            key: _scannerKey,
            errorBuilder: (context, error, child) {
              debugPrint("🔥 Camera Error: ${error.errorCode}");
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off, color: Colors.white54, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      "Camera Error: ${error.errorCode}",
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            },
            onDetect: (capture) {
              debugPrint("📸 Frame captured. Barcodes: ${capture.barcodes.length}");
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              
              for (final barcode in barcodes) {
                final String? code = barcode.displayValue ?? barcode.rawValue;
                debugPrint("📡 Detected Code: $code");
                if (code != null && code.isNotEmpty) {
                  _handleScannedCode(code);
                  break; 
                }
              }
            },
          ),
          
          // Visual guiding frame - Made larger for better visibility
          Container(
            width: 220, height: 130, 
            decoration: BoxDecoration(
              border: Border.all(color: twinGreen.withOpacity(0.5), width: 2), 
              borderRadius: BorderRadius.circular(15)
            ),
            child: Stack(
              children: [
                _buildScanAnimation(),
              ],
            ),
          ),
          
          if (_isProcessingScan)
             Container(
               color: Colors.black45,
               child: const Center(child: CircularProgressIndicator(color: Colors.white)),
             ),

          // Torch Toggle (Flash)
          Positioned(
            top: 10,
            right: 15,
            child: ValueListenableBuilder(
              valueListenable: cameraController,
              builder: (context, value, child) {
                final torchState = value.torchState;
                return IconButton(
                  icon: Icon(
                    torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: () => cameraController.toggleTorch(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                );
              },
            ),
          ),

          // Restart Camera Button
          Positioned(
            top: 10,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () async {
                await cameraController.stop();
                await cameraController.start();
                setState(() {
                  _lastScannedDisplay = "Scanner Resetted";
                });
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    if (currentSessionItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text("Scan items to add them here", style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: currentSessionItems.length,
      itemBuilder: (context, index) {
        final item = currentSessionItems[index];
        final int qty = item['quantity'] ?? 1;
        final double price = (item['price'] ?? 0).toDouble();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: item),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 2,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F9F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Hero(
                        tag: 'product-${item['id']}',
                        child: item['imageUrl'] != null
                            ? Image.network(item['imageUrl'], width: 30, height: 30, errorBuilder: (_, __, ___) => const Text("🛍️"))
                            : const Text("🛍️", style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text("₹$price", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  _buildQtyController(index, qty),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQtyController(int index, int qty) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18, color: Colors.black87),
            onPressed: () => _updateItemQuantity(index, -1),
            constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
            padding: EdgeInsets.zero,
          ),
          Text(
            "$qty",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: Colors.black87),
            onPressed: () => _updateItemQuantity(index, 1),
            constraints: const BoxConstraints(minWidth: 35, minHeight: 1),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBar() {
    bool isError = _lastScannedDisplay.contains("Not found");
    bool isSuccess = _lastScannedDisplay.contains("Added") || _lastScannedDisplay.contains("✅");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : (isSuccess ? TwinMartTheme.brandGreen.withOpacity(0.08) : Colors.white), 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isError ? Colors.red.withOpacity(0.1) : (isSuccess ? TwinMartTheme.brandGreen.withOpacity(0.1) : Colors.grey[100]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError ? Icons.error_outline : (isSuccess ? Icons.check_circle_outline : Icons.qr_code_scanner_rounded), 
              color: isError ? Colors.red : (isSuccess ? TwinMartTheme.brandGreen : Colors.grey), 
              size: 18
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _lastScannedDisplay, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14, 
                color: isError ? Colors.red[700] : (isSuccess ? TwinMartTheme.brandGreen : TwinMartTheme.darkText)
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanAnimation() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value * 130, // Matches frame height
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: twinGreen.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
              color: twinGreen,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('budget')
          .doc('settings')
          .snapshots(),
      builder: (context, snapshot) {
        double limit = 0.0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          limit = (data?['budget_limit'] ?? 0.0).toDouble();
        }
        userBudgetLimit = limit;

        double totalSpent = previousSpending + currentSessionTotal;
        double progressPercent = limit > 0 ? (totalSpent / limit) * 100 : 0;
        bool isWarning = progressPercent >= 75 && progressPercent < 100;
        bool isOver = progressPercent >= 100;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), 
          decoration: BoxDecoration(
            color: isOver ? Colors.red[50] : (isWarning ? Colors.orange[50] : Colors.white), 
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 35, height: 35,
                    child: CircularProgressIndicator(
                      value: (progressPercent / 100).clamp(0.0, 1.0),
                      strokeWidth: 4,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOver ? Colors.red : (isWarning ? Colors.orange : TwinMartTheme.brandGreen)
                      ),
                    ),
                  ),
                  Text('${progressPercent.toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total: ₹${totalSpent.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TwinMartTheme.darkText)),
                    Text('Budget Limit: ₹${limit.toInt()}', style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (isOver)
                const Icon(Icons.error_outline, color: Colors.red, size: 24)
              else if (isWarning)
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24)
              else
                const Icon(Icons.check_circle_outline, color: TwinMartTheme.brandGreen, size: 24),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPayButton() {
    bool hasItems = currentSessionTotal > 0;
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: hasItems ? [
          BoxShadow(color: TwinMartTheme.brandGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: hasItems ? _processPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: TwinMartTheme.brandGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment_rounded, size: 18),
            const SizedBox(width: 10),
            Text(
              "Pay ₹${currentSessionTotal.toInt()} Now", 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}