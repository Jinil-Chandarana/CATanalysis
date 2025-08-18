import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';
import 'package:catalyst_app/theme/app_colors.dart';

// (Helper classes are unchanged)
class RcSetControllers {
  final TextEditingController questions = TextEditingController();
  final TextEditingController correct = TextEditingController();
  Difficulty difficulty = Difficulty.medium;
}

class VaSetControllers {
  final TextEditingController attempted = TextEditingController();
  final TextEditingController correct = TextEditingController();
  String? topic;
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
  final Duration focusDuration;

  const SessionForm({
    super.key,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.focusDuration,
  });

  @override
  ConsumerState<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<SessionForm> {
  // (State variables and controllers are unchanged)
  final _formKey = GlobalKey<FormState>();
  final List<RcSetControllers> _rcSets = [];
  final List<VaSetControllers> _vaSets = [];
  final List<String> _vaTopics = const [
    'Para Completion',
    'Para Jumbles',
    'Odd Sentence',
    'Summary',
  ];
  final List<LrdiSetControllers> _lrdiSets = [];
  final TextEditingController _qaAttemptedController = TextEditingController();
  final TextEditingController _qaCorrectController = TextEditingController();
  String? _selectedQaTopic;
  final List<String> _qaTopics = const [
    'Arithmetic',
    'Algebra',
    'Geometry',
    'Modern Math',
    'Number System',
  ];
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isForReview = false;

  // (initState, dispose, add/remove methods are unchanged)
  @override
  void initState() {
    super.initState();
    if (widget.subject == Subject.varc) {
      _addRcSet();
      _addVaSet();
    }
    if (widget.subject == Subject.lrdi) {
      _addLrdiSet();
    }
  }

  @override
  void dispose() {
    _rcSets.forEach((c) {
      c.questions.dispose();
      c.correct.dispose();
    });
    _vaSets.forEach((c) {
      c.attempted.dispose();
      c.correct.dispose();
    });
    _lrdiSets.forEach((c) {
      c.questions.dispose();
      c.correct.dispose();
    });
    _qaAttemptedController.dispose();
    _qaCorrectController.dispose();
    _taskNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addRcSet() => setState(() => _rcSets.add(RcSetControllers()));
  void _removeRcSet(int index) => setState(() => _rcSets.removeAt(index));
  void _addVaSet() => setState(() => _vaSets.add(VaSetControllers()));
  void _removeVaSet(int index) => setState(() => _vaSets.removeAt(index));
  void _addLrdiSet() => setState(() => _lrdiSets.add(LrdiSetControllers()));
  void _removeLrdiSet(int index) => setState(() => _lrdiSets.removeAt(index));

  // (_saveSession method is unchanged)
  void _saveSession() {
    int getInt(TextEditingController controller) =>
        int.tryParse(controller.text) ?? 0;
    if (_formKey.currentState!.validate()) {
      if (widget.subject == Subject.qa && _selectedQaTopic == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a QA topic.')));
        return;
      }
      for (final vaSet in _vaSets) {
        if (getInt(vaSet.attempted) > 0 && vaSet.topic == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please select a topic for each VA set.')));
          return;
        }
      }
      final metrics = <String, dynamic>{};
      final seatingDuration = widget.endTime.difference(widget.startTime);
      switch (widget.subject) {
        case Subject.varc:
          metrics['rc_sets'] = _rcSets
              .map((c) => {
                    'questions': getInt(c.questions),
                    'correct': getInt(c.correct),
                    'difficulty': c.difficulty.index
                  })
              .toList();
          metrics['va_sets'] = _vaSets
              .where((c) => getInt(c.attempted) > 0)
              .map((c) => {
                    'attempted': getInt(c.attempted),
                    'correct': getInt(c.correct),
                    'topic': c.topic
                  })
              .toList();
          break;
        case Subject.lrdi:
          metrics['lrdi_sets'] = _lrdiSets
              .map((c) => {
                    'questions': getInt(c.questions),
                    'correct': getInt(c.correct),
                    'is_solo': c.isSolo,
                    'difficulty': c.difficulty.index
                  })
              .toList();
          break;
        case Subject.qa:
          metrics['questionsAttempted'] = getInt(_qaAttemptedController);
          metrics['questionsCorrect'] = getInt(_qaCorrectController);
          metrics['tags'] = [_selectedQaTopic!];
          break;
        case Subject.misc:
          metrics['task_name'] = _taskNameController.text.trim();
          break;
      }
      metrics['notes'] = _notesController.text;
      metrics['is_for_review'] = _isForReview;
      final newSession = StudySession(
        id: const Uuid().v4(),
        subject: widget.subject,
        startTime: widget.startTime,
        endTime: widget.endTime,
        focusDuration: widget.focusDuration,
        seatingDuration: seatingDuration,
        metrics: metrics,
      );
      ref.read(sessionProvider.notifier).addSession(newSession);
      Navigator.of(context).pop();
    }
  }

  // (build method is unchanged)
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildFormFields(),
          const SizedBox(height: 16),
          Card(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _buildGlobalFields())),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSession,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Session', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // --- THIS SECTION IS UPDATED ---
  List<Widget> _buildFormFields() {
    switch (widget.subject) {
      case Subject.varc:
        return _buildVarcForm();
      case Subject.lrdi:
        return _buildLrdiForm();
      case Subject.qa:
        return _buildQaForm();
      case Subject.misc:
        return _buildMiscForm();
    }
  }

  List<Widget> _buildVarcForm() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Reading Comprehension",
                  style: Theme.of(context).textTheme.titleLarge),
              ..._rcSets.asMap().entries.map((entry) {
                return _buildSetSubCard(
                  index: entry.key,
                  title: "RC Set ${entry.key + 1}",
                  onRemove: () => _removeRcSet(entry.key),
                  children: [
                    _buildDifficultySelector(
                        (d) =>
                            setState(() => _rcSets[entry.key].difficulty = d),
                        _rcSets[entry.key].difficulty),
                    _buildTextField(
                        _rcSets[entry.key].questions, 'Number of Questions'),
                    _buildTextField(
                        _rcSets[entry.key].correct, 'Number Correct'),
                  ],
                );
              }).toList(),
              TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add RC Set"),
                  onPressed: _addRcSet),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Verbal Ability",
                  style: Theme.of(context).textTheme.titleLarge),
              ..._vaSets.asMap().entries.map((entry) {
                return _buildSetSubCard(
                  index: entry.key,
                  title: "VA Set ${entry.key + 1}",
                  onRemove: () => _removeVaSet(entry.key),
                  children: [
                    _buildTextField(
                        _vaSets[entry.key].attempted, 'Number Attempted'),
                    _buildTextField(
                        _vaSets[entry.key].correct, 'Number Correct'),
                    const SizedBox(height: 16),
                    Text("Topic",
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    // --- THIS IS THE FIX: Replaced Dropdown with ChoiceChip grid ---
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _vaTopics.map((topic) {
                        return ChoiceChip(
                          label: Text(topic),
                          selected: _vaSets[entry.key].topic == topic,
                          onSelected: (isSelected) {
                            setState(() {
                              if (isSelected) {
                                _vaSets[entry.key].topic = topic;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                );
              }).toList(),
              TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add VA Set"),
                  onPressed: _addVaSet),
            ],
          ),
        ),
      ),
    ];
  }

  // (The rest of the file is unchanged.)

  List<Widget> _buildLrdiForm() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("LRDI Sets", style: Theme.of(context).textTheme.titleLarge),
              ..._lrdiSets.asMap().entries.map((entry) {
                return _buildSetSubCard(
                  index: entry.key,
                  title: "LRDI Set ${entry.key + 1}",
                  onRemove: () => _removeLrdiSet(entry.key),
                  children: [
                    _buildDifficultySelector(
                        (d) =>
                            setState(() => _lrdiSets[entry.key].difficulty = d),
                        _lrdiSets[entry.key].difficulty),
                    _buildTextField(
                        _lrdiSets[entry.key].questions, 'Number of Questions'),
                    _buildTextField(
                        _lrdiSets[entry.key].correct, 'Number Correct'),
                    CheckboxListTile(
                      title: const Text("Solved on your own?"),
                      value: _lrdiSets[entry.key].isSolo,
                      onChanged: (val) =>
                          setState(() => _lrdiSets[entry.key].isSolo = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                );
              }).toList(),
              TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add LRDI Set"),
                  onPressed: _addLrdiSet),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildQaForm() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Questions", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _buildTextField(_qaAttemptedController, 'Number Attempted'),
              _buildTextField(_qaCorrectController, 'Number Correct'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Topic", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _qaTopics.map((topic) {
                  return ChoiceChip(
                    label: Text(topic),
                    selected: _selectedQaTopic == topic,
                    onSelected: (isSelected) => setState(
                        () => isSelected ? _selectedQaTopic = topic : null),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMiscForm() {
    return [
      Card(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTextField(
                  _taskNameController, 'Task Name (e.g. Read Article)',
                  isNumeric: false)))
    ];
  }

  Widget _buildGlobalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_notesController, 'Notes / Analysis (Optional)',
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

  Widget _buildSetSubCard(
      {required int index,
      required String title,
      required VoidCallback onRemove,
      required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12)),
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
    );
  }

  Widget _buildDifficultySelector(
      Function(Difficulty) onSelectionChanged, Difficulty groupValue) {
    return Wrap(
      spacing: 8.0,
      children: Difficulty.values.map((d) {
        return ChoiceChip(
          label: Text(d.name),
          selected: groupValue == d,
          onSelected: (isSelected) {
            if (isSelected) {
              onSelectionChanged(d);
            }
          },
        );
      }).toList(),
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
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty))
            return 'Please enter a value';
          return null;
        },
      ),
    );
  }
}
