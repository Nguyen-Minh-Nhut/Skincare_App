import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'health_page.dart';

class CareRoutineModel extends ChangeNotifier {
  CareRoutineModel({required String userId})
    : _key = 'care_routine_v1_$userId' {
    _load();
  }
  final String _key;
  final tasks = <List<String>>[
    ['Làm sạch dịu nhẹ', 'Dưỡng ẩm', 'Chống nắng'],
    ['Làm sạch dịu nhẹ', 'Dưỡng ẩm', 'Chăm sóc buổi tối'],
  ];
  final completed = <Set<int>>[{}, {}];
  bool loading = true;
  bool saving = false;
  bool _disposed = false;
  String _day = _today();
  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final stored = (data['tasks'] as List)
            .map((list) => List<String>.from(list as List))
            .toList();
        if (stored.length == 2) {
          for (var i = 0; i < 2; i++) {
            tasks[i] = stored[i];
          }
          if (data['day'] == _day) {
            final done = data['done'] as List;
            for (var i = 0; i < 2; i++) {
              completed[i].addAll(
                List<int>.from(
                  done[i] as List,
                ).where((index) => index >= 0 && index < tasks[i].length),
              );
            }
          }
        }
      }
    } catch (_) {
      /* Keep usable defaults if local preferences are damaged. */
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _key,
      jsonEncode({
        'tasks': tasks,
        'done': completed.map((s) => s.toList()).toList(),
        'day': _day,
      }),
    )) {
      throw StateError('Could not save routine');
    }
  }

  Future<void> toggle(int period, int index) async {
    if (loading || saving) return;
    if (_day != _today()) {
      _day = _today();
      for (final set in completed) {
        set.clear();
      }
    }
    final old = Set<int>.from(completed[period]);
    completed[period].contains(index)
        ? completed[period].remove(index)
        : completed[period].add(index);
    saving = true;
    notifyListeners();
    try {
      await _persist();
    } catch (_) {
      completed[period] = old;
      rethrow;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> updateTasks(int period, List<String> values) async {
    if (loading || saving) return;
    final old = tasks[period];
    final oldDone = completed[period];
    tasks[period] = values;
    completed[period] = {};
    saving = true;
    notifyListeners();
    try {
      await _persist();
    } catch (_) {
      tasks[period] = old;
      completed[period] = oldDone;
      rethrow;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class CareRoutineCard extends StatefulWidget {
  const CareRoutineCard({
    super.key,
    required this.isEnglish,
    this.compact = false,
    this.onOpenCare,
  });
  final bool isEnglish;
  final bool compact;
  final VoidCallback? onOpenCare;
  @override
  State<CareRoutineCard> createState() => _CareRoutineCardState();
}

class _CareRoutineCardState extends State<CareRoutineCard> {
  int period = 0;
  String _name(String name) => !widget.isEnglish
      ? name
      : switch (name) {
          'Làm sạch dịu nhẹ' => 'Gentle cleansing',
          'Dưỡng ẩm' => 'Moisturize',
          'Chống nắng' => 'Sun protection',
          'Chăm sóc buổi tối' => 'Evening care',
          _ => name,
        };
  Future<void> _edit(CareRoutineModel model) async {
    final controller = TextEditingController(
      text: model.tasks[period].join('\n'),
    );
    final values = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.isEnglish ? 'Edit routine' : 'Chỉnh thói quen'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: widget.isEnglish
                ? 'One step per line'
                : 'Mỗi bước một dòng',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.isEnglish ? 'Cancel' : 'Hủy'),
          ),
          TextButton(
            onPressed: () {
              final lines = controller.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .take(15)
                  .toList();
              Navigator.pop(ctx, lines);
            },
            child: Text(widget.isEnglish ? 'Save' : 'Lưu'),
          ),
        ],
      ),
    );
    // Let the dialog's closing animation finish before disposing its controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (values == null || !mounted) return;
    try {
      await model.updateTasks(period, values);
    } catch (_) {
      _error();
    }
  }

  void _error() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Could not save. Please retry.'
                : 'Chưa lưu được. Vui lòng thử lại.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CareRoutineModel>();
    final en = widget.isEnglish;
    final color = Theme.of(context).colorScheme.primary;
    return HealthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_twilight_outlined, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  en ? 'Your routine' : 'Thói quen của bạn',
                  style: TextStyle(
                    fontSize: 15,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!widget.compact)
                IconButton(
                  tooltip: en ? 'Edit routine' : 'Chỉnh thói quen',
                  onPressed: model.loading || model.saving
                      ? null
                      : () => _edit(model),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2B2C3B)
                  : const Color(0xFFF3F3F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: List.generate(
                2,
                (i) => Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => setState(() => period = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: period == i
                            ? Theme.of(context).colorScheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          en
                              ? ['Morning', 'Evening'][i]
                              : ['Buổi sáng', 'Buổi tối'][i],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (model.loading) const LinearProgressIndicator(),
          if (!widget.compact)
            ...List.generate(
              model.tasks[period].length,
              (i) => InkWell(
                onTap: model.loading || model.saving
                    ? null
                    : () async {
                        try {
                          await model.toggle(period, i);
                        } catch (_) {
                          _error();
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        model.completed[period].contains(i)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: model.completed[period].contains(i)
                            ? color
                            : Colors.grey.shade400,
                        size: 25,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _name(model.tasks[period][i]),
                          style: TextStyle(
                            fontSize: 15,
                            color: model.completed[period].contains(i)
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        (i + 1).toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.compact) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: model.tasks[period].isEmpty
                  ? 0
                  : model.completed[period].length / model.tasks[period].length,
            ),
            const SizedBox(height: 12),
            Text(
              en
                  ? 'Open Care to check off or edit your steps.'
                  : 'Vào Chăm sóc để đánh dấu hoặc chỉnh các bước.',
            ),
            TextButton(
              onPressed: widget.onOpenCare,
              child: Text(en ? 'Open Care' : 'Mở Chăm sóc'),
            ),
          ],
          const Divider(height: 22),
          Text(
            '${model.completed[period].length} / ${model.tasks[period].length} ${en ? 'steps completed' : 'bước hoàn thành'}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
