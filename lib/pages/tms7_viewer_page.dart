import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

import '../services/threejs_bridge.dart';

/// Full-screen TMS7 3D model viewer page.
///
/// Uses [HtmlElementView] to embed a Three.js canvas for the 3D scene,
/// with a native Flutter overlay panel for controls (livery upload, template link).
class Tms7ViewerPage extends StatefulWidget {
  const Tms7ViewerPage({super.key});

  @override
  State<Tms7ViewerPage> createState() => _Tms7ViewerPageState();
}

class _Tms7ViewerPageState extends State<Tms7ViewerPage>
    with SingleTickerProviderStateMixin {
  static const _viewType = 'tms7-threejs-canvas';
  static const _containerId = 'tms7-container';
  static bool _viewRegistered = false;

  bool _sceneReady = false;
  bool _panelExpanded = true;
  late final AnimationController _panelAnimController;
  late final Animation<double> _panelSlide;
  Timer? _initTimer;

  @override
  void initState() {
    super.initState();

    _panelAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _panelSlide = CurvedAnimation(
      parent: _panelAnimController,
      curve: Curves.easeOutCubic,
    );
    _panelAnimController.forward(); // start expanded

    // Register the platform view factory once
    if (!_viewRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final div = web.document.createElement('div') as web.HTMLDivElement;
        div.id = _containerId;
        div.style
          ..width = '100%'
          ..height = '100%'
          ..overflow = 'hidden'
          ..margin = '0'
          ..padding = '0';
        return div;
      });
      _viewRegistered = true;
    }

    // Give the DOM element time to mount, then init the scene
    _initTimer = Timer(const Duration(milliseconds: 300), () {
      ThreeJsBridge.initScene(_containerId);
      if (mounted) setState(() => _sceneReady = true);
    });
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    _panelAnimController.dispose();
    ThreeJsBridge.disposeScene();
    super.dispose();
  }

  // ─── Actions ────────────────────────────────────────────────────

  void _togglePanel() {
    setState(() {
      _panelExpanded = !_panelExpanded;
      if (_panelExpanded) {
        _panelAnimController.forward();
      } else {
        _panelAnimController.reverse();
      }
    });
  }

  /// Opens a native file picker via an HTML input element and sends
  /// the selected image to the Three.js scene as a data URL.
  void _pickLiveryImage() {
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.accept = 'image/*';

    input.addEventListener(
      'change',
      ((web.Event event) {
        final files = input.files;
        if (files == null || files.length == 0) return;

        final file = files.item(0);
        if (file == null) return;

        final reader = web.FileReader();
        reader.addEventListener(
          'load',
          ((web.Event e) {
            final result = reader.result;
            if (result != null) {
              final dataUrl = (result as JSString).toDart;
              ThreeJsBridge.updateLiveryTexture(dataUrl);
            }
          }).toJS,
        );
        reader.readAsDataURL(file);
      }).toJS,
    );

    input.click();
  }

  Future<void> _openTemplateDrive() async {
    final uri = Uri.parse(
      'https://drive.google.com/drive/folders/1NC2Q2W9HxicnZOm2fgmFIUC9JLKRiYUL?usp=drive_link',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // ── Three.js Canvas ──────────────────────────────────────
          const Positioned.fill(child: HtmlElementView(viewType: _viewType)),

          // ── Loading indicator ───────────────────────────────────
          if (!_sceneReady)
            Positioned.fill(
              child: Container(
                color: colorScheme.surface,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Loading 3D Model…',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Back button ─────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _GlassIconButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // ── Overlay Panel ───────────────────────────────────────
          _buildOverlayPanel(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildOverlayPanel(BuildContext context, bool isMobile) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: isMobile ? 16 : 24,
      right: isMobile ? 16 : null,
      bottom: isMobile ? 24 : null,
      top: isMobile ? null : MediaQuery.of(context).padding.top + 24,
      child: SizeTransition(
        sizeFactor: _panelSlide,
        axisAlignment: isMobile ? 1.0 : -1.0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: _buildPanelContent(context, isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelContent(BuildContext context, bool isMobile) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row with collapse button (mobile) ──────────
          Row(
            children: [
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Test Livery',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (isMobile)
                _GlassIconButton(
                  icon: _panelExpanded
                      ? Icons.expand_more_rounded
                      : Icons.expand_less_rounded,
                  onTap: _togglePanel,
                  size: 36,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Description ───────────────────────────────────────
          Text(
            'Select an image to customize your TMS7 experience.\nAny image files are accepted.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // ── Buttons ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _GradientButton(
                  icon: Icons.upload_rounded,
                  label: 'Select Livery',
                  onTap: _pickLiveryImage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OutlineButton(
                  icon: Icons.description_outlined,
                  label: 'Template',
                  onTap: _openTemplateDrive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reusable glassy icon button ─────────────────────────────────────

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.9)
                : colorScheme.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(widget.size / 2),
            border: Border.all(
              color: _hovered
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Icon(
            widget.icon,
            color: colorScheme.onSurface,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}

// ─── Gradient-filled button ──────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: colorScheme.onPrimary, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Outlined button ─────────────────────────────────────────────────

class _OutlineButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? colorScheme.tertiary.withValues(alpha: 0.6)
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: _hovered
                    ? colorScheme.tertiary
                    : colorScheme.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _hovered
                        ? colorScheme.tertiary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
