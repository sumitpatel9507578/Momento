import 'package:flutter/material.dart';
import 'package:momento/utils/image_filter_utils.dart';

class FilterStrip extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const FilterStrip({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ImageFilterUtils.availableFilters;

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filterSpec = filters[index];
          final filterName = filterSpec.name;
          final isSelected =
              selectedFilter.toLowerCase() == filterName.toLowerCase() ||
              (selectedFilter == 'B&W' && filterName == 'Black & White');

          final matrix = ImageFilterUtils.getMatrixByName(filterName);

          return GestureDetector(
            onTap: () => onFilterSelected(filterName),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? Colors.purpleAccent : Colors.white24,
                        width: isSelected ? 3 : 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: matrix != null
                          ? ColorFiltered(
                              colorFilter: ColorFilter.matrix(matrix),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF7E5F),
                                      Color(0xFFFEB47B),
                                      Color(0xFF86A8E7),
                                      Color(0xFF91EAE4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFF7E5F),
                                    Color(0xFFFEB47B),
                                    Color(0xFF86A8E7),
                                    Color(0xFF91EAE4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filterName,
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
