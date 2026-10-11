import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/article_provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/article_card.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';
import 'form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticleProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen())),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Tulis'),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: provider.refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 400) provider.loadMore();
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _Masthead()),
                if (provider.featured.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: _SectionTitle('Pilihan Redaksi')),
                  SliverToBoxAdapter(child: _FeaturedCarousel(provider)),
                ],
                const SliverToBoxAdapter(child: _SectionTitle('Kabar Terbaru')),
                if (provider.categories.isNotEmpty) SliverToBoxAdapter(child: _CategoryChips(provider)),
                ..._articleList(context, provider),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _articleList(BuildContext context, ArticleProvider provider) {
    if (provider.articles.isEmpty) {
      final Widget child;
      if (provider.isLoading) {
        child = const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
        );
      } else if (provider.error != null) {
        child = ErrorView(message: provider.error!, onRetry: provider.refresh);
      } else {
        child = Padding(
          padding: const EdgeInsets.all(48),
          child: Text(
            'Belum ada artikel.',
            textAlign: TextAlign.center,
            style: AppText.body(16, color: AppColors.muted),
          ),
        );
      }
      return [SliverToBoxAdapter(child: child)];
    }

    return [
      SliverList.builder(
        itemCount: provider.articles.length,
        itemBuilder: (context, i) => ArticleCard(
          article: provider.articles[i],
          onTap: () => Navigator.push(context, DetailScreen.route(provider.articles[i])),
        ),
      ),
      if (provider.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
          ),
        ),
    ];
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatDate(DateTime.now()).toUpperCase(), style: AppText.label()),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Kabar'),
                      TextSpan(
                        text: '.',
                        style: AppText.headline(52, color: AppColors.accent),
                      ),
                    ],
                  ),
                  style: AppText.headline(52, weight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: auth.isAdmin ? 'Mode admin aktif' : 'Masuk admin',
                onPressed: () => auth.isAdmin ? _confirmLogout(context) : _showLogin(context),
                icon: Icon(
                  auth.isAdmin ? Icons.verified_user : Icons.key_outlined,
                  color: auth.isAdmin ? AppColors.accent : AppColors.ink,
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.only(right: 8), child: DoubleRule()),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari mode admin?'),
        content: const Text('Key admin akan dihapus dari perangkat ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (ok == true) auth.logout();
  }

  Future<void> _showLogin(BuildContext context) =>
      showDialog(context: context, builder: (_) => const _LoginDialog());
}

class _LoginDialog extends StatefulWidget {
  const _LoginDialog();

  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await context.read<AuthProvider>().login(_controller.text);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
        return;
      }
      setState(() => _error = 'Key ditolak server.');
    } catch (e) {
      setState(() => _error = '$e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mode Admin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masukkan ADMIN_API_KEY untuk menulis, mengubah, dan menghapus artikel. '
            'Key hanya disimpan di perangkat ini.',
            style: AppText.ui(13.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: 'x-api-key', errorText: _error),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Masuk'),
        ),
      ],
    );
  }
}

class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel(this.provider);

  final ArticleProvider provider;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final _controller = PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featured = widget.provider.featured;
    return SizedBox(
      height: 400,
      child: PageView.builder(
        controller: _controller,
        itemCount: featured.length,
        itemBuilder: (context, i) => FeaturedCard(
          article: featured[i],
          onTap: () => Navigator.push(context, DetailScreen.route(featured[i])),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
    child: Text(title, style: AppText.headline(24)),
  );
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips(this.provider);

  final ArticleProvider provider;

  @override
  Widget build(BuildContext context) {
    final items = [(null, 'Semua'), for (final c in provider.categories) (c.slug, c.name)];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (slug, name) = items[i];
          final selected = provider.selectedCategory == slug;
          return GestureDetector(
            onTap: () => provider.selectCategory(slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.ink : AppColors.card,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: selected ? AppColors.ink : AppColors.line),
              ),
              child: Text(
                name,
                style: AppText.ui(
                  13,
                  weight: FontWeight.w600,
                  color: selected ? AppColors.paper : AppColors.ink,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
