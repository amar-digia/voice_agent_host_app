import 'package:digia_engage/digia_engage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../data/mock_data.dart';
import '../services/digia_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/home_sections.dart';
import '../widgets/order_sheet.dart';
import '../widgets/portfolio_card.dart';
import 'kyc_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    (
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
      screenId: ScreenIds.home,
    ),
    (
      icon: Icons.candlestick_chart_outlined,
      selectedIcon: Icons.candlestick_chart,
      label: 'Markets',
      screenId: ScreenIds.markets,
    ),
    (
      icon: Icons.pie_chart_outline,
      selectedIcon: Icons.pie_chart,
      label: 'Portfolio',
      screenId: ScreenIds.portfolio,
    ),
    (
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Orders',
      screenId: ScreenIds.orders,
    ),
    (
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Account',
      screenId: ScreenIds.account,
    ),
  ];

  @override
  void initState() {
    super.initState();
    Digia.setCurrentScreen(_tabs[_tabIndex].screenId);
  }

  void _selectTab(int index) {
    setState(() => _tabIndex = index);
    Digia.setCurrentScreen(_tabs[index].screenId);
  }

  void _showComingSoon(String feature) =>
      showAppMessage(context, '$feature is coming soon');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: DigiaAnchor(
        anchorKey: 'voice_agent_button',
        child: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.record_voice_over_outlined),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: switch (_tabs[_tabIndex].screenId) {
          ScreenIds.home => _HomeFeed(onComingSoon: _showComingSoon),
          ScreenIds.account => const _AccountTab(),
          _ => _PlaceholderTab(label: _tabs[_tabIndex].label),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: _selectTab,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: DigiaAnchor(
                anchorKey: 'tab_${tab.screenId}',
                child: Icon(tab.icon),
              ),
              selectedIcon: DigiaAnchor(
                anchorKey: 'tab_${tab.screenId}',
                child: Icon(tab.selectedIcon),
              ),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _HomeFeed extends StatelessWidget {
  const _HomeFeed({required this.onComingSoon});

  final ValueChanged<String> onComingSoon;

  void _onQuickAction(BuildContext context, String action) => switch (action) {
    'Buy' => showOrderSheet(context),
    'Sell' => showOrderSheet(context, side: OrderSide.sell),
    _ => onComingSoon(action),
  };

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // Build the whole feed up front so the agent can see every element,
      // not just the ones scrolled into view.
      scrollCacheExtent: const ScrollCacheExtent.pixels(5000),
      slivers: [
        SliverToBoxAdapter(child: _Header(onComingSoon: onComingSoon)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DigiaAnchor(
              anchorKey: 'home_portfolio_card',
              child: PortfolioCard(
                history: portfolioHistory,
                invested: portfolioInvested,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: DigiaSlot('home_banner')),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: DigiaAnchor(
            anchorKey: 'home_quick_actions',
            child: QuickActions(onAction: (a) => _onQuickAction(context, a)),
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Market overview',
            onSeeAll: () => onComingSoon('Markets'),
          ),
        ),
        const SliverToBoxAdapter(
          child: MarketIndicesStrip(indices: marketIndices),
        ),
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Watchlist',
            onSeeAll: () => onComingSoon('Watchlist'),
          ),
        ),
        SliverList.builder(
          itemCount: watchlist.length,
          itemBuilder: (context, i) => StockTile(
            stock: watchlist[i],
            onTap: () => showOrderSheet(context, symbol: watchlist[i].symbol),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Top movers')),
        SliverToBoxAdapter(
          child: TopMovers(gainers: topGainers, losers: topLosers),
        ),
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Market news',
            onSeeAll: () => onComingSoon('News'),
          ),
        ),
        SliverList.builder(
          itemCount: marketNews.length,
          itemBuilder: (context, i) => NewsTile(item: marketNews[i], index: i),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onComingSoon});

  final ValueChanged<String> onComingSoon;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceRaised,
            child: Icon(Icons.person, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Search',
            onPressed: () => onComingSoon('Search'),
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => onComingSoon('Notifications'),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Account',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        DigiaAnchor(
          anchorKey: 'account_kyc',
          child: ListTile(
            key: const ValueKey('account_kyc'),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: const Icon(Icons.badge_outlined, color: AppColors.accent),
            title: const Text('Complete KYC'),
            subtitle: const Text(
              'Verify your PAN to start investing',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openKycScreen(context),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label — coming soon',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
      ),
    );
  }
}
