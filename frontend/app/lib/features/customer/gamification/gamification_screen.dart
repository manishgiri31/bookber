import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Achievements'),
        bottom: TabBar(
          controller: _tab,
          labelColor: colors.text,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: BBColors.amber,
          tabs: const [
            Tab(text: 'Badges'),
            Tab(text: 'Challenges'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _BadgesTab(),
          _ChallengesTab(),
          _LeaderboardTab(),
        ],
      ),
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────

const _badges = [
  (AppIcons.starFill, 'First Booking', 'Made your first booking', true, BBColors.amber),
  (AppIcons.repeat, 'Regular', 'Booked 5+ times', true, BBColors.success),
  (AppIcons.timer, 'On Time', 'No no-shows in 10 bookings', true, BBColors.info),
  (AppIcons.people, 'Social', 'Referred 3 friends', false, BBColors.amber),
  (AppIcons.loyalty, 'Gold Member', 'Reached Gold tier', false, Color(0xFFFFD700)),
  (AppIcons.fire, '7-Day Streak', '7 consecutive booking weeks', false, BBColors.error),
  (AppIcons.premium, 'VIP', 'Reached Platinum tier', false, Color(0xFFE5E4E2)),
  (AppIcons.diamond, 'Diamond', 'Reached Diamond tier', false, Color(0xFF67E8F9)),
];

class _BadgesTab extends StatelessWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return ListView(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      children: [
        // ── Current level ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(BBSpacing.base),
          decoration: BoxDecoration(
            color: BBColors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(BBRadius.xl),
            border: Border.all(
                color: BBColors.amber.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: BBColors.amber,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'Lv 3',
                    style: BBTypography.textTheme.titleMedium?.copyWith(
                      color: colors.background,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: BBSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Regular Customer',
                      style: BBTypography.textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: colors.border,
                      valueColor:
                          const AlwaysStoppedAnimation(BBColors.amber),
                      borderRadius:
                          BorderRadius.circular(BBRadius.full),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '650 / 1000 XP to Level 4',
                      style: BBTypography.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BBSpacing.xl),

        // ── Streak ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: BBSpacing.base, vertical: BBSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.fire,
                  color: BBColors.error, size: 28),
              const SizedBox(width: BBSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak',
                      style: BBTypography.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      '3 weeks in a row',
                      style: BBTypography.textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '🔥 3',
                style: BBTypography.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BBSpacing.xl),

        // ── Badges grid ─────────────────────────────────────────────────
        Text(
          'EARNED BADGES',
          style: BBTypography.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: BBSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: BBSpacing.sm,
            mainAxisSpacing: BBSpacing.sm,
            childAspectRatio: 0.8,
          ),
          itemCount: _badges.length,
          itemBuilder: (ctx, i) {
            final b = _badges[i];
            return Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: b.$4
                        ? b.$5.withValues(alpha: 0.12)
                        : colors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: b.$4
                          ? b.$5.withValues(alpha: 0.4)
                          : colors.border,
                    ),
                  ),
                  child: Icon(
                    b.$1,
                    size: 28,
                    color: b.$4 ? b.$5 : colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  b.$2,
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color: b.$4 ? colors.text : colors.textTertiary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Challenges ────────────────────────────────────────────────────────────────

const _challenges = [
  ('Book 3 times this month', 2, 3, 'Earn 150 pts', true),
  ('Leave 2 reviews this week', 1, 2, 'Earn 80 pts', true),
  ('Refer a friend', 0, 1, 'Earn 200 pts + free haircut', false),
  ('Try a new service', 0, 1, 'Earn 100 pts', false),
  ('Book back-to-back weeks', 1, 4, 'Gold badge + 500 pts', true),
];

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      itemCount: _challenges.length,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
      itemBuilder: (ctx, i) {
        final c = _challenges[i];
        return _ChallengeCard(
          title: c.$1,
          progress: c.$2,
          total: c.$3,
          reward: c.$4,
          isActive: c.$5,
        );
      },
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.title,
    required this.progress,
    required this.total,
    required this.reward,
    required this.isActive,
  });
  final String title;
  final int progress;
  final int total;
  final String reward;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final pct = (progress / total).clamp(0.0, 1.0);
    final isDone = progress >= total;

    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(
          color: isDone
              ? BBColors.success.withValues(alpha: 0.4)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: BBTypography.textTheme.titleSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BBColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BBRadius.full),
                  ),
                  child: Text(
                    'Done!',
                    style: BBTypography.textTheme.labelSmall?.copyWith(
                      color: BBColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: [
              const Icon(AppIcons.loyalty,
                  size: 14, color: BBColors.amber),
              const SizedBox(width: 4),
              Text(
                reward,
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: BBColors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation(
                    isDone ? BBColors.success : BBColors.amber,
                  ),
                  borderRadius: BorderRadius.circular(BBRadius.full),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: BBSpacing.sm),
              Text(
                '$progress / $total',
                style: BBTypography.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard ───────────────────────────────────────────────────────────────

const _leaderboard = [
  ('Raj M.', 4250, '🥇'),
  ('Priya K.', 3810, '🥈'),
  ('Ankit S.', 3540, '🥉'),
  ('Rahul V.', 2990, '4'),
  ('You', 2300, '5'),
  ('Neha R.', 1800, '6'),
  ('Arun T.', 1450, '7'),
];

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return ListView.separated(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      itemCount: _leaderboard.length,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
      itemBuilder: (ctx, i) {
        final entry = _leaderboard[i];
        final isMe = entry.$1 == 'You';
        return Container(
          padding: const EdgeInsets.all(BBSpacing.base),
          decoration: BoxDecoration(
            color: isMe
                ? BBColors.amber.withValues(alpha: 0.08)
                : colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(
              color: isMe
                  ? BBColors.amber.withValues(alpha: 0.3)
                  : colors.border,
              width: isMe ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  entry.$3,
                  style: BBTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: BBSpacing.md),
              Expanded(
                child: Text(
                  entry.$1,
                  style: BBTypography.textTheme.titleSmall?.copyWith(
                    color: isMe ? BBColors.amber : colors.text,
                    fontWeight:
                        isMe ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(AppIcons.loyalty,
                      size: 14, color: BBColors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.$2} pts',
                    style: BBTypography.textTheme.titleSmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
