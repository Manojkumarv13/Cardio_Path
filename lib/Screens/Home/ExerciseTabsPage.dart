import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Constants/Lists.dart';

class ExerciseTabsPage extends StatefulWidget {
  final String selectedLanguage;
  const ExerciseTabsPage({super.key, this.selectedLanguage = 'English'});

  @override
  State<ExerciseTabsPage> createState() => _ExerciseTabsPageState();
}

class _ExerciseTabsPageState extends State<ExerciseTabsPage> {
  String? _activeExercise;
  int _elapsedSeconds = 0;
  Timer? _timer;

  void _onStart(String exerciseName) {
    setState(() {
      _activeExercise = exerciseName;
      _elapsedSeconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.selectedLanguage == 'Tamil'
              ? "தொடங்கியது: $exerciseName"
              : "Started $exerciseName",
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _onStop(String exerciseName) {
    if (_activeExercise == exerciseName) {
      setState(() {
        _activeExercise = null;
        _elapsedSeconds = 0;
      });
      _timer?.cancel();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.selectedLanguage == 'Tamil'
              ? "நிறுத்தப்பட்டது: $exerciseName"
              : "Stopped $exerciseName",
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              elevation: 1,
              flexibleSpace: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TabBar(
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.black87,
                      indicator: const UnderlineTabIndicator(
                        borderSide:
                        BorderSide(width: 3, color: Colors.blueAccent),
                      ),
                      labelStyle:
                      GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(
                            text: widget.selectedLanguage == 'Tamil'
                                ? 'வெப்பமூட்டல்'
                                : 'Warm Up'),
                        Tab(
                            text: widget.selectedLanguage == 'Tamil'
                                ? 'முக்கியம்'
                                : 'Main'),
                        Tab(
                            text: widget.selectedLanguage == 'Tamil'
                                ? 'சூடு குறை'
                                : 'Cool Down'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              ExerciseList(
                type: "warmup",
                activeExercise: _activeExercise,
                elapsedSeconds: _elapsedSeconds,
                onStart: _onStart,
                onStop: _onStop,
                selectedLanguage: widget.selectedLanguage,
              ),
              ExerciseList(
                type: "main",
                activeExercise: _activeExercise,
                elapsedSeconds: _elapsedSeconds,
                onStart: _onStart,
                onStop: _onStop,
                selectedLanguage: widget.selectedLanguage,
              ),
              ExerciseList(
                type: "cooldown",
                activeExercise: _activeExercise,
                elapsedSeconds: _elapsedSeconds,
                onStart: _onStart,
                onStop: _onStop,
                selectedLanguage: widget.selectedLanguage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExerciseList extends StatefulWidget {
  final String type;
  final String? activeExercise;
  final int? elapsedSeconds;
  final Function(String)? onStart;
  final Function(String)? onStop;
  final String selectedLanguage;

  const ExerciseList({
    super.key,
    required this.type,
    this.activeExercise,
    this.elapsedSeconds,
    this.onStart,
    this.onStop,
    required this.selectedLanguage,
  });

  @override
  State<ExerciseList> createState() => _ExerciseListState();
}

class _ExerciseListState extends State<ExerciseList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final exercises = widget.type == "warmup"
        ? MyLists.WarmUpExercises
        : widget.type == "main"
        ? MyLists.MainExercises
        : MyLists.CoolDownExercises;

    if (exercises.isEmpty) {
      return const Center(
        child: Text(
          "No exercises available.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final item = exercises[index];
        return ExerciseCard(
          name: item['name'] ?? '',
          duration: item['duration'] ?? '',
          todayTime: item['todayTime'] ?? '',
          monthTime: item['monthTime'] ?? '',
          gif: item['gif'] ?? '',
          procedure: item['procedure'] ??
              'Follow the correct posture and breathing rhythm.',
          procedureTamil: item['proceduretamil'] ?? '',
          isActive: widget.activeExercise == item['name'],
          elapsedSeconds: widget.elapsedSeconds ?? 0,
          onStart: widget.onStart ?? (_) {},
          onStop: widget.onStop ?? (_) {},
          selectedLanguage: widget.selectedLanguage,
        );
      },
    );
  }
}

class ExerciseCard extends StatefulWidget {
  final String name;
  final String duration;
  final String todayTime;
  final String monthTime;
  final String gif;
  final String procedure;
  final String procedureTamil;
  final bool isActive;
  final int elapsedSeconds;
  final Function(String) onStart;
  final Function(String) onStop;
  final String selectedLanguage;

  const ExerciseCard({
    super.key,
    required this.name,
    required this.duration,
    required this.todayTime,
    required this.monthTime,
    required this.gif,
    required this.procedure,
    required this.procedureTamil,
    required this.isActive,
    required this.elapsedSeconds,
    required this.onStart,
    required this.onStop,
    required this.selectedLanguage,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _showProcedure = false;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.5,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  Future<void> _speakProcedure() async {
    // ✅ FIX: match your saved language string ("Tamil" or "English")
    final isTamil = widget.selectedLanguage == 'Tamil';

    final textToSpeak =
    isTamil ? widget.procedureTamil : widget.procedure;

    if (textToSpeak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTamil
              ? 'பேச எதுவும் கிடைக்கவில்லை'
              : 'No text available for TTS'),
        ),
      );
      return;
    }

    await _flutterTts.setLanguage(isTamil ? "ta-IN" : "en-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    setState(() => _isSpeaking = true);
    await _flutterTts.speak(textToSpeak);

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = widget.selectedLanguage == 'Tamil';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: widget.isActive ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              widget.gif,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 190,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, size: 50),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoChip(Icons.timer, widget.duration, Colors.blue),
                    _infoChip(Icons.today, "Today: ${widget.todayTime}",
                        Colors.green),
                    _infoChip(Icons.calendar_month,
                        "Month: ${widget.monthTime}", Colors.deepOrange),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _showProcedure = !_showProcedure),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTamil ? "செய்முறை" : "Procedure",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isSpeaking
                                  ? Icons.volume_up
                                  : Icons.volume_down,
                              color: Colors.blueAccent,
                            ),
                            onPressed: _speakProcedure,
                          ),
                          Icon(
                            _showProcedure
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: _showProcedure
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      isTamil
                          ? widget.procedureTamil
                          : widget.procedure,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),
                _startStopButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _startStopButton() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = _glowController.value;
        return GestureDetector(
          onTap: () {
            if (widget.isActive) {
              widget.onStop(widget.name);
            } else {
              widget.onStart(widget.name);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isActive
                    ? [Colors.red, Colors.redAccent]
                    : [Colors.green, Colors.teal],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (widget.isActive
                      ? Colors.red
                      : Colors.green)
                      .withOpacity(0.4 * glow),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isActive
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isActive
                      ? (widget.selectedLanguage == 'Tamil' ? "நிறுத்து" : "STOP")
                      : (widget.selectedLanguage == 'Tamil' ? "தொடங்கு" : "START"),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }
}
