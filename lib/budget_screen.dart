import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';    
import 'dart:async'; 

class BudgetScreen extends StatefulWidget {
  final VoidCallback onBackToDashboard; 
  
  const BudgetScreen({super.key, required this.onBackToDashboard});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // --- STATE DATA ---
  double totalBudget = 5000.0;
  double originalMonthlyBudget = 5000.0; 
  double spent = 0.0; 
  int editsRemaining = 2; 
  bool isLoading = true; 
  
  Map<String, double> categorySpentMap = {};

  final TextEditingController _budgetController = TextEditingController();

  double get remaining => totalBudget - spent;
  double get progressValue => totalBudget > 0 ? (spent / totalBudget).clamp(0.0, 1.0) : 0.0;
  double get maxIncreaseAllowed => originalMonthlyBudget * 0.5; 

  Map<String, double> splitPercentages = {
    'Groceries': 35.0,
    'Food & Dining': 26.0,
    'Digitals': 16.0, 
    'Utilities': 11.0,
    'Entertainment': 11.0,
  };

  final Map<String, IconData> catIcons = {
    'Groceries': Icons.shopping_cart_outlined,
    'Food & Dining': Icons.restaurant, 
    'Digitals': Icons.devices_other, 
    'Utilities': Icons.bolt,
    'Entertainment': Icons.coffee_rounded,
  };

  final Map<String, Color> catColors = {
    'Groceries': const Color(0xFF1DB98A),
    'Food & Dining': Colors.orange,
    'Digitals': Colors.teal, 
    'Utilities': Colors.orangeAccent,
    'Entertainment': const Color(0xFF1DB98A),
  };

  @override
  void initState() {
    super.initState();
    _loadBudgetData(); 
  }

  Future<void> _loadBudgetData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('budget')
        .doc('settings');

    try {
      final doc = await docRef.get().timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        await docRef.set({
          'budget_limit': 5000.0,
          'category_spending': {
            'Digitals': 0.0,
            'Food & Dining': 0.0,
            'Groceries': 0.0,
            'Utilities': 0.0,
            'Entertainment': 0.0,
          },
          'split_percentages': splitPercentages,
        }).timeout(const Duration(seconds: 10));
      }

      final freshDoc = await docRef.get().timeout(const Duration(seconds: 10));
      final data = freshDoc.data(); // This is Map<String, dynamic>?

