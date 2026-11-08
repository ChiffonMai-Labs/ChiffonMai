import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/entity/chongxi/MaimaiServerStatusModel.dart';
import 'package:my_first_flutter_app/service/chongxi/MaimaiServerStatusService.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/ExternalLaunchUtil.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../utils/AppDesignTokens.dart';

/// 舞萌服务器状态页面。
///
/// 数据来自 mai.chongxi.us 的机器人状态接口，页面直接展示接口提供的总览、
/// 各服务状态与延迟。
class MaimaiServerStatusPage extends StatefulWidget {
  const MaimaiServerStatusPage({super.key});

  @override
  State<MaimaiServerStatusPage> createState() => _MaimaiServerStatusPageState();
}

class _MaimaiServerStatusPageState extends State<MaimaiServerStatusPage> {
  MaimaiServerStatusEntity? _serverStatus;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadServerStatus();
  }

  Future<void> _loadServerStatus() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final status = await MaimaiServerStatusService.getServerStatus();
      if (!mounted) return;
      if (status == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = appL10n.flowServerStatusIsTemporarilyUnavailable;
        });
        return;
      }
      setState(() {
        _serverStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[MaimaiServerStatusPage] 加载失败: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = appL10n.flowCouldNotLoadServerStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPageScaffold(
      title: context.l10n.featureServerStatus,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _errorMessage.isNotEmpty
            ? KeyedSubtree(
                key: const ValueKey('server-status-error'),
                child: _buildErrorState(),
              )
            : KeyedSubtree(
                key: ValueKey(_isLoading && _serverStatus == null
                    ? 'server-status-loading'
                    : 'server-status-loaded'),
                child: _buildServerStatusContent(),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(_errorMessage),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _loadServerStatus,
            child:  Text(context.l10n.flowRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildServerStatusContent() {
    final status = _serverStatus;
    if (status == null) return _buildLoadingContent();

    return RefreshIndicator(
      onRefresh: _loadServerStatus,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          TextButton.icon(
            onPressed: () => ExternalLaunchUtil.open(
              Uri.parse('https://mai.chongxi.us/'),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 17),
            label:  Text(context.l10n.flowDataFromIsMaiDownByChongxi),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
          ),
          _buildOverviewCard(status),
          const SizedBox(height: 16),
          Text(
            context.l10n.flowServiceStatus,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...status.services.map(_buildServiceCard),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        TextButton.icon(
          onPressed: null,
          icon: const Icon(Icons.open_in_new_rounded, size: 17),
          label:  Text(context.l10n.flowDataFromIsMaiDownByChongxi),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
        ),
        Container(
          height: 168,
          decoration: BoxDecoration(
            color: AppSurfaces.card(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: scheme.primary),
                const SizedBox(height: 12),
                Text(context.l10n.flowReadingServerStatus,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.flowServiceStatus,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < 3; i++)
          Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppSurfaces.card(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
            ),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverviewCard(MaimaiServerStatusEntity status) {
    final color = _statusColor(status.status);
    final latency = status.latency.currentMs;
    final reports = status.reports;
    final statusLabel = status.statusText.isEmpty
        ? (status.isHealthy ? context.l10n.flowHealthy : context.l10n.flowUnhealthy)
        : status.statusText;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppSurfaces.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.dns_outlined, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.verdictText,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(statusLabel, color),
              ],
            ),
            if (status.summary.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                status.summary,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetricChip(
                  Icons.speed_outlined,
                  latency == null ? context.l10n.flowLatency : context.l10n.flowLatencyP0Ms((latency).toString()),
                  _latencyColor(latency),
                ),
                if (status.latency.loadText.isNotEmpty)
                  _buildMetricChip(
                    Icons.swap_vert_rounded,
                    status.latency.loadText,
                    Theme.of(context).colorScheme.primary,
                  ),
                _buildMetricChip(
                  Icons.check_circle_outline,
                  context.l10n.flowHealthyP0((reports.normalCount).toString()),
                  AppColors.successGreen(Theme.of(context).brightness),
                ),
                _buildMetricChip(
                  Icons.warning_amber_rounded,
                  context.l10n.flowIssuesP0((reports.anomalyCount).toString()),
                  AppColors.warningOrange(Theme.of(context).brightness),
                ),
              ],
            ),
            if (status.timestamp.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.flowUpdatedP02((status.timestamp).toString()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(MaimaiServiceStatus service) {
    final color = _statusColor(service.state);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppSurfaces.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(Icons.circle, color: color, size: 13),
        ),
        title: Text(service.name.isEmpty ? service.key : service.name),
        subtitle:
            service.durationText.isEmpty ? null : Text(service.durationText),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              service.stateText,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            if (service.latency != null)
              Text(
                '${service.latency} ms',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    final isSingleCharacter = text.runes.length <= 1;
    return SizedBox(
      width: isSingleCharacter ? 32 : 68,
      height: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String text, Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(text, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String state) {
    switch (state) {
      case 'ok':
      case 'normal':
      case 'up':
        return AppColors.successGreen(Theme.of(context).brightness);
      case 'warning':
      case 'degraded':
        return AppColors.warningOrange(Theme.of(context).brightness);
      default:
        return AppColors.errorRed(Theme.of(context).brightness);
    }
  }

  Color _latencyColor(int? latency) {
    if (latency == null) return Theme.of(context).colorScheme.onSurfaceVariant;
    if (latency < 50) {
      return AppColors.successGreen(Theme.of(context).brightness);
    }
    if (latency < 100) {
      return AppColors.warningOrange(Theme.of(context).brightness);
    }
    return AppColors.errorRed(Theme.of(context).brightness);
  }
}
