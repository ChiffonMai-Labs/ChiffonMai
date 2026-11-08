import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/AppTheme.dart';
import '../widgets/AppLauncherIcon.dart';

/// 应用启动加载页：主题底色 + 应用图标 + 应用名称 + 加载动画。
/// 设计目标：克制、聚焦，把视觉权重留给 Logo。
class SplashPage extends StatelessWidget {
  final bool showBrand;

  const SplashPage({super.key, this.showBrand = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: scheme.surface,
      ),
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLauncherIcon(size: 108),
                const SizedBox(height: 28),
                // 字体尚未就绪时保留标题位置，避免启动页也出现字体闪换。
                if (showBrand)
                  _buildBrand(scheme)
                else
                  const SizedBox(height: 40),
                const SizedBox(height: 32),
                _buildLoading(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand(ColorScheme scheme) {
    return Text(
      'ChiffonMai',
      style: AppTheme.font(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: scheme.onSurface,
      ),
    );
  }

  // 加载动画：Material CircularProgressIndicator
  Widget _buildLoading(ColorScheme scheme) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
      ),
    );
  }
}
