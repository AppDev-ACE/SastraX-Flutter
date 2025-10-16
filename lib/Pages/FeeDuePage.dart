import 'package:flutter/material.dart';

class FeeDueStatusPage extends StatelessWidget {
  const FeeDueStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. App Bar
      appBar: AppBar(
        title: const Text('Fee Due Status'),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: const Icon(Icons.arrow_back) , color: Colors.black),
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      // 2. Main Body Content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Total Amount Due Card ---
            _buildTotalDueCard(),
            const SizedBox(height: 32.0),

            // --- Due Details Section ---
            const Text(
              'Due Details',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),

            // --- Individual Fee Items ---
            _buildDueItemCard(
              title: 'Tuition Fee 2025',
              dueDate: 'Due: May 15, 2025',
              amount: 'Rs. 85,000.00',
              barColor: Colors.deepPurple,
            ),
            const SizedBox(height: 12.0),

            _buildDueItemCard(
              title: 'Library Fine',
              dueDate: 'Due: April 30, 2023',
              amount: 'Rs. 250.00',
              barColor: Colors.red,
              amountColor: Colors.red, // Highlight overdue fine in red
            ),
            const SizedBox(height: 12.0),

            _buildDueItemCard(
              title: 'Lab Charges',
              dueDate: 'Due: June 5, 2023',
              amount: 'Rs. 375.00',
              barColor: Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main purple card showing the total amount due.
  Widget _buildTotalDueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Total Amount Due',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Rs. 85,625.00',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () {
              // TODO: Add payment logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: const Text(
              'Pay Now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a reusable card widget for each due item.
  Widget _buildDueItemCard({
    required String title,
    required String dueDate,
    required String amount,
    required Color barColor,
    Color amountColor = Colors.black87,
  }) {
    return Card(
      elevation: 2.0,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Colored vertical indicator bar
            Container(
              width: 5.0,
              height: 40.0, // Set a fixed height for the bar
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            const SizedBox(width: 16.0),
            // Title and due date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    dueDate,
                    style: TextStyle(
                      fontSize: 13.0,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              amount,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}