      if (mounted && data != null) {
        setState(() {
          totalBudget = (data['budget_limit'] ?? 5000.0).toDouble();
          originalMonthlyBudget = totalBudget;
          
          // Fixed potential null access with safe casting
          var cats = data['category_spending'] as Map<String, dynamic>? ?? {};
          categorySpentMap = cats.map((key, value) => MapEntry(key, (value ?? 0.0).toDouble()));
          spent = categorySpentMap.values.fold(0.0, (sum, v) => sum + v);

          // Fixed potential null access with safe casting
          var savedSplits = data['split_percentages'] as Map<String, dynamic>?;
          if (savedSplits != null) {
            splitPercentages = savedSplits.map((key, value) => MapEntry(key, (value ?? 0.0).toDouble()));
          }
          
          isLoading = false; 
        });
      } else if (mounted) {
        setState(() => isLoading = false);
      }
    } on TimeoutException catch (_) {
      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Error loading budget: $e");
      if (mounted) setState(() => isLoading = false); 
    }
  }

  Future<void> _updateBudgetInFirestore(double newLimit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users').doc(user.uid)
        .collection('budget').doc('settings')
        .update({'budget_limit': newLimit}).timeout(const Duration(seconds: 10));
    
    _loadBudgetData(); 
  }

  Future<void> _syncSplitsToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('budget').doc('settings')
          .update({'split_percentages': splitPercentages}).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Error syncing splits: $e");
    }
  }

  void _showEditBudgetDialog() {
    if (editsRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No budget edits remaining for this month.")),
      );
      return;
    }

    _budgetController.text = totalBudget.toInt().toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Budget ($editsRemaining left)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: '₹ ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Text(
              "Note: Max increase allowed is ₹${maxIncreaseAllowed.toInt()} (50%)",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              double? newValue = double.tryParse(_budgetController.text);
              if (newValue == null) return;

              if (newValue > (originalMonthlyBudget + maxIncreaseAllowed)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Cannot exceed ₹${(originalMonthlyBudget + maxIncreaseAllowed).toInt()} (+50%)")),
                );
                return;
              }

              _updateBudgetInFirestore(newValue);
              setState(() {
                totalBudget = newValue;
                editsRemaining--; 
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB98A)),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateSplit(String changedCategory, double newValue) {
    setState(() {
      double oldValue = splitPercentages[changedCategory] ?? 0.0;
      double difference = newValue - oldValue;
      splitPercentages[changedCategory] = newValue;

      List<String> others = splitPercentages.keys.where((k) => k != changedCategory).toList();
      if (others.isNotEmpty) {
        double perCategoryDiff = difference / others.length;
        for (var cat in others) {
          double currentVal = splitPercentages[cat] ?? 0.0;
          splitPercentages[cat] = (currentVal - perCategoryDiff).clamp(0.0, 100.0);
        }
      }
    });
    _syncSplitsToFirestore();
  }

  double get totalAllocated => splitPercentages.values.fold(0, (sum, item) => sum + item);

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF1DB98A)),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildGradientCard(), 
              _buildStatGrid(),
              _buildCategorySpending(),
              _buildRecentTransactions(),
              _buildSmartTips(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBackToDashboard, 
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Text('January 2026', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showBudgetSplitter,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey[100]!)),
              child: const Icon(Icons.bar_chart, color: Colors.black87), 
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB98A), Color(0xFF15A196), Color(0xFF0E8A81)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFF1DB98A).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(backgroundColor: Colors.white24, radius: 28, child: Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28)),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monthly Budget', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Row(
                        children: [
                          Text('₹${totalBudget.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showEditBudgetDialog,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: editsRemaining > 0 ? Colors.white24 : Colors.white10,
                              child: Icon(Icons.edit_outlined, color: editsRemaining > 0 ? Colors.white : Colors.white38, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Remaining', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('₹${remaining.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Stack(
            children: [
              Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              FractionallySizedBox(
                widthFactor: progressValue,
                child: Container(height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${spent.toInt()} spent', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text('${(progressValue * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white60, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Max increase allowed: ₹${maxIncreaseAllowed.toInt()} (50%) • $editsRemaining edits left',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statCard("This Week", "₹1,450", "+12%", const Color(0xFF1DB98A), Icons.trending_up),
          _statCard("Saved", "₹890", "+25%", const Color(0xFF15A196), Icons.savings),
          _statCard("Daily Avg", "₹190", "-8%", Colors.orange, Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _statCard(String label, String val, String trend, Color color, IconData icon) {
    return Container(
      width: 108, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 12),
        Text(trend, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildCategorySpending() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Category Spending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16)
          ]),
          const SizedBox(height: 20),
          ...splitPercentages.keys.map((catName) {
            double percent = splitPercentages[catName] ?? 0.0;
            double limit = (totalBudget * percent) / 100;
            double currentSpent = categorySpentMap[catName] ?? 0.0;
            double prog = limit > 0 ? (currentSpent / limit).clamp(0.0, 1.0) : 0.0;

            return _spendingRow(
              catName, 
              prog, 
              catColors[catName] ?? Colors.teal, 
              catIcons[catName] ?? Icons.help_outline, 
              "₹${currentSpent.toInt()} / ₹${limit.toInt()}"
            );
          }),
        ],
      ),
    );
  }

  Widget _spendingRow(String name, double prog, Color color, IconData icon, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(children: [
        Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 12), Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Text(amount, style: const TextStyle(color: Colors.grey, fontSize: 11))]),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: prog, minHeight: 6, backgroundColor: Colors.grey[100], valueColor: AlwaysStoppedAnimation<Color>(color)),
      ]),
    );
  }

  Widget _buildRecentTransactions() {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users').doc(user?.uid).collection('transactions')
                .orderBy('timestamp', descending: true).limit(5).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text("No scans yet.");
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: Color(0xFFF4F9F8), child: Icon(Icons.shopping_bag_outlined)),
                    title: Text(data['productName'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['category'] ?? 'Offline Scan'),
                    trailing: Text("-₹${data['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Smart Tips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _tipContainer("Buy seasonal fruits to save up to 30%"),
              _tipContainer("Check weekly deals before shopping"),
              _tipContainer("Compare prices using the scanner"),
            ],
          ),
        )
      ],
    );
  }

  Widget _tipContainer(String text) {
    return Container(
      width: 240, margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFCFF2EB).withOpacity(0.35), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFCFF2EB))),
      child: Row(children: [const Icon(Icons.check_circle_outline, color: Color(0xFF1DB98A), size: 18), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)))]),
    );
  }

  void _showBudgetSplitter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FractionallySizedBox(
          heightFactor: 0.85, 
          child: Column(
            children: [
              _buildModalHeader(context),
              Expanded(
                child: SingleChildScrollView( 
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      ...splitPercentages.keys.map((cat) => _buildSplitRow(cat, splitPercentages[cat] ?? 0.0, (val) {
                        setModalState(() => _updateSplit(cat, val));
                      })),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildAllocationSummary(), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Budget Splitter', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Allocate your ₹${totalBudget.toInt()} budget', style: const TextStyle(color: Colors.grey)),
          ]),
          IconButton(
            icon: CircleAvatar(backgroundColor: Colors.grey[100], child: const Icon(Icons.close, color: Colors.black, size: 20)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitRow(String name, double percent, ValueChanged<double> onChanged) {
    double amount = (totalBudget * percent) / 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: (catColors[name] ?? Colors.teal).withOpacity(0.1), child: Icon(catIcons[name] ?? Icons.help, color: catColors[name] ?? Colors.teal, size: 20)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('₹${amount.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ),
              Text('${percent.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF1DB98A),
              inactiveTrackColor: Colors.grey[100],
              thumbColor: Colors.white,
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
            ),
            child: Slider(value: percent, min: 0, max: 100, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationSummary() {
    bool isOver = totalAllocated > 100.1; 
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 15, 25, 40),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Allocation', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              Text('${totalAllocated.toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isOver ? Colors.red : Colors.black)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: splitPercentages.keys.map((cat) {
              int flexValue = ((splitPercentages[cat] ?? 0.0) * 10).toInt().clamp(1, 1000);
              return Expanded(
                flex: flexValue,
                child: Container(
                  height: 10,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(color: catColors[cat] ?? Colors.teal, borderRadius: BorderRadius.circular(5)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}