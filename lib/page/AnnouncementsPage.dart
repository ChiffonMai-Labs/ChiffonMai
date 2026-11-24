import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';

import '../service/AnnouncementService.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AnnouncementDialog.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/EmptyState.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';

String _publishedDate(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context)
        .formatMediumDate(date.toUtc().add(const Duration(hours: 8)));

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final _service = AnnouncementService();
  final _items = <AnnouncementSummary>[];
  final ListEntrance _entrance = ListEntrance();
  int? _nextOffset;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool append = false}) async {
    if (_loading) return;
    final offset = append ? _nextOffset : 0;
    if (offset == null) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final page = await _service.loadList(offset: offset);
      if (!mounted) return;
      setState(() {
        if (!append) _items.clear();
        final ids = _items.map((item) => item.id).toSet();
        _items.addAll(page.items.where((item) => ids.add(item.id)));
        _nextOffset = page.nextOffset;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(AnnouncementSummary item) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => _AnnouncementDetailPage(item: item, service: _service),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasFooter = _nextOffset != null || _loading || _error;
    return BackgroundPageScaffold(
      title: l10n.announcementCenter,
      actions: [
        IconButton(
          tooltip: l10n.flowRetry,
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: _items.isEmpty
          ? _loading
              ? const _AnnouncementLoading()
              : _error
                  ? _AnnouncementError(onRetry: _load)
                  : EmptyState(
                      icon: Icons.campaign_outlined,
                      title: l10n.announcementEmpty,
                    )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppDesignTokens.gutter,
                4,
                AppDesignTokens.gutter,
                MediaQuery.paddingOf(context).bottom + 16,
              ),
              itemCount: _items.length + (hasFooter ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _loading
                        ? const SmoothLinearProgressIndicator()
                        : Center(
                            child: TextButton(
                              onPressed: () =>
                                  _load(append: _nextOffset != null),
                              child: Text(_error
                                  ? l10n.flowRetry
                                  : l10n.announcementLoadMore),
                            ),
                          ),
                  );
                }
                final item = _items[index];
                final date = item.publishedAt;
                final theme = Theme.of(context);
                final colors = theme.colorScheme;
                return _entrance.wrap(
                  _items.isEmpty ? null : _items.first.id,
                  index,
                  PressScale(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
                        ),
                        child: Icon(Icons.campaign_outlined,
                            color: colors.onPrimaryContainer),
                      ),
                      title: Text(item.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      subtitle: date == null
                          ? null
                          : Text(_publishedDate(context, date)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _open(item),
                    ),
                  ),
                  key: ValueKey(item.id),
                  maxAnimatedIndex: 8,
                );
              },
            ),
    );
  }
}

class _AnnouncementDetailPage extends StatefulWidget {
  const _AnnouncementDetailPage({required this.item, required this.service});

  final AnnouncementSummary item;
  final AnnouncementService service;

  @override
  State<_AnnouncementDetailPage> createState() =>
      _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState extends State<_AnnouncementDetailPage> {
  late Future<Announcement> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.service.loadDetail(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPageScaffold(
      title: context.l10n.announcementDetail,
      child: FutureBuilder<Announcement>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _AnnouncementLoading();
          }
          final value = snapshot.data;
          if (value == null) {
            return _AnnouncementError(onRetry: () {
              setState(
                  () => _detail = widget.service.loadDetail(widget.item.id));
            });
          }
          final theme = Theme.of(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppDesignTokens.gutter,
              10,
              AppDesignTokens.gutter,
              MediaQuery.paddingOf(context).bottom + 16,
            ),
            children: [
              EntranceAnimation(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (value.publishedAt case final DateTime date) ...[
                      Text(_publishedDate(context, date),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          )),
                      const SizedBox(height: 8),
                    ],
                    Semantics(
                      header: true,
                      child: Text(value.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              EntranceAnimation(
                  index: 1, child: AnnouncementContent(value: value)),
            ],
          );
        },
      ),
    );
  }
}

class _AnnouncementLoading extends StatelessWidget {
  const _AnnouncementLoading();

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(width: 120, child: SmoothLinearProgressIndicator()),
      );
}

class _AnnouncementError extends StatelessWidget {
  const _AnnouncementError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: context.l10n.announcementLoadFailed,
        actionLabel: context.l10n.flowRetry,
        actionIcon: Icons.refresh_rounded,
        onAction: onRetry,
      );
}
