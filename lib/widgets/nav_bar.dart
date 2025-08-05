// File: lib/widgets/nav_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/default_theme.dart';
import '../services/voice_assistant_service.dart';
import 'dart:async';
import 'dart:math' as math;

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.mediumSpacing,
            vertical: AppTheme.tinySpacing,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                context,
                iconPath: 'assets/nav_bar/home_icon.png',
                index: 0,
                isSelected: currentIndex == 0,
                fallbackIcon: Icons.home_rounded,
              ),
              _buildNavItem(
                context,
                iconPath: 'assets/nav_bar/calendar.png',
                index: 1,
                isSelected: currentIndex == 1,
                fallbackIcon: Icons.calendar_today_rounded,
              ),
              _buildVoiceAssistantButton(context),
              _buildNavItem(
                context,
                iconPath: 'assets/nav_bar/community_icon.png',
                index: 2,
                isSelected: currentIndex == 2,
                fallbackIcon: Icons.people_rounded,
              ),
              _buildNavItem(
                context,
                iconPath: 'assets/nav_bar/menu_icon.png',
                index: 3,
                isSelected: currentIndex == 3,
                fallbackIcon: Icons.menu_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String iconPath,
    required int index,
    required bool isSelected,
    required IconData fallbackIcon,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: AppTheme.shortAnimation,
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.smallSpacing,
          vertical: AppTheme.tinySpacing,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.getPrimaryColor(context).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppTheme.shortAnimation,
              child: Image.asset(
                iconPath,
                width: isSelected ? 28 : 26,
                height: isSelected ? 28 : 26,
                color: isSelected
                    ? AppTheme.getPrimaryColor(context)
                    : AppTheme.getIconColor(context),
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon,
                    color: isSelected
                        ? AppTheme.getPrimaryColor(context)
                        : AppTheme.getIconColor(context),
                    size: isSelected ? 28 : 26,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceAssistantButton(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -25),
      child: Consumer<VoiceAssistantService>(
        builder: (context, voiceService, child) {
          return GestureDetector(
            onTap: () => _showAdvancedVoiceDialog(context),
            onLongPressStart: (_) => _startQuickVoice(context),
            onLongPressEnd: (_) => _stopQuickVoice(context),
            child: VoiceButton(voiceState: voiceService.currentState),
          );
        },
      ),
    );
  }

  void _startQuickVoice(BuildContext context) async {
    final voiceService = Provider.of<VoiceAssistantService>(context, listen: false);
    if (!voiceService.isInitialized) {
      await voiceService.initialize();
    }
    await voiceService.startListening();
  }

  void _stopQuickVoice(BuildContext context) async {
    final voiceService = Provider.of<VoiceAssistantService>(context, listen: false);
    await voiceService.stopListening();
  }

  void _showAdvancedVoiceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedVoiceAssistantDialog(),
    );
  }
}

class VoiceButton extends StatefulWidget {
  final VoiceState voiceState;

  const VoiceButton({super.key, required this.voiceState});

