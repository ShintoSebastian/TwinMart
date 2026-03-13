import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'profile_screen.dart';

class StatisticsScreen extends StatefulWidget {
  final VoidCallback onBackToDashboard;

  const StatisticsScreen({super.key, required this.onBackToDashboard});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String selectedPeriod = "Month";
  bool isLoading = true;

  double totalBudget = 5000.0;
  double totalSpent = 0.0;
  double onlineSpent = 0.0;
  double offlineSpent = 0.0;
  double firstBudgetOfMonth = 0.0;
  int editsThisMonth = 0;

  Map<String, double> splitPercentages = {
    'Groceries': 40.0,
    'Electronics': 20.0,
    'Clothing': 20.0,
    'Food & Dining': 10.0,
    'Others': 10.0,
  };

  final Set<String> _lockedCategories = {};
  final TextEditingController _budgetController = TextEditingController();
  final Map<String, TextEditingController> _catControllers = {};

  Map<String, double> categorySpending = {};
  List<Map<String, dynamic>> recentTransactions = [];
  StreamSubscription? _catSubscription;
  StreamSubscription? _transactionSubscription;
  StreamSubscription? _settingsSubscription;

  final List<Color> _fallbackPalette = [
    const Color(0xFF1DB98A), // Green
    Colors.blue,
    Colors.orange,
    Colors.teal,
    Colors.redAccent,
    Colors.amber,
    Colors.indigo,
    Colors.purple,
    Colors.pinkAccent,
    Colors.cyan,
    Colors.lightGreen,
    Colors.deepOrange,
  ];

  Color _getCatColor(String cat) {
    String lower = cat.toLowerCase();
    if (lower.contains("grocer")) return const Color(0xFF1DB98A);
    if (lower.contains("food")) return Colors.orange;
    if (lower.contains("digit")) return Colors.teal;
    if (lower.contains("utilit")) return Colors.orangeAccent;
    if (lower.contains("entertain")) return Colors.purple;
    if (lower.contains("fruit")) return Colors.redAccent;
    if (lower.contains("fashion")) return Colors.blueAccent;
    if (lower.contains("home")) return Colors.indigo;
    if (lower.contains("beauty")) return Colors.pinkAccent;
    if (lower.contains("toy")) return Colors.amber;
    return _fallbackPalette[cat.hashCode.abs() % _fallbackPalette.length];
  }

  IconData _getCatIcon(String cat) {
    String lower = cat.toLowerCase();
    if (lower.contains("grocer")) return Icons.shopping_basket_outlined;
    if (lower.contains("food") || lower.contains("restaur")) return Icons.restaurant;
    if (lower.contains("digit") || lower.contains("tech") || lower.contains("device")) return Icons.memory;
    if (lower.contains("utilit") || lower.contains("bill")) return Icons.bolt;
    if (lower.contains("entertain") || lower.contains("movie") || lower.contains("game")) return Icons.movie_outlined;
    if (lower.contains("fruit") || lower.contains("veg")) return Icons.restaurant_menu;
    if (lower.contains("fashion") || lower.contains("cloth")) return Icons.checkroom_outlined;
    if (lower.contains("home") || lower.contains("applian")) return Icons.kitchen_outlined;
    if (lower.contains("beauty") || lower.contains("health")) return Icons.health_and_safety_outlined;
    if (lower.contains("toy")) return Icons.smart_toy_outlined;
    return Icons.grid_view_rounded;
  }

  @override
  void initState() {
    super.initState();
    _loadAllData(); 
    _setupCategoryListener();
    _listenToTransactions();
    _listenToSettings();
  }

  void _listenToSettings() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _settingsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('budget')
        .doc('settings')
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            totalBudget = (data['budget_limit'] ?? 5000.0).toDouble();
            
            final String currentMonth = DateTime.now().month.toString();
            final String lastEditMonth = (data['last_edit_month'] ?? "").toString();

