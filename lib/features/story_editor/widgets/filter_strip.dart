import 'package:flutter/material.dart';

class FilterStrip extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const FilterStrip({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  static const filters = [
    'Normal',
    'Vivid',
    'Warm',
    'Cool',
    'B&W',
    'Vintage',
    'Fade',
    'Drama',
    'Noir',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.purple : Colors.white24,
                        width: isSelected ? 3 : 1.5,
                      ),
                      color: Colors.grey[850],
                    ),
                    child: Center(
                      child: Text(
                        filter.substring(0, 1),
                        style: TextStyle(
                          color: isSelected ? Colors.purpleAccent : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.purpleAccent : Colors.white70,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