  @override
  _VoiceButtonState createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    _updateAnimations();
  }

  void _updateAnimations() {
    switch (widget.voiceState) {
      case VoiceState.listening:
        _pulseController.repeat(reverse: true);
        _rotationController.stop();
        break;
      case VoiceState.processing:
        _pulseController.stop();
        _rotationController.repeat();
        break;
      case VoiceState.responding:
        _pulseController.repeat(reverse: true);
        _rotationController.stop();
        break;
      case VoiceState.idle:
      default:
        _pulseController.stop();
        _rotationController.stop();
        _pulseController.reset();
        _rotationController.reset();
        break;
    }
  }

  @override
  void didUpdateWidget(VoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voiceState != widget.voiceState) {
      _updateAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: widget.voiceState == VoiceState.processing 
                ? _rotationAnimation.value 
                : 0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: _getVoiceGradient(),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: _getVoiceColor().withOpacity(0.4),
                    spreadRadius: 3,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(AppTheme.smallSpacing),
                child: Icon(
                  _getVoiceIcon(),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getVoiceColor() {
    switch (widget.voiceState) {
      case VoiceState.listening:
        return Colors.blue;
      case VoiceState.processing:
        return Colors.orange;
      case VoiceState.responding:
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  LinearGradient _getVoiceGradient() {
    switch (widget.voiceState) {
      case VoiceState.listening:
        return LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case VoiceState.processing:
        return LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case VoiceState.responding:
        return LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.black, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getVoiceIcon() {
    switch (widget.voiceState) {
      case VoiceState.listening:
        return Icons.mic;
      case VoiceState.processing:
        return Icons.sync;
      case VoiceState.responding:
        return Icons.volume_up;
      default:
        return Icons.mic;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

class AdvancedVoiceAssistantDialog extends StatefulWidget {
  const AdvancedVoiceAssistantDialog({super.key});

  @override
  _AdvancedVoiceAssistantDialogState createState() => _AdvancedVoiceAssistantDialogState();
}

class _AdvancedVoiceAssistantDialogState extends State<AdvancedVoiceAssistantDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, MediaQuery.of(context).size.height * 0.7 * _slideAnimation.value),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.extraLargeRadius),
              ),
            ),
            child: Consumer<VoiceAssistantService>(
              builder: (context, voiceService, child) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.greyMedium,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: EdgeInsets.all(AppTheme.largeSpacing),
                      child: Text(
                        'BBBD Voice Assistant',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ),

                    // Voice visualization and controls
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: AppTheme.largeSpacing),
                        child: Column(
                          children: [
                            // Current status and text display
                            _buildStatusSection(voiceService),
                            
                            SizedBox(height: AppTheme.largeSpacing),
                            
                            // Voice button and controls
                            _buildVoiceControls(voiceService),
                            
                            SizedBox(height: AppTheme.largeSpacing),
                            
                            // Quick actions
                            _buildQuickActions(voiceService),
                            
                            SizedBox(height: AppTheme.largeSpacing),
                            
                            // Voice settings
                            _buildVoiceSettings(voiceService),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(VoiceAssistantService voiceService) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTheme.largeSpacing),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: AppTheme.getDividerColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(voiceService.currentState),
                color: _getStatusColor(voiceService.currentState),
                size: 20,
              ),
              SizedBox(width: AppTheme.smallSpacing),
              Text(
                _getStatusText(voiceService.currentState),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(voiceService.currentState),
                ),
              ),
            ],
          ),
          
          if (voiceService.lastWords.isNotEmpty) ...[
            SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'You said:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.getSubtitleColor(context),
              ),
            ),
            SizedBox(height: AppTheme.smallSpacing),
            Text(
              voiceService.lastWords,
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 16,
              ),
            ),
          ],
          
          if (voiceService.currentResponse.isNotEmpty) ...[
            SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'Assistant:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.getSubtitleColor(context),
              ),
            ),
            SizedBox(height: AppTheme.smallSpacing),
            Text(
              voiceService.currentResponse,
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 16,
              ),
            ),
          ],
          
          if (voiceService.confidence > 0) ...[
            SizedBox(height: AppTheme.smallSpacing),
            Row(
              children: [
                Text(
                  'Confidence: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getSubtitleColor(context),
                  ),
                ),
                Text(
                  '${(voiceService.confidence * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: voiceService.confidence > 0.7 
                        ? Colors.green 
                        : voiceService.confidence > 0.4 
                            ? Colors.orange 
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceControls(VoiceAssistantService voiceService) {
    return Column(
      children: [
        // Main voice button
        GestureDetector(
          onTapDown: (_) => _startListening(voiceService),
          onTapUp: (_) => _stopListening(voiceService),
          onTapCancel: () => _stopListening(voiceService),
          child: VoiceButton(voiceState: voiceService.currentState),
        ),
        
        SizedBox(height: AppTheme.mediumSpacing),
        
        // Voice wave visualization (when listening)
        if (voiceService.isListening)
          SizedBox(
            height: 60,
            child: VoiceWaveVisualization(),
          ),
        
        SizedBox(height: AppTheme.mediumSpacing),
        
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: voiceService.isListening ? Icons.stop : Icons.mic,
              label: voiceService.isListening ? 'Stop' : 'Start',
              onPressed: voiceService.isListening 
                  ? () => _stopListening(voiceService)
                  : () => _startListening(voiceService),
              color: voiceService.isListening ? Colors.red : Colors.blue,
            ),
            
            _buildControlButton(
              icon: Icons.volume_off,
              label: 'Stop Speech',
              onPressed: voiceService.isSpeaking 
                  ? () => voiceService.stopSpeaking()
                  : null,
              color: Colors.orange,
            ),
            
            _buildControlButton(
              icon: Icons.refresh,
              label: 'Test Voice',
              onPressed: () => voiceService.testVoice(),
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: onPressed != null ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: onPressed != null ? color : Colors.grey,
              width: 2,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: onPressed != null ? color : Colors.grey,
              size: 24,
            ),
          ),
        ),
        SizedBox(height: AppTheme.smallSpacing),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onPressed != null 
                ? AppTheme.getTextColor(context) 
                : AppTheme.getSubtitleColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(VoiceAssistantService voiceService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context),
          ),
        ),
        SizedBox(height: AppTheme.mediumSpacing),
        
        Wrap(
          spacing: AppTheme.smallSpacing,
          runSpacing: AppTheme.smallSpacing,
          children: [
            _buildQuickActionChip('💡 Ideas', () => voiceService.processQuickAction('ideas')),
            _buildQuickActionChip('❓ Help', () => voiceService.processQuickAction('help')),
            _buildQuickActionChip('⚙️ Settings', () => voiceService.processQuickAction('settings')),
            _buildQuickActionChip('📝 Add Reminder', () => _processCommand(voiceService, 'Add a new reminder')),
            _buildQuickActionChip('📅 Check Calendar', () => _processCommand(voiceService, 'What\'s on my calendar today?')),
            _buildQuickActionChip('💬 Send Message', () => _processCommand(voiceService, 'Help me send a message')),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.mediumSpacing,
          vertical: AppTheme.smallSpacing,
        ),
        decoration: BoxDecoration(
          color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.largeRadius),
          border: Border.all(
            color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppTheme.getPrimaryColor(context),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceSettings(VoiceAssistantService voiceService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context),
          ),
        ),
        SizedBox(height: AppTheme.mediumSpacing),
        
        // Speech Rate
        _buildSliderSetting(
          label: 'Speech Rate',
          value: 0.5, // Default value since we can't access private fields
          min: 0.1,
          max: 1.0,
          onChanged: (value) => voiceService.setSpeechRate(value),
        ),
        
        // Speech Volume
        _buildSliderSetting(
          label: 'Speech Volume',
          value: 0.8, // Default value
          min: 0.0,
          max: 1.0,
          onChanged: (value) => voiceService.setSpeechVolume(value),
        ),
        
        // Speech Pitch
        _buildSliderSetting(
          label: 'Speech Pitch',
          value: 1.0, // Default value
          min: 0.5,
          max: 2.0,
          onChanged: (value) => voiceService.setSpeechPitch(value),
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: AppTheme.getSubtitleColor(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.smallSpacing),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.getPrimaryColor(context),
              inactiveTrackColor: AppTheme.greyLight,
              thumbColor: AppTheme.getPrimaryColor(context),
              overlayColor: AppTheme.getPrimaryColor(context).withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startListening(VoiceAssistantService voiceService) async {
    if (!voiceService.isInitialized) {
      await voiceService.initialize();
    }
    await voiceService.startListening();
  }

  Future<void> _stopListening(VoiceAssistantService voiceService) async {
    await voiceService.stopListening();
  }

  Future<void> _processCommand(VoiceAssistantService voiceService, String command) async {
    // Create a simple method to process commands directly
    setState(() {
      // Show processing state temporarily
    });
    
    // Simulate processing the command
    await Future.delayed(Duration(milliseconds: 500));
    
    // You can implement this method in the voice service or handle it here
    await voiceService.testVoice(); // For now, just test voice as fallback
  }

  IconData _getStatusIcon(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        return Icons.mic;
      case VoiceState.processing:
        return Icons.sync;
      case VoiceState.responding:
        return Icons.volume_up;
      default:
        return Icons.mic_none;
    }
  }

  Color _getStatusColor(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        return Colors.blue;
      case VoiceState.processing:
        return Colors.orange;
      case VoiceState.responding:
        return Colors.green;
      default:
        return AppTheme.getSubtitleColor(context);
    }
  }

  String _getStatusText(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.processing:
        return 'Processing...';
      case VoiceState.responding:
        return 'Speaking...';
      default:
        return 'Ready to help';
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}

class VoiceWaveVisualization extends StatefulWidget {
  const VoiceWaveVisualization({super.key});

  @override
  _VoiceWaveVisualizationState createState() => _VoiceWaveVisualizationState();
}

class _VoiceWaveVisualizationState extends State<VoiceWaveVisualization>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _barControllers = List.generate(7, (index) => 
      AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );
    
    _barAnimations = _barControllers.map((controller) =>
      Tween<double>(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
    ).toList();
    
    _startAnimation();
  }

  void _startAnimation() {
    for (int i = 0; i < _barControllers.length; i++) {
      Timer(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _barControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (index) {
        return AnimatedBuilder(
          animation: _barAnimations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: 20 + (index * 5.0) * _barAnimations[index].value,
              decoration: BoxDecoration(
                color: AppTheme.getPrimaryColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}