            if (currentMonth != lastEditMonth) {
              editsThisMonth = 0;
              firstBudgetOfMonth = 0.0;
            } else {
              editsThisMonth = data['edits_this_month'] ?? 0;
              firstBudgetOfMonth = (data['first_budget_of_month'] ?? 0.0).toDouble();
            }

            var savedSplits = data['split_percentages'] as Map<String, dynamic>? ?? {};
            if (savedSplits.isNotEmpty) {
               Map<String, double> tempSplits = {};
               savedSplits.forEach((key, value) => tempSplits[key] = (value as num).toDouble());
               splitPercentages = tempSplits;
            }
          });
        }
      }
    });
  }

  void _listenToTransactions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _transactionSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> allTrans = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        double price = (data['price'] ?? 0.0).toDouble();
        int qty = (data['quantity'] ?? 1) as int;
        double lineTotal = price * qty;
        
        String type = data['type'] ?? 'offline';
        String originalCat = (data['category'] ?? 'Miscellaneous').toString();
        String productName = data['productName'] ?? data['name'] ?? "Item";
        String cat = _normalizeCategory(originalCat, productName);
        DateTime txDate = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

        allTrans.add({
          'name': productName,
          'amount': lineTotal,
          'date': txDate,
          'category': cat,
          'type': type,
          'image': data['productImage'],
        });
      }

      if (mounted) {
        _allTransactions = allTrans;
        _recalculateStatistics();
      }
    });
  }

  List<Map<String, dynamic>> _allTransactions = [];

  void _recalculateStatistics() {
    final now = DateTime.now();
    double tempTotal = 0;
    double tempOnline = 0;
    double tempOffline = 0;
    Map<String, double> tempCatMap = {};
    List<Map<String, dynamic>> tempRecent = [];

    for (var tx in _allTransactions) {
      final DateTime date = tx['date'];
      bool inPeriod = false;

      if (selectedPeriod == "Week") {
        inPeriod = now.difference(date).inDays <= 7;
      } else if (selectedPeriod == "Month") {
        inPeriod = date.month == now.month && date.year == now.year;
      } else {
        inPeriod = date.year == now.year;
      }

      if (!inPeriod) continue;

      double amt = tx['amount'];
      tempTotal += amt;
      if (tx['type'] == 'online') tempOnline += amt;
      else tempOffline += amt;

      String cat = tx['category'];
      tempCatMap[cat] = (tempCatMap[cat] ?? 0.0) + amt;

      if (tempRecent.length < 5) {
        tempRecent.add(tx);
      }
    }

    if (mounted) {
      setState(() {
        totalSpent = tempTotal;
        onlineSpent = tempOnline;
        offlineSpent = tempOffline;
        categorySpending = tempCatMap;
        recentTransactions = tempRecent;
        isLoading = false;
      });
    }
  }

  void _setupCategoryListener() {
    _catSubscription = FirebaseFirestore.instance.collection('categories').snapshots().listen((_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _catSubscription?.cancel();
    _transactionSubscription?.cancel();
    _settingsSubscription?.cancel();
    _budgetController.dispose();
    for (var controller in _catControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _normalizeCategory(String? cat, String productName) {
    String c = (cat ?? "").toLowerCase();
    String n = productName.toLowerCase();
    
    if (c.contains('digital') || c.contains('digit')) return 'digital';
    if (c.contains('grocery') || c.contains('groc')) return 'grocery';
    if (c.contains('fruit')) return 'Fruits';
    if (c.contains('applian')) return 'home appliances';
    
    if (n.contains('tv') || n.contains('watch') || n.contains('vision') || 
        n.contains('intel') || n.contains('headphone') || n.contains('phone') || 
        n.contains('laptop')) return 'digital';
    
    if (n.contains('fridge') || n.contains('washing') || n.contains('microwave') || 
        n.contains('cooker') || n.contains('heater')) return 'home appliances';

    if (n.contains('apple') || n.contains('banana') || n.contains('mango') || 
        n.contains('piece')) return 'Fruits';

    if (cat != null && cat.isNotEmpty && cat != 'General' && cat != 'Others' && cat != 'Miscellaneous') {
      return cat;
    }
    
    return 'Miscellaneous';
  }

  Future<void> _loadAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!isLoading) setState(() => isLoading = true);

    try {
      final systemCatsSnapshot = await FirebaseFirestore.instance.collection('categories').get();
      final List<String> systemCategories = systemCatsSnapshot.docs.map((doc) => doc['name'] as String).toList();

      final budgetDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('budget').doc('settings')
          .get();

      if (budgetDoc.exists) {
        final data = budgetDoc.data();
        totalBudget = (data?['budget_limit'] ?? 5000.0).toDouble();
        
        final String currentMonth = DateTime.now().month.toString();
        final String lastEditMonth = (data?['last_edit_month'] ?? "").toString();

        if (currentMonth != lastEditMonth) {
          editsThisMonth = 0;
          firstBudgetOfMonth = 0.0;
        } else {
          editsThisMonth = data?['edits_this_month'] ?? 0;
          firstBudgetOfMonth = (data?['first_budget_of_month'] ?? 0.0).toDouble();
        }
        
        var savedSplits = data?['split_percentages'] as Map<String, dynamic>? ?? {};
        Map<String, double> mergedSplits = {};
        for (var cat in systemCategories) {
          mergedSplits[cat] = (savedSplits[cat] ?? 0.0).toDouble();
        }
        
        double currentTotal = mergedSplits.values.fold(0.0, (sum, v) => sum + v);
        if (currentTotal < 1.0 && systemCategories.isNotEmpty) {
          double defaultPercent = 100.0 / systemCategories.length;
          for (var cat in systemCategories) {
            mergedSplits[cat] = defaultPercent;
          }
        }
        splitPercentages = mergedSplits;
      }

      _catControllers.clear();
      for (var cat in splitPercentages.keys) {
        double amt = totalBudget * (splitPercentages[cat] ?? 0.0) / 100;
        _catControllers[cat] = TextEditingController(text: amt.toInt().toString());
      }
      
      _recalculateStatistics();
    } catch (e) {
      debugPrint("Error loading statistics: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateBudgetInFirestore(double newLimit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      Map<String, dynamic> updateData = {
        'budget_limit': newLimit,
        'split_percentages': splitPercentages,
        'last_edit_month': now.month.toString(),
        'edits_this_month': editsThisMonth + 1,
      };

      if (editsThisMonth == 0) {
        updateData['first_budget_of_month'] = newLimit;
      }

      await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('budget').doc('settings')
          .set(updateData, SetOptions(merge: true));
      
      _loadAllData(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _updateSplit(String changedCategory, double newValue, {bool updateControllers = true}) {
    setState(() {
      _lockedCategories.add(changedCategory);
      double oldValue = splitPercentages[changedCategory] ?? 0.0;
      double otherLockedSum = 0;
      for (var cat in splitPercentages.keys) {
        if (cat != changedCategory && _lockedCategories.contains(cat)) {
          otherLockedSum += splitPercentages[cat] ?? 0;
        }
      }

      newValue = newValue.clamp(0.0, 100.0 - otherLockedSum);
      double difference = newValue - oldValue;
      splitPercentages[changedCategory] = newValue;

      List<String> remaining = splitPercentages.keys
          .where((k) => k != changedCategory && !_lockedCategories.contains(k))
          .toList();
      
      if (remaining.isNotEmpty) {
        double perCategoryDiff = difference / remaining.length;
        for (var cat in remaining) {
          double currentVal = splitPercentages[cat] ?? 0.0;
          splitPercentages[cat] = (currentVal - perCategoryDiff).clamp(0.0, 100.0);
        }
      }

      if (updateControllers) {
        double currentTotalGoal = double.tryParse(_budgetController.text) ?? totalBudget;
        for (var cat in splitPercentages.keys) {
          double amt = currentTotalGoal * (splitPercentages[cat] ?? 0.0) / 100;
          _catControllers[cat]?.text = amt.toInt().toString();
        }
      }
    });
  }

  void _showAdvancedBudgetDialog() {
    if (editsThisMonth >= 2) {
      _showLimitAlert();
      return;
    }

    if (editsThisMonth == 1) {
      _budgetController.text = totalBudget.toInt().toString();
    } else {
      _budgetController.text = totalBudget.toInt().toString();
    }

    for (var cat in splitPercentages.keys) {
      double amt = (double.tryParse(_budgetController.text) ?? totalBudget) * (splitPercentages[cat] ?? 0.0) / 100;
      _catControllers[cat]?.text = amt.toInt().toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 5, width: 40, 
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5)),
              ),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Budget Control', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Plan your offline & online spending', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    IconButton(
                      icon: const CircleAvatar(backgroundColor: Color(0xFFF4F9F8), child: Icon(Icons.close, size: 20)),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF4F9F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text("Total Offline Monthly Spending Goal", style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _budgetController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                double? newTotal = double.tryParse(val);
                                if (newTotal != null && newTotal > 0) {
                                  if (editsThisMonth == 1) {
                                    double maxAllowed = firstBudgetOfMonth * 1.5;
                                    if (newTotal > maxAllowed) {
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Warning: Limit exceeded! Max allowed is ₹${maxAllowed.toInt()}"),
                                          backgroundColor: Colors.redAccent,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                  setModalState(() {
                                    for (var cat in splitPercentages.keys) {
                                      double amt = newTotal * (splitPercentages[cat] ?? 0.0) / 100;
                                      _catControllers[cat]?.text = amt.toInt().toString();
                                    }
                                  });
                                }
                              },
                              style: TextStyle(
                                fontSize: 32, 
                                fontWeight: FontWeight.bold, 
                                color: (editsThisMonth == 1 && (double.tryParse(_budgetController.text) ?? 0) > firstBudgetOfMonth * 1.5) 
                                    ? Colors.redAccent 
                                    : const Color(0xFF1DB98A)
                              ),
                              decoration: InputDecoration(
                                prefixText: "₹", 
                                border: InputBorder.none,
                                enabled: true,
                                hintText: editsThisMonth == 1 ? "Max ₹${(firstBudgetOfMonth * 1.5).toInt()}" : "",
                              ),
                            ),
                            if (editsThisMonth == 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Second edit can only increase up to 50% extra (Max: ₹${(firstBudgetOfMonth * 1.5).toInt()})",
                                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Row(
                        children: [
                          Icon(Icons.pie_chart_outline, size: 20, color: Colors.grey),
                          SizedBox(width: 10),
                          Text("Category Allocation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...splitPercentages.keys.map((cat) => _buildSplitRow(
                        name: cat, 
                        percent: splitPercentages[cat] ?? 0.0, 
                        onChanged: (val) {
                          setModalState(() => _updateSplit(cat, val));
                        }, 
                        setModalState: setModalState,
                      )),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25),
                child: ElevatedButton(
                  onPressed: () {
                    double? newValue = double.tryParse(_budgetController.text);
                    if (newValue == null || newValue <= 0) return;

                    if (editsThisMonth == 1) {
                      double maxAllowed = firstBudgetOfMonth * 1.5;
                      if (newValue > maxAllowed) {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 50),
                                      const SizedBox(height: 16),
                                      const Text("Limit Exceeded", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      Text(
                                        "You can increase the budget by only 50% of the first budget (Max: ₹${maxAllowed.toInt()}).",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            backgroundColor: const Color(0xFF1DB98A).withOpacity(0.8),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Got it", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                        return; // Block saving
                      }
                    }

                    _updateBudgetInFirestore(newValue);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB98A),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Lock My Budget", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitRow({
    required String name, 
    required double percent, 
    required ValueChanged<double> onChanged, 
    required StateSetter setModalState,
  }) {
    bool isLocked = _lockedCategories.contains(name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setModalState(() {
                    if (isLocked) _lockedCategories.remove(name);
                    else _lockedCategories.add(name);
                  });
                },
                icon: Icon(
                  isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: isLocked ? const Color(0xFF1DB98A) : Colors.grey[400],
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: _getCatColor(name).withOpacity(0.1), 
                child: Icon(_getCatIcon(name), color: _getCatColor(name), size: 20)
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                width: 90,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _catControllers[name],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: const InputDecoration(
                    prefixText: "₹",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) {
                    double? amt = double.tryParse(val);
                    double totalGoal = double.tryParse(_budgetController.text) ?? totalBudget;
                    if (amt != null && totalGoal > 0) {
                      double newPercent = (amt / totalGoal) * 100;
                      setModalState(() {
                        _updateSplit(name, newPercent.clamp(0.0, 100.0), updateControllers: false);
                        for (var otherCat in _catControllers.keys) {
                          if (otherCat != name) {
                            double otherAmt = totalGoal * (splitPercentages[otherCat] ?? 0.0) / 100;
                            _catControllers[otherCat]?.text = otherAmt.toInt().toString();
                          }
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 40,
                child: Text('${percent.toInt()}%', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold))
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF1DB98A),
              inactiveTrackColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
              thumbColor: Colors.white,
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: percent, 
              min: 0, 
              max: 100, 
              onChanged: (val) {
                onChanged(val);
                setModalState(() {});
              }
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingState();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          TwinMartTheme.bgBlob(
            top: -120,
            left: -100,
            size: 320,
            color: TwinMartTheme.brandGreen.withOpacity(0.2),
          ),
          TwinMartTheme.bgBlob(
            bottom: 150,
            right: -80,
            size: 300,
            color: TwinMartTheme.brandBlue.withOpacity(0.18),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadAllData,
                color: TwinMartTheme.brandGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 25),
                      _buildSpendingOverviewCard(),
                      const SizedBox(height: 30),
                      _buildTypeBreakdown(),
                      const SizedBox(height: 30),
                      _buildPeriodSelector(),
                      const SizedBox(height: 25),
                      _buildCategoryChartCard(),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history_rounded, size: 20, color: Color(0xFF1DB98A)),
                              SizedBox(width: 8),
                              Text("Recent Purchases", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (recentTransactions.isNotEmpty)
                            Text("${recentTransactions.length} items", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTransactionList(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TwinMartTheme.brandLogo(size: 24, context: context),
                const SizedBox(width: 10),
                TwinMartTheme.brandText(fontSize: 24, context: context),
              ],
            ),
            const SizedBox(height: 5),
            const Text('Smart budgeting for offline scans', 
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        _profileIcon()
      ],
    );
  }

  Widget _profileIcon() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
      builder: (context, snapshot) {
        String nameStr = "U";
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          try {
            final dataMap = snapshot.data!.data();
            if (dataMap is Map) {
              nameStr = dataMap['name'] ?? "U";
            }
          } catch (e) {
            nameStr = "U";
          }
        }
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                onBackToDashboard: widget.onBackToDashboard,
              ),
            ),
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF1DB98A),
            child: Text(nameStr.isNotEmpty ? nameStr[0].toUpperCase() : "U", 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildSpendingOverviewCard() {
    double progress = totalBudget > 0 ? (offlineSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    double remaining = totalBudget - offlineSpent;
    bool isOverBudget = offlineSpent > totalBudget;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${offlineSpent.toStringAsFixed(0)}', 
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isOverBudget ? Colors.redAccent : Theme.of(context).textTheme.bodyLarge?.color)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1DB98A).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(selectedPeriod == "Month" ? "Monthly Budget" : "Spending", style: const TextStyle(color: Color(0xFF1DB98A), fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Limit: ₹${totalBudget.toStringAsFixed(0)}', 
                  style: const TextStyle(color: Colors.grey)),
              Text(isOverBudget ? 'Exceeded!' : 'Available: ₹${remaining.toStringAsFixed(0)}', 
                  style: TextStyle(color: isOverBudget ? Colors.redAccent : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Stack(
            children: [
              Container(
                height: 12, width: double.infinity,
                decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(6)),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isOverBudget ? [Colors.redAccent, Colors.red] : [const Color(0xFF1DB98A), const Color(0xFF15A196)]),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: (isOverBudget ? Colors.red : const Color(0xFF1DB98A)).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[50], borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: editsThisMonth >= 2 ? Colors.redAccent : Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    editsThisMonth >= 2 
                      ? "Monthly edit limit reached (2/2)." 
                      : (editsThisMonth == 1 
                          ? "1 edit left. Max increase to ₹${(firstBudgetOfMonth * 1.5).toInt()} (150%)." 
                          : "2 edits remaining this month."),
                    style: TextStyle(fontSize: 11, color: editsThisMonth >= 2 ? Colors.redAccent : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _showAdvancedBudgetDialog,
              icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
              label: const Text("Manage My Spending Limit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C252E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBreakdown() {
    double exceededAmt = offlineSpent > totalBudget ? offlineSpent - totalBudget : 0.0;
    return Row(
      children: [
        Expanded(child: _typeCard("Online", onlineSpent, Icons.cloud_outlined, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _typeCard("Offline", offlineSpent, Icons.storefront_outlined, const Color(0xFF1DB98A))),
        const SizedBox(width: 12),
        Expanded(child: _typeCard("Exceeded", exceededAmt, Icons.info_outline_rounded, TwinMartTheme.brandBlue)),
      ],
    );
  }

  Widget _typeCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text("₹${amount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _periodItem("Week"),
          _periodItem("Month"),
          _periodItem("Year"),
        ],
      ),
    );
  }

  Widget _periodItem(String title) {
    bool isSelected = selectedPeriod == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedPeriod = title);
          _recalculateStatistics();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1DB98A) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1DB98A).withOpacity(0.3), blurRadius: 10)] : [],
          ),
          child: Center(
            child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 20)],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 140, width: 140,
            child: PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 35, sections: _buildChartSections())),
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${totalSpent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('Total Spent', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 15),
                ...(() {
                  final sortedEntries = categorySpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                  return sortedEntries.map((entry) {
                    final percent = totalSpent > 0 ? (entry.value / totalSpent * 100) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _getCatColor(entry.key), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                          Text('₹${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  });
                })(),
              ],
            ),
          )
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    if (categorySpending.isEmpty) return [PieChartSectionData(color: Colors.grey[300], value: 1, title: '', radius: 25)];
    return categorySpending.entries.map((entry) {
      return PieChartSectionData(color: _getCatColor(entry.key), value: entry.value, title: '', radius: 28, showTitle: false);
    }).toList();
  }

  Widget _buildTransactionList() {
    if (recentTransactions.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No transactions.")));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentTransactions.length,
      itemBuilder: (context, index) {
        final tx = recentTransactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                height: 54, width: 54,
                decoration: BoxDecoration(
                  color: _getCatColor(tx['category']).withOpacity(0.08), 
                  borderRadius: BorderRadius.circular(16),
                  image: tx['image'] != null && tx['image'].toString().isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(tx['image']),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: tx['image'] != null && tx['image'].toString().isNotEmpty
                  ? null
                  : Icon(_getCatIcon(tx['category']), color: _getCatColor(tx['category'])),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(tx['category'], style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Text('₹${tx['amount'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(height: 60, width: double.infinity, color: Colors.white),
              const SizedBox(height: 30),
              Container(height: 180, width: double.infinity, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  void _showLimitAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Limit Reached! 🛑"),
        content: const Text("You can only edit your budget twice per month. Please try again next month."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it"))],
      ),
    );
  }
}
