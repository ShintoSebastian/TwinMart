import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:twinmart_app/theme/twinmart_theme.dart';
import 'dart:ui' as ui;

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
  double originalMonthlyBudget = 5000.0;
  double totalSpent = 0.0;
  double onlineSpent = 0.0;
  double offlineSpent = 0.0;

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

  final Map<String, Color> catColors = {
    'Groceries': const Color(0xFF1DB98A),
    'Electronics': Colors.blue,
    'Clothing': Colors.orange,
    'Digitals': Colors.teal,
    'Food & Dining': Colors.redAccent,
    'Others': Colors.grey,
  };

  final Map<String, IconData> catIcons = {
    'Groceries': Icons.shopping_basket_outlined,
    'Electronics': Icons.devices_other,
    'Clothing': Icons.checkroom_outlined,
    'Digitals': Icons.phone_android_outlined,
    'Food & Dining': Icons.restaurant_menu_outlined,
    'Others': Icons.grid_view_rounded,
  };

  @override
  void initState() {
    super.initState();
    for (var cat in splitPercentages.keys) {
      _catControllers[cat] = TextEditingController();
    }
    _loadAllData();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    for (var controller in _catControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!isLoading) setState(() => isLoading = true);

    try {
      // 1. Load Budget Settings
      final budgetDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('budget')
          .doc('settings')
          .get();

      if (budgetDoc.exists) {
        final data = budgetDoc.data();
        totalBudget = (data?['budget_limit'] ?? 5000.0).toDouble();
        originalMonthlyBudget = totalBudget;
        
        var savedSplits = data?['split_percentages'] as Map<String, dynamic>?;
        if (savedSplits != null) {
          splitPercentages = savedSplits.map((key, value) => MapEntry(key, (value ?? 0.0).toDouble()));
        }
      }

      // Sync controllers after load
      for (var cat in splitPercentages.keys) {
        double amt = totalBudget * (splitPercentages[cat] ?? 0.0) / 100;
        _catControllers[cat]?.text = amt.toInt().toString();
      }

      // 2. Load Transactions (individual items)
      final transSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();

      double tempTotal = 0;
      double tempOnline = 0;
      double tempOffline = 0;
      Map<String, double> tempCatMap = {};
      List<Map<String, dynamic>> tempRecent = [];

      for (var doc in transSnapshot.docs) {
        final data = doc.data();
        double price = (data['price'] ?? 0.0).toDouble();
        String type = data['type'] ?? 'offline';
        String cat = data['category'] ?? 'Others';

        tempTotal += price;
        if (type == 'online') tempOnline += price;
        else tempOffline += price;

        tempCatMap[cat] = (tempCatMap[cat] ?? 0.0) + price;

        if (tempRecent.length < 5) {
          tempRecent.add({
            'name': data['productName'] ?? 'Item',
            'amount': price,
            'date': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'category': cat,
            'type': type,
          });
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
    } catch (e) {
      debugPrint("Error loading statistics: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateBudgetInFirestore(double newLimit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('budget').doc('settings')
          .set({
            'budget_limit': newLimit,
            'split_percentages': splitPercentages,
          }, SetOptions(merge: true));
      
      _loadAllData(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _updateSplit(String changedCategory, double newValue, {bool updateControllers = true}) {
    setState(() {
      // Automatically "Fix" this category once the user interacts with it
      _lockedCategories.add(changedCategory);

      double oldValue = splitPercentages[changedCategory] ?? 0.0;
      
      // Calculate total percentage already "Fixed" by OTHER categories
      double otherLockedSum = 0;
      for (var cat in splitPercentages.keys) {
        if (cat != changedCategory && _lockedCategories.contains(cat)) {
          otherLockedSum += splitPercentages[cat] ?? 0;
        }
      }

      // 1. Clamp newValue so it doesn't exceed the available "un-fixed" space
      newValue = newValue.clamp(0.0, 100.0 - otherLockedSum);
      double difference = newValue - oldValue;
      splitPercentages[changedCategory] = newValue;

      // 2. Identify "Remaining" categories that can be rearranged (not locked, not the one we just changed)
      List<String> remaining = splitPercentages.keys
          .where((k) => k != changedCategory && !_lockedCategories.contains(k))
          .toList();
      
      if (remaining.isNotEmpty) {
        // Redistribute the difference among the remaining un-fixed categories
        double perCategoryDiff = difference / remaining.length;
        for (var cat in remaining) {
          double currentVal = splitPercentages[cat] ?? 0.0;
          splitPercentages[cat] = (currentVal - perCategoryDiff).clamp(0.0, 100.0);
        }
      } else {
        // Edge case: If everything else is fixed, we can't redistribute.
        // In a premium UX, we'd maybe force-unlock the most recent lock, 
        // but for now we clamp the newValue (done above) to maintain 100%.
      }

      // Sync the text input fields
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
    _budgetController.text = totalBudget.toInt().toString();
    // Refresh controllers based on current budget
    for (var cat in splitPercentages.keys) {
      double amt = totalBudget * (splitPercentages[cat] ?? 0.0) / 100;
      _catControllers[cat]?.text = amt.toInt().toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
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
                        decoration: BoxDecoration(color: const Color(0xFFF4F9F8), borderRadius: BorderRadius.circular(20)),
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
                                  setModalState(() {
                                    for (var cat in splitPercentages.keys) {
                                      double amt = newTotal * (splitPercentages[cat] ?? 0.0) / 100;
                                      _catControllers[cat]?.text = amt.toInt().toString();
                                    }
                                  });
                                }
                              },
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1DB98A)),
                              decoration: const InputDecoration(prefixText: "₹", border: InputBorder.none),
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
                    if (newValue != null) {
                      _updateBudgetInFirestore(newValue);
                      Navigator.pop(context);
                    }
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
                backgroundColor: (catColors[name] ?? Colors.teal).withOpacity(0.1), 
                child: Icon(catIcons[name] ?? Icons.help, color: catColors[name] ?? Colors.teal, size: 20)
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
                  color: Colors.grey[100],
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
              inactiveTrackColor: Colors.grey[100],
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
      backgroundColor: TwinMartTheme.bgLight,
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
                      const Text("Category Breakdown", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                TwinMartTheme.brandLogo(size: 24),
                const SizedBox(width: 10),
                TwinMartTheme.brandText(fontSize: 24),
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
        return CircleAvatar(
          backgroundColor: const Color(0xFF1DB98A),
          child: Text(nameStr.isNotEmpty ? nameStr[0].toUpperCase() : "U", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${offlineSpent.toStringAsFixed(0)}', 
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isOverBudget ? Colors.redAccent : Colors.black)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1DB98A).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text("Offline Budget", style: TextStyle(color: Color(0xFF1DB98A), fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Limit: ₹${totalBudget.toStringAsFixed(0)}', 
                  style: const TextStyle(color: Colors.grey)),
              Text(isOverBudget ? 'Budget Exceeded!' : 'Available: ₹${remaining.toStringAsFixed(0)}', 
                  style: TextStyle(color: isOverBudget ? Colors.redAccent : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOverBudget 
                        ? [Colors.redAccent, Colors.red] 
                        : [const Color(0xFF1DB98A), const Color(0xFF15A196)]
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: (isOverBudget ? Colors.red : const Color(0xFF1DB98A)).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4)
                      )
                    ]
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
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
    return Row(
      children: [
        Expanded(
          child: _typeCard("Online", onlineSpent, Icons.cloud_outlined, Colors.blue),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _typeCard("Offline", offlineSpent, Icons.storefront_outlined, const Color(0xFF1DB98A)),
        ),
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
          Text("₹${amount.toStringAsFixed(0)}", 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
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
        onTap: () => setState(() => selectedPeriod = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1DB98A) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1DB98A).withOpacity(0.3), blurRadius: 10)] : [],
          ),
          child: Center(
            child: Text(title, 
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey, 
                  fontWeight: FontWeight.bold
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 150,
            width: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: _buildChartSections(),
              ),
            ),
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${totalSpent.toStringAsFixed(0)}', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('Total Spent', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 15),
                ...categorySpending.keys.take(4).map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: catColors[cat] ?? Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(cat, style: const TextStyle(fontSize: 12))),
                        Text('₹${categorySpending[cat]!.toStringAsFixed(0)}', 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          )
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    if (categorySpending.isEmpty) {
      return [PieChartSectionData(color: Colors.grey[300], value: 1, title: '', radius: 25)];
    }
    return categorySpending.entries.map((entry) {
      return PieChartSectionData(
        color: catColors[entry.key] ?? Colors.grey,
        value: entry.value,
        title: '',
        radius: 25,
      );
    }).toList();
  }

  Widget _buildTransactionList() {
    if (recentTransactions.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: Text("No transactions recorded."),
      ));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentTransactions.length,
      itemBuilder: (context, index) {
        final tx = recentTransactions[index];
        final name = tx['name']?.toString() ?? 'Item';
        final amount = (tx['amount'] ?? 0.0).toDouble();
        final date = tx['date'] is DateTime ? tx['date'] as DateTime : DateTime.now();
        final type = tx['type']?.toString() ?? 'offline';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text("image", style: TextStyle(color: Colors.grey, fontSize: 10))),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('MMM dd, yyyy').format(date), 
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${amount.toStringAsFixed(0)}', 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Icon(
                    type == 'online' ? Icons.cloud_outlined : Icons.storefront_outlined,
                    size: 14, color: Colors.grey,
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(height: 60, width: double.infinity, color: Colors.white),
              const SizedBox(height: 30),
              Container(height: 180, width: double.infinity, color: Colors.white),
              const SizedBox(height: 30),
              Container(height: 150, width: double.infinity, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
