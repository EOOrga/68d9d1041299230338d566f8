import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String appName = 'CARRERAS ANTOINE';
const String supportEmail = 'support@carrerasantoine.com';
const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

void main() {
  runApp(const CarrerasAntoineApp());
}

class CarrerasAntoineApp extends StatelessWidget {
  const CarrerasAntoineApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF27F2F5);
    const secondary = Color(0xFFF527F2);
    const tertiary = Color(0xFFF2F527);
    const background = Color(0xFFF7F2E8);

    final baseScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,
          surface: const Color(0xFFFFFCF6),
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF1D1409),
          onSurface: const Color(0xFF17201D),
        );

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: baseScheme,
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: background,
          foregroundColor: Color(0xFF17201D),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: baseScheme.surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE4DED1)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD8D1C3)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFFFCF6),
          indicatorColor: secondary.withValues(alpha: 0.22),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
      home: const OperationsShell(),
    );
  }
}

enum OpsType {
  procurement,
  attendance,
  resource,
  incident;

  String get label {
    switch (this) {
      case OpsType.procurement:
        return 'Procurement';
      case OpsType.attendance:
        return 'Attendance';
      case OpsType.resource:
        return 'Resources';
      case OpsType.incident:
        return 'Incidents';
    }
  }

  IconData get icon {
    switch (this) {
      case OpsType.procurement:
        return Icons.inventory_2_outlined;
      case OpsType.attendance:
        return Icons.fact_check_outlined;
      case OpsType.resource:
        return Icons.precision_manufacturing_outlined;
      case OpsType.incident:
        return Icons.report_problem_outlined;
    }
  }
}

enum OpsStatus {
  open,
  scheduled,
  inProgress,
  resolved,
  closed;

  String get label {
    switch (this) {
      case OpsStatus.open:
        return 'Open';
      case OpsStatus.scheduled:
        return 'Scheduled';
      case OpsStatus.inProgress:
        return 'In progress';
      case OpsStatus.resolved:
        return 'Resolved';
      case OpsStatus.closed:
        return 'Closed';
    }
  }

  bool get active => this != OpsStatus.resolved && this != OpsStatus.closed;
}

enum OpsPriority {
  routine,
  important,
  urgent;

  String get label {
    switch (this) {
      case OpsPriority.routine:
        return 'Routine';
      case OpsPriority.important:
        return 'Important';
      case OpsPriority.urgent:
        return 'Urgent';
    }
  }
}

