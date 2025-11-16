import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_entity.dart';

class MonthlyChart extends StatelessWidget {
  final List<MonthlyData> monthlyData;

  const MonthlyChart({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('داده‌ای برای نمایش وجود ندارد'),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'درآمد ماهانه (تومان)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: monthlyData.length,
                itemBuilder: (context, index) {
                  final data = monthlyData[index];
                  final maxRevenue = monthlyData
                      .map((e) => e.revenue)
                      .reduce((a, b) => a > b ? a : b);
                  
                  // Handle zero or NaN values
                  double height = 20; // minimum height
                  if (maxRevenue > 0 && data.revenue > 0) {
                    height = (data.revenue / maxRevenue) * 150;
                    if (height < 20) height = 20; // ensure minimum visibility
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          data.revenue == 0 
                              ? '0' 
                              : '${(data.revenue / 1000000).toStringAsFixed(1)}M',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 40,
                          height: height,
                          decoration: BoxDecoration(
                            color: data.revenue == 0 
                                ? Colors.grey.shade300
                                : Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.month,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
