import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/verification_controller.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/glass_container.dart';

class VerificationEligibilityScreen extends StatelessWidget {
  const VerificationEligibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerificationController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Eligibility Check',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.eligibility.value == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.purple));
        }

        final elig = controller.eligibility.value;
        if (elig == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load eligibility details', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => controller.loadEligibilityAndStatus(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(18),
                child: Row(
                  children: [
                    Icon(
                      elig.isEligible ? Icons.verified_rounded : Icons.pending_actions_rounded,
                      color: elig.isEligible ? Colors.greenAccent : Colors.orangeAccent,
                      size: 36,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            elig.isEligible ? 'Account Meets Standard Criteria' : 'Requirements Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            elig.isEligible
                                ? 'Your account satisfies standard verification criteria. You can proceed with the application.'
                                : 'Some requirements are not yet satisfied.',
                            style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Requirement Breakdown',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 12),

              _buildRequirementCard(
                title: '5,000+ Followers',
                subtitle: 'Current: ${elig.followersCount} Followers (Required: ${elig.minFollowersRequired})',
                isSatisfied: elig.isFollowersEligible,
              ),
              const SizedBox(height: 10),

              _buildRequirementCard(
                title: '90+ Days Account Age',
                subtitle: 'Current: ${elig.accountAgeDays} Days (Required: ${elig.minAccountAgeDaysRequired})',
                isSatisfied: elig.isAgeEligible,
              ),
              const SizedBox(height: 10),

              _buildRequirementCard(
                title: 'Complete Profile Details',
                subtitle: 'Name, Username, Bio, and Profile Picture completed',
                isSatisfied: elig.isProfileComplete,
              ),
              const SizedBox(height: 10),

              _buildRequirementCard(
                title: 'Account Standing',
                subtitle: 'Active account with no critical policy infractions',
                isSatisfied: elig.hasActiveStanding,
              ),

              if (elig.missingRequirements.isNotEmpty) ...[
                const SizedBox(height: 20),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Missing Requirements',
                            style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...elig.missingRequirements.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('• $r', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed('/verification-form');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: Text(
                    elig.isEligible ? 'Proceed to Application' : 'Request Exception Review',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRequirementCard({
    required String title,
    required String subtitle,
    required bool isSatisfied,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isSatisfied ? Colors.greenAccent : Colors.redAccent,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isSatisfied ? Colors.green : Colors.red).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isSatisfied ? Colors.green : Colors.red).withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              isSatisfied ? 'Eligible' : 'Incomplete',
              style: TextStyle(
                color: isSatisfied ? Colors.greenAccent : Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
