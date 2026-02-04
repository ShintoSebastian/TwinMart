import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  // 1. Added the callback parameter
  final VoidCallback onBackToDashboard; 

  // 2. Updated constructor to require this parameter
  const ScanScreen({super.key, required this.onBackToDashboard});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color twinGreen = Color(0xFF1DB98A);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- UPDATED HEADER SECTION WITH SAFE NAVIGATION ---
              Row(
                children: [
                  GestureDetector(
                    // 3. Changed Navigator.pop to widget.onBackToDashboard
                    onTap: widget.onBackToDashboard, 
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan & Shop', 
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)
                      ),
                      Text(
                        'Scan products to add them to your cart', 
                        style: TextStyle(color: Colors.grey, fontSize: 14)
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              
              // 2. LIVE CAMERA SCANNER BOX
              Container(
                height: 380,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C252E),
                  borderRadius: BorderRadius.circular(35),
                ),
                clipBehavior: Clip.hardEdge, 
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: cameraController,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          HapticFeedback.lightImpact(); 
                          debugPrint('Detected code: ${barcode.rawValue}');
                        }
                      },
                    ),
                    
                    // The Scanner Viewfinder Frame
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: twinGreen, width: 3),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),

                    // Floating Tool Buttons
                    Positioned(
                      bottom: 25,
                      child: Row(
                        children: [
                          _circleTool(
                            Icons.flashlight_on_outlined, 
                            false, 
                            onTap: () => cameraController.toggleTorch()
                          ),
                          const SizedBox(width: 20),
                          _circleTool(
                            Icons.camera_alt, 
                            true, 
                            onTap: () => cameraController.switchCamera()
                          ),
                          const SizedBox(width: 20),
                          _circleTool(Icons.grid_view_rounded, false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 3. INSTRUCTION BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hold your phone steady and center the barcode', 
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 4. BUDGET STATUS CARD
              _buildBudgetCard(twinGreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard(Color twinGreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: twinGreen, size: 28),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('₹1,520 left', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: twinGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              '24%', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleTool(IconData icon, bool isPrimary, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click, 
        child: Container(
          padding: EdgeInsets.all(isPrimary ? 16 : 12),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF1DB98A) : const Color(0xFF2D3843),
            shape: BoxShape.circle,
            boxShadow: isPrimary ? [
              BoxShadow(
                color: const Color(0xFF1DB98A).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ] : null,
          ),
          child: Icon(icon, color: Colors.white, size: isPrimary ? 28 : 22),
        ),
      ),
    );
  }
}