import 'dart:async';
import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import '../theme/app_theme.dart';
import 'tms7_viewer_page.dart';

/// Dashboard page that shows Supabase connection status
/// and provides a quick way to test connectivity.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  _ConnectionStatus _status = _ConnectionStatus.idle;
  String _message = '';
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _status = _ConnectionStatus.testing;
      _message = 'Connecting to Supabase…';
    });

    if (!SupabaseConfig.isConfigured) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _status = _ConnectionStatus.warning;
        _message =
            'Supabase credentials not configured.\n'
            'Update your .env file with your project URL and anon key.';
      });
      return;
    }

    try {
      // Simple connectivity test — attempt a lightweight RPC or health check
      final client = SupabaseConfig.client!;
      // Try to reach the REST endpoint
      await client.rest
          .from('payments')
          .select()
          .limit(1)
          .timeout(const Duration(seconds: 5));

      setState(() {
        _status = _ConnectionStatus.connected;
        _message = 'Successfully connected to Supabase!';
      });
    } on TimeoutException {
      setState(() {
        _status = _ConnectionStatus.error;
        _message = 'Connection timed out. Check your URL and network.';
      });
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      // A 404 or "relation does not exist" means the server responded —
      // that's actually a successful connection test.
      if (errorString.contains('relation') ||
          errorString.contains('does not exist') ||
          errorString.contains('could not find') ||
          errorString.contains('404') ||
          errorString.contains('42P01') ||
          errorString.contains('pgrst205')) {
        setState(() {
          _status = _ConnectionStatus.connected;
          _message =
              'Connected to Supabase successfully!\n'
              '(Server responded — no tables yet, which is expected.)';
        });
      } else {
        setState(() {
          _status = _ConnectionStatus.error;
          _message = 'Connection failed:\n${e.toString().split('\n').first}';
        });
      }
    }
  }

  // ─── UI builders ──────────────────────────────────────────────────

  Color get _statusColor => switch (_status) {
    _ConnectionStatus.idle => AppTheme.textSecondary,
    _ConnectionStatus.testing => AppTheme.primary,
    _ConnectionStatus.connected => AppTheme.success,
    _ConnectionStatus.warning => AppTheme.warning,
    _ConnectionStatus.error => AppTheme.error,
  };

  IconData get _statusIcon => switch (_status) {
    _ConnectionStatus.idle => Icons.cloud_outlined,
    _ConnectionStatus.testing => Icons.sync,
    _ConnectionStatus.connected => Icons.cloud_done_rounded,
    _ConnectionStatus.warning => Icons.warning_amber_rounded,
    _ConnectionStatus.error => Icons.cloud_off_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.surfaceGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildStatusCard(),
                    const SizedBox(height: 32),
                    _buildActionButton(),
                    const SizedBox(height: 48),
                    _buildInfoCards(),
                    const SizedBox(height: 32),
                    _buildTms7LaunchCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated gradient icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.05),
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'Supabase + Flutter',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your project is ready to launch',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Status icon with glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _status == _ConnectionStatus.testing
                  ? SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: _statusColor,
                      ),
                    )
                  : Icon(
                      _statusIcon,
                      key: ValueKey(_status),
                      size: 32,
                      color: _statusColor,
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Status label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: _statusColor,
              fontWeight: FontWeight.w600,
            ),
            child: Text(_status.label),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final isLoading = _status == _ConnectionStatus.testing;
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isLoading ? null : AppTheme.primaryGradient,
        color: isLoading ? AppTheme.surfaceLight : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _testConnection,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          isLoading ? 'Testing…' : 'Test Supabase Connection',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        children: [
          _InfoCard(
            icon: Icons.settings_rounded,
            title: 'Configure',
            subtitle: 'Add your Supabase URL & anon key to .env',
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.storage_rounded,
            title: 'Database',
            subtitle: 'Create tables in Supabase Dashboard',
            color: AppTheme.accent,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.rocket_launch_rounded,
            title: 'Deploy',
            subtitle: 'Push to GitHub → auto-deploy to Pages',
            color: AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildTms7LaunchCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const Tms7ViewerPage(),
              transitionsBuilder: (_, anim, __, child) {
                return FadeTransition(opacity: anim, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.12),
                AppTheme.accent.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.view_in_ar_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'TMS7 3D Viewer',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View & customize livery in 3D',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────

class _InfoCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_hovered ? 1.02 : 1.0),
        decoration: BoxDecoration(
          color: _hovered
              ? AppTheme.surfaceLight.withValues(alpha: 0.8)
              : AppTheme.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Connection status enum ────────────────────────────────────────

enum _ConnectionStatus {
  idle('Ready to Test'),
  testing('Testing Connection…'),
  connected('Connected'),
  warning('Not Configured'),
  error('Connection Failed');

  const _ConnectionStatus(this.label);
  final String label;
}