class OpsRecord {
  const OpsRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.owner,
    required this.location,
    required this.status,
    required this.priority,
    required this.quantity,
    required this.notes,
    required this.createdAt,
    required this.dueAt,
  });

  final String id;
  final OpsType type;
  final String title;
  final String owner;
  final String location;
  final OpsStatus status;
  final OpsPriority priority;
  final int quantity;
  final String notes;
  final DateTime createdAt;
  final DateTime dueAt;

  bool get isActive => status.active;

  OpsRecord copyWith({OpsStatus? status}) {
    return OpsRecord(
      id: id,
      type: type,
      title: title,
      owner: owner,
      location: location,
      status: status ?? this.status,
      priority: priority,
      quantity: quantity,
      notes: notes,
      createdAt: createdAt,
      dueAt: dueAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'owner': owner,
      'location': location,
      'status': status.name,
      'priority': priority.name,
      'quantity': quantity,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'dueAt': dueAt.toIso8601String(),
    };
  }

  factory OpsRecord.fromJson(Map<String, dynamic> json) {
    return OpsRecord(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: _enumByName(
        OpsType.values,
        json['type'] as String?,
        OpsType.procurement,
      ),
      title: json['title'] as String? ?? 'Untitled record',
      owner: json['owner'] as String? ?? 'Unassigned',
      location: json['location'] as String? ?? 'Main site',
      status: _enumByName(
        OpsStatus.values,
        json['status'] as String?,
        OpsStatus.open,
      ),
      priority: _enumByName(
        OpsPriority.values,
        json['priority'] as String?,
        OpsPriority.routine,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      dueAt:
          DateTime.tryParse(json['dueAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 1)),
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}

class OperationsController extends ChangeNotifier {
  static const _recordsKey = 'carreras_antoine_records_v1';
  static const _compactKey = 'carreras_antoine_compact_v1';

  SharedPreferences? _prefs;
  bool _loaded = false;
  bool _compactOverview = false;
  List<OpsRecord> _records = const [];

  bool get loaded => _loaded;
  bool get compactOverview => _compactOverview;
  List<OpsRecord> get records => List.unmodifiable(_records);

  Future<void> load() async {
    if (kScreenshotMode) {
      _records = _sampleRecords;
      _loaded = true;
      notifyListeners();
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    final encoded = _prefs?.getStringList(_recordsKey) ?? const <String>[];
    _records =
        encoded
            .map(
              (item) =>
                  OpsRecord.fromJson(jsonDecode(item) as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _compactOverview = _prefs?.getBool(_compactKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> addRecord(OpsRecord record) async {
    _records = [record, ..._records];
    notifyListeners();
    await _saveRecords();
  }

  Future<void> updateStatus(String id, OpsStatus status) async {
    _records = [
      for (final record in _records)
        if (record.id == id) record.copyWith(status: status) else record,
    ];
    notifyListeners();
    await _saveRecords();
  }

  Future<void> clearRecords() async {
    _records = const [];
    notifyListeners();
    if (!kScreenshotMode) {
      await _prefs?.remove(_recordsKey);
    }
  }

  Future<void> setCompactOverview(bool value) async {
    _compactOverview = value;
    notifyListeners();
    if (!kScreenshotMode) {
      await _prefs?.setBool(_compactKey, value);
    }
  }

  Future<void> _saveRecords() async {
    if (kScreenshotMode) {
      return;
    }
    final encoded = [
      for (final record in _records) jsonEncode(record.toJson()),
    ];
    await _prefs?.setStringList(_recordsKey, encoded);
  }
}

class OperationsShell extends StatefulWidget {
  const OperationsShell({super.key});

  @override
  State<OperationsShell> createState() => _OperationsShellState();
}

class _OperationsShellState extends State<OperationsShell> {
  late final OperationsController _controller;
  int _selectedIndex = 0;
  OpsType _draftType = OpsType.procurement;

  @override
  void initState() {
    super.initState();
    _controller = OperationsController()..addListener(_handleControllerChange);
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChange)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openNewRecord(OpsType type) {
    setState(() {
      _draftType = type;
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      DashboardScreen(
        records: _controller.records,
        compact: _controller.compactOverview,
        onCreate: _openNewRecord,
      ),
      WorkflowsScreen(
        records: _controller.records,
        onCreate: _openNewRecord,
        onStatusChanged: _controller.updateStatus,
      ),
      NewRecordScreen(
        key: ValueKey(_draftType),
        initialType: _draftType,
        onSave: (record) async {
          final messenger = ScaffoldMessenger.of(context);
          await _controller.addRecord(record);
          if (!mounted) {
            return;
          }
          setState(() => _selectedIndex = 1);
          messenger.showSnackBar(
            SnackBar(content: Text('${record.type.label} saved locally')),
          );
        },
      ),
      TeamScreen(records: _controller.records),
      SettingsScreen(
        compactOverview: _controller.compactOverview,
        recordCount: _controller.records.length,
        onCompactChanged: _controller.setCompactOverview,
        onClearRecords: _controller.clearRecords,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted_outlined),
            selectedIcon: Icon(Icons.format_list_bulleted),
            label: 'Workflows',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'New',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.records,
    required this.compact,
    required this.onCreate,
  });

  final List<OpsRecord> records;
  final bool compact;
  final ValueChanged<OpsType> onCreate;

  @override
  Widget build(BuildContext context) {
    final openProcurement = records
        .where(
          (record) => record.type == OpsType.procurement && record.isActive,
        )
        .length;
    final attendance = records
        .where((record) => record.type == OpsType.attendance && record.isActive)
        .length;
    final resources = records
        .where((record) => record.type == OpsType.resource && record.isActive)
        .length;
    final incidents = records
        .where((record) => record.type == OpsType.incident && record.isActive)
        .length;
    final urgent = records
        .where(
          (record) => record.priority == OpsPriority.urgent && record.isActive,
        )
        .toList();
    final focusRecords = (urgent.isEmpty ? records : urgent)
        .take(compact ? 2 : 4)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const BrandHeader(
          title: 'CARRERAS ANTOINE',
          subtitle:
              'Procurement, attendance, resources, and incidents in one local desk.',
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.22,
          children: [
            MetricCard(
              label: 'Procurement',
              value: '$openProcurement',
              icon: OpsType.procurement.icon,
              tint: const Color(0xFFB77736),
            ),
            MetricCard(
              label: 'Attendance',
              value: '$attendance',
              icon: OpsType.attendance.icon,
              tint: const Color(0xFF214B5B),
            ),
            MetricCard(
              label: 'Resources',
              value: '$resources',
              icon: OpsType.resource.icon,
              tint: const Color(0xFF3F6B4A),
            ),
            MetricCard(
              label: 'Incidents',
              value: '$incidents',
              icon: OpsType.incident.icon,
              tint: const Color(0xFFA54C35),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionTitle(
          title: 'Quick capture',
          action: TextButton.icon(
            onPressed: () => onCreate(OpsType.procurement),
            icon: const Icon(Icons.add),
            label: const Text('Request'),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in OpsType.values)
              FilledButton.tonalIcon(
                onPressed: () => onCreate(type),
                icon: Icon(type.icon),
                label: Text(type.label),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Priority focus'),
        const SizedBox(height: 8),
        if (focusRecords.isEmpty)
          EmptyState(
            icon: Icons.assignment_turned_in_outlined,
            title: 'No active records yet',
            body:
                'Create the first operational record to start tracking the day.',
            actionLabel: 'Add record',
            onAction: () => onCreate(OpsType.procurement),
          )
        else
          ...focusRecords.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordCard(record: record),
            ),
          ),
      ],
    );
  }
}

class WorkflowsScreen extends StatefulWidget {
  const WorkflowsScreen({
    super.key,
    required this.records,
    required this.onCreate,
    required this.onStatusChanged,
  });

  final List<OpsRecord> records;
  final ValueChanged<OpsType> onCreate;
  final Future<void> Function(String id, OpsStatus status) onStatusChanged;

  @override
  State<WorkflowsScreen> createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends State<WorkflowsScreen> {
  OpsType? _filter;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.records
        .where((record) => _filter == null || record.type == _filter)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        ScreenHeading(
          title: 'Operational records',
          subtitle:
              'Review open work, inspect details, and close items once handled.',
          action: IconButton.filledTonal(
            onPressed: () => widget.onCreate(_filter ?? OpsType.procurement),
            icon: const Icon(Icons.add),
            tooltip: 'Add record',
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              for (final type in OpsType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(type.icon, size: 18),
                    label: Text(type.label),
                    selected: _filter == type,
                    onSelected: (_) => setState(() => _filter = type),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          EmptyState(
            icon: Icons.rule_folder_outlined,
            title: 'No records in this view',
            body: 'Switch filters or create a local record for this workflow.',
            actionLabel: 'Create record',
            onAction: () => widget.onCreate(_filter ?? OpsType.procurement),
          )
        else
          ...filtered.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordCard(
                record: record,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RecordDetailPage(
                      record: record,
                      onStatusChanged: widget.onStatusChanged,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NewRecordScreen extends StatefulWidget {
  const NewRecordScreen({
    super.key,
    required this.initialType,
    required this.onSave,
  });

  final OpsType initialType;
  final Future<void> Function(OpsRecord record) onSave;

  @override
  State<NewRecordScreen> createState() => _NewRecordScreenState();
}

class _NewRecordScreenState extends State<NewRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _ownerController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  late OpsType _type;
  OpsStatus _status = OpsStatus.open;
  OpsPriority _priority = OpsPriority.important;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (kScreenshotMode) {
      _titleController.text = 'Restock safety kits';
      _ownerController.text = 'Operations desk';
      _locationController.text = 'Main warehouse';
      _quantityController.text = '24';
      _notesController.text =
          'Keep enough stock for field teams and site visitors.';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ownerController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const ScreenHeading(
          title: 'New local record',
          subtitle:
              'Capture an operational item without accounts, cloud sync, or network use.',
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<OpsType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Workflow'),
                items: [
                  for (final type in OpsType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 20),
                          const SizedBox(width: 8),
                          Text(type.label),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('record_title_field'),
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Restock safety kits',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('record_owner_field'),
                controller: _ownerController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Owner',
                  hintText: 'Operations desk',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Location or team',
                  hintText: 'Main warehouse',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OpsStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final status in OpsStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OpsPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: [
                  for (final priority in OpsPriority.values)
                    DropdownMenuItem(
                      value: priority,
                      child: Text(priority.label),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _priority = value ?? _priority),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity or headcount',
                  hintText: '1',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 1) {
                    return 'Enter a number above 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add operational context or next action',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('save_record_button'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save locally'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final dueAt = switch (_priority) {
      OpsPriority.urgent => now.add(const Duration(hours: 12)),
      OpsPriority.important => now.add(const Duration(days: 1)),
      OpsPriority.routine => now.add(const Duration(days: 3)),
    };
    final record = OpsRecord(
      id: now.microsecondsSinceEpoch.toString(),
      type: _type,
      title: _titleController.text.trim(),
      owner: _ownerController.text.trim(),
      location: _locationController.text.trim(),
      status: _status,
      priority: _priority,
      quantity: int.parse(_quantityController.text),
      notes: _notesController.text.trim(),
      createdAt: now,
      dueAt: dueAt,
    );
    await widget.onSave(record);
    if (mounted) {
      setState(() => _saving = false);
      if (!kScreenshotMode) {
        _formKey.currentState!.reset();
        _titleController.clear();
        _ownerController.clear();
        _locationController.clear();
        _quantityController.text = '1';
        _notesController.clear();
        _status = OpsStatus.open;
        _priority = OpsPriority.important;
      }
    }
  }
}

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key, required this.records});

  final List<OpsRecord> records;

  @override
  Widget build(BuildContext context) {
    final attendanceItems = records
        .where((record) => record.type == OpsType.attendance)
        .toList();
    final resourceItems = records
        .where((record) => record.type == OpsType.resource)
        .toList();
    final presentCount = attendanceItems
        .where((record) => record.status != OpsStatus.closed)
        .length;
    final allocatedCount = resourceItems
        .where((record) => record.status.active)
        .fold<int>(0, (total, record) => total + record.quantity);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const ScreenHeading(
          title: 'Team and assets',
          subtitle:
              'Track attendance coverage and resource load for the current day.',
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.25,
          children: [
            MetricCard(
              label: 'Attendance items',
              value: '$presentCount',
              icon: Icons.badge_outlined,
              tint: const Color(0xFF214B5B),
            ),
            MetricCard(
              label: 'Assets allocated',
              value: '$allocatedCount',
              icon: Icons.handyman_outlined,
              tint: const Color(0xFFB77736),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Coverage board'),
        const SizedBox(height: 8),
        ..._teamRows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TeamRow(
              name: row.$1,
              role: row.$2,
              state: row.$3,
              color: row.$4,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SectionTitle(title: 'Resource notes'),
        const SizedBox(height: 8),
        if (resourceItems.isEmpty)
          const EmptyState(
            icon: Icons.precision_manufacturing_outlined,
            title: 'No active allocation records',
            body:
                'Create a resource record when equipment, vehicles, or stock are assigned.',
          )
        else
          ...resourceItems
              .take(3)
              .map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RecordCard(record: record),
                ),
              ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.compactOverview,
    required this.recordCount,
    required this.onCompactChanged,
    required this.onClearRecords,
  });

  final bool compactOverview;
  final int recordCount;
  final ValueChanged<bool> onCompactChanged;
  final Future<void> Function() onClearRecords;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const ScreenHeading(
          title: 'Settings and privacy',
          subtitle: 'Local controls for the CARRERAS ANTOINE operations desk.',
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            value: compactOverview,
            onChanged: onCompactChanged,
            title: const Text('Compact overview'),
            subtitle: const Text(
              'Show fewer priority items on the first screen.',
            ),
            secondary: const Icon(Icons.view_agenda_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Local records'),
            subtitle: Text('$recordCount saved on this device'),
            trailing: OutlinedButton(
              onPressed: recordCount == 0
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear local records?'),
                          content: const Text(
                            'This removes the procurement, attendance, resource, and incident records stored by the app on this device.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await onClearRecords();
                      }
                    },
              child: const Text('Clear'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined),
                SizedBox(height: 10),
                Text(
                  'Privacy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'The app stores operational records and preferences locally on this device. It does not use accounts, analytics, advertising identifiers, cloud sync, location, contacts, photos, microphone input, or payment data.',
                ),
                SizedBox(height: 12),
                SelectableText(supportEmail),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({
    super.key,
    required this.record,
    required this.onStatusChanged,
  });

  final OpsRecord record;
  final Future<void> Function(String id, OpsStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(record.type.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          RecordCard(record: record),
          const SizedBox(height: 16),
          DetailRow(label: 'Owner', value: record.owner),
          DetailRow(label: 'Location or team', value: record.location),
          DetailRow(
            label: 'Quantity or headcount',
            value: '${record.quantity}',
          ),
          DetailRow(label: 'Created', value: dateLabel(record.createdAt)),
          DetailRow(label: 'Target', value: dateLabel(record.dueAt)),
          if (record.notes.isNotEmpty)
            DetailRow(label: 'Notes', value: record.notes),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Update status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in OpsStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: record.status == status,
                  onSelected: record.status == status
                      ? null
                      : (_) async {
                          await onStatusChanged(record.id, status);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF17322F),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'docs/icon.png',
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class ScreenHeading extends StatelessWidget {
  const ScreenHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        ?action,
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordCard extends StatelessWidget {
  const RecordCard({super.key, required this.record, this.onTap});

  final OpsRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (record.priority) {
      OpsPriority.urgent => const Color(0xFFA54C35),
      OpsPriority.important => const Color(0xFFB77736),
      OpsPriority.routine => const Color(0xFF3F6B4A),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      record.type.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record.owner} - ${record.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  LabelPill(
                    text: record.type.label,
                    icon: record.type.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  LabelPill(
                    text: record.status.label,
                    icon: Icons.sync_alt,
                    color: record.isActive
                        ? Theme.of(context).colorScheme.tertiary
                        : const Color(0xFF68736E),
                  ),
                  LabelPill(
                    text: record.priority.label,
                    icon: Icons.flag_outlined,
                    color: priorityColor,
                  ),
                  LabelPill(
                    text: shortDateLabel(record.dueAt),
                    icon: Icons.event_outlined,
                    color: const Color(0xFF4B5F58),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LabelPill extends StatelessWidget {
  const LabelPill({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TeamRow extends StatelessWidget {
  const TeamRow({
    super.key,
    required this.name,
    required this.role,
    required this.state,
    required this.color,
  });

  final String name;
  final String role;
  final String state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          foregroundColor: color,
          child: Text(name.characters.first),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(role),
        trailing: LabelPill(text: state, icon: Icons.circle, color: color),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

String dateLabel(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

String shortDateLabel(DateTime date) {
  return '${_monthNames[date.month - 1].substring(0, 3)} ${date.day}';
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

final _sampleRecords = [
  OpsRecord(
    id: 'sample-001',
    type: OpsType.procurement,
    title: 'Approve supplier purchase order',
    owner: 'Nadia B.',
    location: 'Procurement desk',
    status: OpsStatus.inProgress,
    priority: OpsPriority.urgent,
    quantity: 3,
    notes:
        'Review three supplier quotes and release the purchase order before noon.',
    createdAt: DateTime(2026, 5, 12, 8, 10),
    dueAt: DateTime(2026, 5, 12, 12, 0),
  ),
  OpsRecord(
    id: 'sample-002',
    type: OpsType.attendance,
    title: 'Morning attendance rollup',
    owner: 'Karim E.',
    location: 'Field teams',
    status: OpsStatus.scheduled,
    priority: OpsPriority.important,
    quantity: 18,
    notes: 'Confirm late arrivals and record the supervisor handoff.',
    createdAt: DateTime(2026, 5, 12, 7, 45),
    dueAt: DateTime(2026, 5, 12, 10, 30),
  ),
  OpsRecord(
    id: 'sample-003',
    type: OpsType.resource,
    title: 'Allocate service vehicles',
    owner: 'Youssef M.',
    location: 'North yard',
    status: OpsStatus.open,
    priority: OpsPriority.important,
    quantity: 5,
    notes:
        'Assign vehicles to scheduled calls and keep one spare for incident response.',
    createdAt: DateTime(2026, 5, 11, 16, 20),
    dueAt: DateTime(2026, 5, 12, 11, 0),
  ),
  OpsRecord(
    id: 'sample-004',
    type: OpsType.incident,
    title: 'Loading bay obstruction',
    owner: 'Amal R.',
    location: 'Bay 2',
    status: OpsStatus.inProgress,
    priority: OpsPriority.urgent,
    quantity: 1,
    notes:
        'Move stored material away from the marked walkway and record resolution.',
    createdAt: DateTime(2026, 5, 12, 9, 5),
    dueAt: DateTime(2026, 5, 12, 13, 0),
  ),
  OpsRecord(
    id: 'sample-005',
    type: OpsType.procurement,
    title: 'Restock safety gloves',
    owner: 'Sofia T.',
    location: 'Main warehouse',
    status: OpsStatus.open,
    priority: OpsPriority.routine,
    quantity: 80,
    notes: 'Keep minimum stock ready for visitor and maintenance teams.',
    createdAt: DateTime(2026, 5, 10, 14, 10),
    dueAt: DateTime(2026, 5, 14, 17, 0),
  ),
];

const _teamRows = [
  ('Nadia B.', 'Procurement lead', 'Active', Color(0xFF3F6B4A)),
  ('Karim E.', 'Attendance coordinator', 'Checking', Color(0xFF214B5B)),
  ('Youssef M.', 'Resource planner', 'Allocated', Color(0xFFB77736)),
  ('Amal R.', 'Incident owner', 'Resolving', Color(0xFFA54C35)),
];
