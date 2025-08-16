import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';

// Helper classes now include difficulty
class RcSetControllers {
  final TextEditingController questions = TextEditingController();
  final TextEditingController correct = TextEditingController();
  Difficulty difficulty = Difficulty.medium;
}

class LrdiSetControllers {
  final TextEditingController questions = TextEditingController();
  final TextEditingController correct = TextEditingController();
  bool isSolo = false;
  Difficulty difficulty = Difficulty.medium;
}

class SessionForm extends ConsumerStatefulWidget {
  final Subject subject;
  final DateTime startTime;
  final DateTime endTime;

  const SessionForm({
    super.key,
    required this.subject,
    required this.startTime,
    required this.endTime,
  });

  @override
  ConsumerState<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<SessionForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for VARC
  final List<RcSetControllers> _rcSets = [];
  final TextEditingController _vaAttemptedController = TextEditingController();
  final TextEditingController _vaCorrectController = TextEditingController();

  // Controllers for LRDI
  final List<LrdiSetControllers> _lrdiSets = [];

  // Controllers for QA
  final TextEditingController _qaAttemptedController = TextEditingController();
  final TextEditingController _qaCorrectController = TextEditingController();
  final TextEditingController _qaTagsController = TextEditingController();

  // Controllers for new global features
  final TextEditingController _notesController = TextEditingController();
  bool _isForReview = false;

  @override
  void initState() {
    super.initState();
    if (widget.subject == Subject.varc) _addRcSet();
    if (widget.subject == Subject.lrdi) _addLrdiSet();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var set in _rcSets) {
      set.questions.dispose();
      set.correct.dispose();
    }
    _vaAttemptedController.dispose();
    _vaCorrectController.dispose();
    for (var set in _lrdiSets) {
      set.questions.dispose();
      set.correct.dispose();
    }
    _qaAttemptedController.dispose();
    _qaCorrectController.dispose();
    _qaTagsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addRcSet() => setState(() => _rcSets.add(RcSetControllers()));
  void _removeRcSet(int index) => setState(() => _rcSets.removeAt(index));

  void _addLrdiSet() => setState(() => _lrdiSets.add(LrdiSetControllers()));
  void _removeLrdiSet(int index) => setState(() => _lrdiSets.removeAt(index));

  void _saveSession() {
    if (_formKey.currentState!.validate()) {
      final metrics = <String, dynamic>{};
      final duration = widget.endTime.difference(widget.startTime);

      int getInt(TextEditingController controller) =>
          int.tryParse(controller.text) ?? 0;

      // Save data based on subject
      switch (widget.subject) {
        case Subject.varc:
          metrics['rc_sets'] = _rcSets
              .map((c) => {
                    'questions': getInt(c.questions),
                    'correct': getInt(c.correct),
                    'difficulty': c.difficulty.index, // Save difficulty
                  })
              .toList();
          metrics['va_attempted'] = getInt(_vaAttemptedController);
          metrics['va_correct'] = getInt(_vaCorrectController);
          break;
        case Subject.lrdi:
          metrics['lrdi_sets'] = _lrdiSets
              .map((c) => {
                    'questions': getInt(c.questions),
                    'correct': getInt(c.correct),
                    'is_solo': c.isSolo,
                    'difficulty': c.difficulty.index, // Save difficulty
                  })
              .toList();
          break;
        case Subject.qa:
          metrics['questionsAttempted'] = getInt(_qaAttemptedController);
          metrics['questionsCorrect'] = getInt(_qaCorrectController);
          // Save tags
          metrics['tags'] = _qaTagsController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          break;
      }

      // Save global feature data
      metrics['notes'] = _notesController.text;
      metrics['is_for_review'] = _isForReview;

      final newSession = StudySession(
        id: const Uuid().v4(),
        subject: widget.subject,
        startTime: widget.startTime,
        endTime: widget.endTime,
        duration: duration,
        metrics: metrics,
      );

      ref.read(sessionProvider.notifier).addSession(newSession);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildFormFields(),
          const Divider(height: 40),
          _buildGlobalFields(), // Notes and Review Flag
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSession,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Save Session', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    switch (widget.subject) {
      case Subject.varc:
        return _buildVarcForm();
      case Subject.lrdi:
        return _buildLrdiForm();
      case Subject.qa:
        return _buildQaForm();
    }
  }

