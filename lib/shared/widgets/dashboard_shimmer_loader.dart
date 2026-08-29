import 'package:flutter/material.dart';

class DashboardShimmerLoader extends StatefulWidget {
  const DashboardShimmerLoader({super.key});

  @override
  State<DashboardShimmerLoader> createState() => _DashboardShimmerLoaderState();
}

class _DashboardShimmerLoaderState extends State<DashboardShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shimmerAnim = Tween<double>(begin: 0.25, end: 0.75).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        final opacity = _shimmerAnim.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Card Skeleton (Vehículo + Placa + Kilometraje)
              Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: baseColor.withValues(alpha: isDark ? opacity * 0.12 : opacity * 0.06),
                  border: Border.all(
                    color: baseColor.withValues(alpha: isDark ? 0.08 : 0.04),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120,
                            height: 22,
                            decoration: BoxDecoration(
                              color: baseColor.withValues(alpha: opacity * 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Container(
                            width: 70,
                            height: 28,
                            decoration: BoxDecoration(
                              color: baseColor.withValues(alpha: opacity * 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: Icon(
                          Icons.directions_car_rounded,
                          size: 70,
                          color: baseColor.withValues(alpha: opacity * 0.15),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 90,
                            height: 16,
                            decoration: BoxDecoration(
                              color: baseColor.withValues(alpha: opacity * 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Container(
                            width: 110,
                            height: 16,
                            decoration: BoxDecoration(
                              color: baseColor.withValues(alpha: opacity * 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // 2. Indicadores Circulares de Salud Skeleton
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: baseColor.withValues(alpha: isDark ? 0.04 : 0.02),
                  border: Border.all(color: baseColor.withValues(alpha: isDark ? 0.06 : 0.03)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: opacity * 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        4,
                        (index) => Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: baseColor.withValues(alpha: opacity * 0.12),
                                border: Border.all(
                                  color: baseColor.withValues(alpha: opacity * 0.25),
                                  width: 3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 44,
                              height: 10,
                              decoration: BoxDecoration(
                                color: baseColor.withValues(alpha: opacity * 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 3. Grid de Documentos Skeleton
              Row(
                children: List.generate(
                  2,
                  (index) => Expanded(
                    child: Container(
                      height: 110,
                      margin: EdgeInsets.only(
                        left: index == 1 ? 8 : 0,
                        right: index == 0 ? 8 : 0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: baseColor.withValues(alpha: isDark ? opacity * 0.08 : opacity * 0.04),
                        border: Border.all(color: baseColor.withValues(alpha: isDark ? 0.06 : 0.03)),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Barra de Acciones Skeleton
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: baseColor.withValues(alpha: isDark ? opacity * 0.09 : opacity * 0.04),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
