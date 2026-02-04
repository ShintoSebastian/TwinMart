import 'package:flutter/material.dart';

class BudgetScreen extends StatefulWidget {
  // 1. Added callback to notify MainWrapper to change the tab index
  final VoidCallback onBackToDashboard; 
  
  const BudgetScreen({super.key, required this.onBackToDashboard});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // --- STATE DATA ---
  double totalBudget = 5000.0;
  double originalMonthlyBudget = 5000.0; 
  double spent = 2890.0;
  int editsRemaining = 2; 
  
  final TextEditingController _budgetController = TextEditingController();

  double get remaining => totalBudget - spent;
  double get progressValue => (spent / totalBudget).clamp(0.0, 1.0);
  double get maxIncreaseAllowed => originalMonthlyBudget * 0.5; 

  Map<String, double> splitPercentages = {
    'Groceries': 35.0,
    'Food & Dining': 26.0,
    'Transport': 16.0,
    'Utilities': 11.0,
    'Entertainment': 11.0,
  };

  final Map<String, IconData> catIcons = {
    'Groceries': Icons.shopping_cart_outlined,
    'Food & Dining': Icons.restaurant, 
    'Transport': Icons.directions_car_filled_outlined,
    'Utilities': Icons.bolt,
    'Entertainment': Icons.coffee_rounded,
  };

  final Map<String, Color> catColors = {
    'Groceries': const Color(0xFF1DB98A),
    'Food & Dining': Colors.orange,
    'Transport': Colors.teal,
    'Utilities': Colors.orangeAccent,
    'Entertainment': const Color(0xFF1DB98A),
  };

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
      double oldValue = splitPercentages[changedCategory]!;
      double difference = newValue - oldValue;
      splitPercentages[changedCategory] = newValue;

      List<String> others = splitPercentages.keys.where((k) => k != changedCategory).toList();
      double perCategoryDiff = difference / others.length;

      for (var cat in others) {
        double currentVal = splitPercentages[cat]!;
        splitPercentages[cat] = (currentVal - perCategoryDiff).clamp(5.0, 100.0);
      }
    });
  }

  double get totalAllocated => splitPercentages.values.fold(0, (sum, item) => sum + item);

  @override
  Widget build(BuildContext context) {
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

  // --- HEADER UPDATED WITH BACK BUTTON ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBackToDashboard, // Swaps index to 0 in MainWrapper
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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _showBudgetSplitter,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey[100]!)),
                child: const Icon(Icons.bar_chart, color: Colors.black87), 
              ),
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
            GestureDetector(onTap: () {}, child: const Row(children: [Text("View All", style: TextStyle(color: Colors.grey, fontSize: 12)), Icon(Icons.chevron_right, color: Colors.grey, size: 16)]))
          ]),
          const SizedBox(height: 20),
          _spendingRow("Groceries", 0.6, const Color(0xFF1DB98A), Icons.shopping_cart_outlined, "₹1200 / ₹2000"),
          _spendingRow("Food & Dining", 0.59, Colors.orange, Icons.restaurant, "₹890 / ₹1500"),
          _spendingRow("Transport", 0.81, Colors.teal, Icons.directions_car_outlined, "₹650 / ₹800"),
          _spendingRow("Utilities", 0.96, Colors.deepOrange, Icons.bolt, "₹480 / ₹500"),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _transactionItem("Fresh Milk 1L", "Today", "-₹65", "🥛"),
          _transactionItem("Organic Apples 1kg", "Today", "-₹180", "🍎"),
          _transactionItem("Whole Wheat Bread", "Yesterday", "-₹45", "🍞"),
          _transactionItem("Greek Yogurt", "Yesterday", "-₹89", "🥛"),
        ],
      ),
    );
  }

  Widget _transactionItem(String title, String date, String price, String emoji) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: const Color(0xFFF4F9F8), child: Text(emoji)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(date),
      trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      ...splitPercentages.keys.map((cat) => _buildSplitRow(cat, splitPercentages[cat]!, (val) {
                        setModalState(() => _updateSplit(cat, val));
                      })).toList(),
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
              CircleAvatar(backgroundColor: catColors[name]!.withOpacity(0.1), child: Icon(catIcons[name], color: catColors[name], size: 20)),
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
    bool isOver = totalAllocated > 100;
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
            children: splitPercentages.keys.map((cat) => _allocationSegment(splitPercentages[cat]! / 100, catColors[cat]!)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _allocationSegment(double weight, Color color) {
    return Expanded(
      flex: (weight * 100).toInt(),
      child: Container(
        height: 10,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}