  // --- FORM BUILDERS ---
  List<Widget> _buildVarcForm() {
    return [
      Text("Reading Comprehension",
          style: Theme.of(context).textTheme.titleLarge),
      ..._rcSets.asMap().entries.map((entry) {
        int index = entry.key;
        RcSetControllers controllers = entry.value;
        return _buildSetCard(
          index: index,
          title: "RC Set ${index + 1}",
          onRemove: () => _removeRcSet(index),
          children: [
            _buildDifficultySelector((newDifficulty) {
              setState(() => controllers.difficulty = newDifficulty);
            }, controllers.difficulty),
            _buildTextField(controllers.questions, 'Number of Questions'),
            _buildTextField(controllers.correct, 'Number Correct'),
          ],
        );
      }).toList(),
      TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add RC Set"),
          onPressed: _addRcSet),
      const Divider(height: 40),
      Text("Verbal Ability", style: Theme.of(context).textTheme.titleLarge),
      _buildTextField(_vaAttemptedController, 'Number of VA Questions Done'),
      _buildTextField(_vaCorrectController, 'VA Questions Correct'),
    ];
  }

  List<Widget> _buildLrdiForm() {
    return [
      Text("LRDI Sets", style: Theme.of(context).textTheme.titleLarge),
      ..._lrdiSets.asMap().entries.map((entry) {
        int index = entry.key;
        LrdiSetControllers controllers = entry.value;
        return _buildSetCard(
          index: index,
          title: "LRDI Set ${index + 1}",
          onRemove: () => _removeLrdiSet(index),
          children: [
            _buildDifficultySelector((newDifficulty) {
              setState(() => controllers.difficulty = newDifficulty);
            }, controllers.difficulty),
            _buildTextField(controllers.questions, 'Number of Questions'),
            _buildTextField(controllers.correct, 'Number Correct'),
            StatefulBuilder(builder: (context, setCheckboxState) {
              return CheckboxListTile(
                title: const Text("Solved on your own?"),
                value: controllers.isSolo,
                onChanged: (val) =>
                    setCheckboxState(() => controllers.isSolo = val!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        );
      }).toList(),
      TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add LRDI Set"),
          onPressed: _addLrdiSet),
    ];
  }

  List<Widget> _buildQaForm() {
    return [
      _buildTextField(_qaAttemptedController, 'Number of Questions Attempted'),
      _buildTextField(_qaCorrectController, 'Number of Questions Correct'),
      _buildTextField(
        _qaTagsController,
        'Topics (e.g. Algebra, Geometry)',
        isNumeric: false,
      ),
    ];
  }

  Widget _buildGlobalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_notesController, 'Notes / Mistake Analysis (Optional)',
            isNumeric: false, isRequired: false),
        CheckboxListTile(
          title: const Text("Flag for Later Review"),
          value: _isForReview,
          onChanged: (val) => setState(() => _isForReview = val!),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // --- REUSABLE WIDGETS ---
  Widget _buildSetCard(
      {required int index,
      required String title,
      required VoidCallback onRemove,
      required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (index > 0)
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onRemove,
                      visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector(
      Function(Difficulty) onSelectionChanged, Difficulty groupValue) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: SegmentedButton<Difficulty>(
        segments: const [
          ButtonSegment(value: Difficulty.easy, label: Text('Easy')),
          ButtonSegment(value: Difficulty.medium, label: Text('Medium')),
          ButtonSegment(value: Difficulty.hard, label: Text('Hard')),
        ],
        selected: {groupValue},
        onSelectionChanged: (newSelection) {
          onSelectionChanged(newSelection.first);
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumeric = true, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters:
            isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please enter a value';
          }
          return null;
        },
      ),
    );
  }
}
