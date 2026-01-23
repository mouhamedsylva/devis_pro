/// Splash Screen Premium - Générateur de Devis
///
/// Design professionnel avec :
/// - Logo document/facture animé
/// - Particules connectées représentant les données
/// - Anneaux rotatifs symbolisant le workflow
/// - Titre DEVISPRO avec effet premium
/// - Icônes métier (calculatrice, signature, envoi)
/// - Barre de progression avec étapes du processus

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui;

import '../../core/constants/app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers pour la séquence d'entrée
  late AnimationController _logoEnterController;
  late AnimationController _ringsEnterController;
  late AnimationController _titleEnterController;
  late AnimationController _progressEnterController;
  
  // Animation controllers pour les effets continus
  late AnimationController _logoFloatController;
  late AnimationController _rotationController;
  late AnimationController _glitchController;
  late AnimationController _fadeController;
  
  // Animations
  late Animation<double> _logoEnterAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _ringsEnterAnimation;
  late Animation<double> _titleEnterAnimation;
  late Animation<double> _progressEnterAnimation;
  
  double _progress = 0.0;
  String _statusText = 'Initialisation du système...';
  Timer? _progressTimer;
  
  final List<String> _statuses = [
    'Initialisation du système...',
    'Chargement des modèles de devis...',
    'Configuration des calculs...',
    'Préparation de l\'interface...',
    'Vérification des templates...',
    'Finalisation...'
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  @override
  void dispose() {
    _logoEnterController.dispose();
    _ringsEnterController.dispose();
    _titleEnterController.dispose();
    _progressEnterController.dispose();
    _logoFloatController.dispose();
    _rotationController.dispose();
    _glitchController.dispose();
    _fadeController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _setupAnimations() {
    // 1. Logo entrance (rotation d'entrée)
    _logoEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoEnterAnimation = CurvedAnimation(
      parent: _logoEnterController,
      curve: Curves.elasticOut,
    );
    _logoRotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _logoEnterController, curve: Curves.easeOutBack),
    );

    // 2. Rings entrance
    _ringsEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _ringsEnterAnimation = CurvedAnimation(
      parent: _ringsEnterController,
      curve: Curves.easeOutBack,
    );

    // 3. Title entrance
    _titleEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleEnterAnimation = CurvedAnimation(
      parent: _titleEnterController,
      curve: Curves.easeOut,
    );

    // 4. Progress section entrance
    _progressEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressEnterAnimation = CurvedAnimation(
      parent: _progressEnterController,
      curve: Curves.easeOut,
    );

    // Continuous animations
    _logoFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  Future<void> _startAnimationSequence() async {
    // 1. Logo + cercle arrivent avec rotation (1.2s)
    await Future.delayed(const Duration(milliseconds: 300));
    _logoEnterController.forward();
    
    // 2. Anneaux arrivent en tournant (après 0.6s)
    await Future.delayed(const Duration(milliseconds: 600));
    _ringsEnterController.forward();
    _rotationController.repeat(); // Commencer la rotation continue
    
    // 3. Titre arrive (après 0.5s)
    await Future.delayed(const Duration(milliseconds: 500));
    _titleEnterController.forward();
    
    // 4. Progress arrive et démarre (après 0.4s)
    await Future.delayed(const Duration(milliseconds: 400));
    _progressEnterController.forward();
    _startProgressAnimation();
    
    // Démarrer les animations continues
    await Future.delayed(const Duration(milliseconds: 200));
    _logoFloatController.repeat();
    _glitchController.repeat();
  }

  void _startProgressAnimation() {
    int statusIndex = 0;
    double targetProgress = 0.0;
    
    // Animation fluide avec interpolation
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        // Incrément du progrès cible
        targetProgress += (math.Random().nextDouble() * 8 + 2) / 100;
        
        if (targetProgress >= 1.0) {
          targetProgress = 1.0;
        }
        
        // Interpolation fluide vers la cible
        _progress += (targetProgress - _progress) * 0.15;
        
        if (_progress >= 0.99 && targetProgress >= 1.0) {
          _progress = 1.0;
          _statusText = 'Prêt à démarrer !';
          timer.cancel();
          
          _fadeController.forward().then((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            });
          });
        } else {
          final newStatusIndex = (_progress * _statuses.length).floor();
          if (newStatusIndex != statusIndex && newStatusIndex < _statuses.length) {
            statusIndex = newStatusIndex;
            _statusText = _statuses[statusIndex];
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoEnterController,
          _ringsEnterController,
          _titleEnterController,
          _progressEnterController,
          _logoFloatController,
          _rotationController,
          _glitchController,
          _fadeController,
        ]),
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _fadeController.value,
            child: Stack(
              children: [
                // Animated gradient background
                _buildAnimatedGradient(),
                
                // Particles canvas - représente les données et calculs
                CustomPaint(
                  size: size,
                  painter: ParticlePainter(
                    animation: _rotationController,
                  ),
                ),
                
                // Main content
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(flex: 1),
                      
                      // Logo document/devis avec effet 3D
                      _build3DLogo(),
                      
                      const SizedBox(height: 40),
                      
                      // Rotating rings symbolisant le workflow
                      SizedBox(
                        width: 350,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildRotatingRing(1, false),
                            _buildRotatingRing(2, true),
                            // Brand title avec tagline au centre
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildBrandTitle(),
                                const SizedBox(height: 8),
                                Text(
                                  'GÉNÉRATEUR DE DEVIS PROFESSIONNEL',
                                  style: TextStyle(
                                    color: AppColors.yellow,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(flex: 1),
                      
                      // Progress section avec étapes
                      _buildProgressSection(),
                      
                      const Spacer(flex: 1),
                      
                      // Bottom features - fonctionnalités métier
                      _buildBottomFeatures(),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedGradient() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_rotationController.value * 2 - 1, -1),
              end: Alignment(1 - _rotationController.value * 2, 1),
              colors: const [
                Color(0xFF1A1A1A),
                Color(0xFF2A2A2A),
                Color(0xFF1A1A1A),
                Color(0xFF2A2A2A),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRotatingRing(int index, bool reverse) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final rotation = reverse
            ? -_rotationController.value * 2 * math.pi
            : _rotationController.value * 2 * math.pi;
        
        final enterValue = _ringsEnterAnimation.value.clamp(0.0, 1.0);
        final enterRotation = (1 - enterValue) * 2 * math.pi;
        
        return Opacity(
          opacity: enterValue,
          child: Transform.scale(
            scale: enterValue,
            child: Transform.rotate(
              angle: rotation * (index == 1 ? 1.0 : 1.33) + enterRotation * (reverse ? -1 : 1),
              child: Container(
                width: index == 1 ? 280 : 320,
                height: index == 1 ? 180 : 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(
                      index == 1 ? 140 : 160,
                      index == 1 ? 90 : 100,
                    ),
                  ),
                  border: Border.all(
                    color: AppColors.yellow.withOpacity((0.3 * enterValue).clamp(0.0, 1.0)),
                    width: 2,
                  ),
                ),
                child: CustomPaint(
                  painter: ArcPainter(
                    color: AppColors.yellow.withOpacity((0.3 * enterValue).clamp(0.0, 1.0)),
                    isReverse: reverse,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _build3DLogo() {
    return AnimatedBuilder(
      animation: _logoFloatController,
      builder: (context, child) {
        final floatProgress = _logoFloatController.value;
        final rotateY = math.sin(floatProgress * 2 * math.pi) * 0.1;
        final rotateX = math.cos(floatProgress * 2 * math.pi) * 0.1;
        
        final enterValue = _logoEnterAnimation.value.clamp(0.0, 1.0);
        final enterRotation = _logoRotationAnimation.value;
        
        return Opacity(
          opacity: enterValue,
          child: Transform.scale(
            scale: enterValue,
            child: Transform.rotate(
              angle: enterRotation,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotateY)
                  ..rotateX(rotateX),
                alignment: Alignment.center,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFDB913),
                        Color(0xFFFFD700),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withOpacity((0.4 * enterValue).clamp(0.0, 1.0)),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Document icon de base
                      Icon(
                        Icons.description,
                        size: 70,
                        color: Colors.white,
                      ),
                      // Overlay avec lignes de devis
                      Positioned(
                        bottom: 45,
                        child: Container(
                          width: 40,
                          child: Column(
                            children: [
                              Container(
                                height: 2,
                                width: 30,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                height: 2,
                                width: 25,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                height: 2,
                                width: 20,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Icône € pour symboliser le devis
                      Positioned(
                        bottom: 35,
                        right: 35,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '€',
                              style: TextStyle(
                                color: AppColors.yellow,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandTitle() {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        final shouldGlitch = _glitchController.value > 0.90 && 
                             _glitchController.value < 0.94;
        
        final enterValue = _titleEnterAnimation.value.clamp(0.0, 1.0);
        final enterOffset = (1 - enterValue) * 30;
        
        return Opacity(
          opacity: enterValue,
          child: Transform.translate(
            offset: Offset(0, enterOffset),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: shouldGlitch 
                      ? Offset(
                          (math.Random().nextDouble() - 0.5) * 4,
                          (math.Random().nextDouble() - 0.5) * 4,
                        )
                      : Offset.zero,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: shouldGlitch
                          ? [AppColors.yellow, const Color(0xFFFFD700)]
                          : [AppColors.yellow, AppColors.yellow],
                    ).createShader(bounds),
                    child: const Text(
                      'DEVIS',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Transform.translate(
                  offset: shouldGlitch 
                      ? Offset(
                          (math.Random().nextDouble() - 0.5) * 4,
                          (math.Random().nextDouble() - 0.5) * 4,
                        )
                      : Offset.zero,
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSection() {
    final enterValue = _progressEnterAnimation.value.clamp(0.0, 1.0);
    
    return Opacity(
      opacity: enterValue,
      child: Transform.translate(
        offset: Offset(0, (1 - enterValue) * 20),
        child: SizedBox(
          width: 350,
          child: Column(
            children: [
              // Circular progress
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: CircularProgressPainter(
                        progress: _progress,
                        color: AppColors.yellow,
                      ),
                    ),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: (_progress * 100).toInt()),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Text(
                          '$value%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.yellow,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Linear progress bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFDB913),
                          Color(0xFFFFD700),
                          Color(0xFFFDB913),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.yellow.withOpacity(0.6),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _statusText,
                  key: ValueKey<String>(_statusText),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomFeatures() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFeatureItem(Icons.calculate, 'CALCUL AUTO'),
        const SizedBox(width: 40),
        _buildFeatureItem(Icons.edit_document, 'PERSONNALISABLE'),
        const SizedBox(width: 40),
        _buildFeatureItem(Icons.send, 'ENVOI RAPIDE'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow.withOpacity(0.15),
                border: Border.all(
                  color: AppColors.yellow.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple effect
                  Transform.scale(
                    scale: 1.0 + (_rotationController.value * 0.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.yellow.withOpacity(
                            (1 - _rotationController.value) * 0.5,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    color: AppColors.yellow,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 9,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Particle Painter - représente les données qui circulent
class ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final List<Particle> particles = [];
  
  ParticlePainter({required this.animation}) : super(repaint: animation) {
    for (int i = 0; i < 80; i++) {
      particles.add(Particle());
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(size);
      particle.draw(canvas);
    }

    // Draw connections - symbolise les liens entre données
    final paint = Paint()..strokeWidth = 1;
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final dx = particles[i].x - particles[j].x;
        final dy = particles[i].y - particles[j].y;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance < 150) {
          paint.color = AppColors.yellow.withOpacity(
            0.2 * (1 - distance / 150),
          );
          canvas.drawLine(
            Offset(particles[i].x, particles[i].y),
            Offset(particles[j].x, particles[j].y),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class Particle {
  double x = 0;
  double y = 0;
  double size = 0;
  double speedX = 0;
  double speedY = 0;
  double opacity = 0;

  Particle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble() * 1000;
    y = math.Random().nextDouble() * 1000;
    size = math.Random().nextDouble() * 2.5 + 0.8;
    speedX = (math.Random().nextDouble() - 0.5) * 0.6;
    speedY = (math.Random().nextDouble() - 0.5) * 0.6;
    opacity = math.Random().nextDouble() * 0.4 + 0.1;
  }

  void update(Size size) {
    x += speedX;
    y += speedY;

    if (x > size.width || x < 0) speedX *= -1;
    if (y > size.height || y < 0) speedY *= -1;
  }

  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.yellow.withOpacity(opacity);
    canvas.drawCircle(Offset(x, y), size, paint);
  }
}

// Arc Painter for rotating rings
class ArcPainter extends CustomPainter {
  final Color color;
  final bool isReverse;

  ArcPainter({required this.color, required this.isReverse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    if (isReverse) {
      canvas.drawArc(rect, math.pi, math.pi, false, paint);
    } else {
      canvas.drawArc(rect, 0, math.pi, false, paint);
    }
  }

  @override
  bool shouldRepaint(ArcPainter oldDelegate) => false;
}

// Circular Progress Painter
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}