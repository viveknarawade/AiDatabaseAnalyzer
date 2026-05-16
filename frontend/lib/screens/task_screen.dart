import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _scrollCtrl = ScrollController();
  String _filterStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<TaskProvider>().fetchMoreTasks();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<TaskProvider>().fetchTasks(refresh: true);
  }

  // ─── Filter tasks client-side ───────────────────────────────
  List<Task> _filtered(List<Task> tasks) {
    if (_filterStatus == 'ALL') return tasks;
    return tasks.where((t) => t.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final tasks = _filtered(taskProv.tasks);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildFilterBar(),
            Expanded(
              child: taskProv.isInitialLoading
                  ? _buildShimmer()
                  : taskProv.status == TaskStatus.error
                  ? _buildErrorState(taskProv.errorMessage)
                  : tasks.isEmpty
                  ? _buildEmptyState()
                  : _buildList(tasks, taskProv),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          // ── Logo ──
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5CFC), Color(0xFF5B8DFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // ── Title ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${taskProv.tasks.length} tasks',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

          // ── More options menu ──
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white54,
              size: 22,
            ),
            color: const Color(0xFF1E1C2E),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            offset: const Offset(0, 48),
            onSelected: (value) {
              if (value == 'logout') _confirmLogout(context);
              if (value == 'delete_account') _confirmDeleteAccount(context);
            },
            itemBuilder: (_) => [
              // ── Sign out ──
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Log out of your account',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Divider ──
              const PopupMenuDivider(height: 1),

              // ── Delete account ──
              PopupMenuItem<String>(
                value: 'delete_account',
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_remove_outlined,
                        color: Color(0xFFFF6B6B),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete Account',
                          style: TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Permanently remove account',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // // App Bar
  // Widget _buildAppBar(BuildContext context) {
  //   final taskProv = context.watch<TaskProvider>();
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 40,
  //           height: 40,
  //           decoration: BoxDecoration(
  //             gradient: const LinearGradient(
  //               colors: [Color(0xFF7C5CFC), Color(0xFF5B8DFC)],
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //             ),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: const Icon(
  //             Icons.task_alt_rounded,
  //             color: Colors.white,
  //             size: 22,
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 'My Tasks',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 20,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               Text(
  //                 '${taskProv.tasks.length} tasks',
  //                 style: const TextStyle(color: Colors.white38, fontSize: 12),
  //               ),
  //             ],
  //           ),
  //         ),
  //         IconButton(
  //           icon: const Icon(
  //             Icons.logout_rounded,
  //             color: Colors.white54,
  //             size: 22,
  //           ),
  //           onPressed: () => _confirmLogout(context),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Filter chips
  Widget _buildFilterBar() {
    const filters = ['ALL', 'TODO', 'IN_PROGRESS', 'COMPLETED'];
    const labels = {
      'ALL': 'All',
      'TODO': 'To Do',
      'IN_PROGRESS': 'In Progress',
      'COMPLETED': 'Completed',
    };

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final selected = _filterStatus == f;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF7C5CFC)
                    : const Color(0xFF1E1C2E),
                borderRadius: BorderRadius.circular(20),
                border: selected ? null : Border.all(color: Colors.white12),
              ),
              child: Text(
                labels[f]!,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Task list
  Widget _buildList(List<Task> tasks, TaskProvider taskProv) {
    return RefreshIndicator(
      color: const Color(0xFF7C5CFC),
      backgroundColor: const Color(0xFF1E1C2E),
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: tasks.length + (taskProv.isFetchingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == tasks.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF7C5CFC),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            );
          }

          final task = tasks[i];
          return TaskCard(
            key: ValueKey(task.id),
            task: task,
            onEdit: () => _showTaskDialog(context, task: task),
            onDelete: () => _confirmDelete(context, task),
          );
        },
      ),
    );
  }

  // Shimmer skeleton
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E1C2E),
      highlightColor: const Color(0xFF2A2838),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1C2E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: Colors.white24,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No tasks yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to create your first task',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Error state
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFFF6B6B),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C5CFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // FAB
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5CFC), Color(0xFF5B8DFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C5CFC).withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Create / Edit dialog
  void _showTaskDialog(BuildContext context, {Task? task}) {
    final isEdit = task != null;

    final titleCtrl = TextEditingController(text: task?.title ?? '');

    final descCtrl = TextEditingController(text: task?.description ?? '');

    String status = task?.status ?? 'TODO';

    String priority = task?.priority ?? 'MEDIUM';

    DateTime? dueDate = task?.dueDate.isNotEmpty == true
        ? DateTime.parse(task!.dueDate)
        : null;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1828),

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,

              bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
            ),

            child: Form(
              key: formKey,

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  _modalField(
                    controller: titleCtrl,

                    label: "Title",

                    icon: Icons.title,

                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Title required";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  _modalField(
                    controller: descCtrl,

                    label: "Description",

                    icon: Icons.notes,

                    maxLines: 3,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _modalDropdown(
                          label: "Status",

                          value: status,

                          items: const ['TODO', 'IN_PROGRESS', 'COMPLETED'],

                          labels: const {
                            'TODO': 'To Do',

                            'IN_PROGRESS': 'In Progress',

                            'COMPLETED': 'Completed',
                          },

                          onChanged: (v) {
                            setModal(() {
                              status = v!;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _modalDropdown(
                          label: "Priority",

                          value: priority,

                          items: const ['LOW', 'MEDIUM', 'HIGH'],

                          labels: const {
                            'LOW': 'Low',

                            'MEDIUM': 'Medium',

                            'HIGH': 'High',
                          },

                          onChanged: (v) {
                            setModal(() {
                              priority = v!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,

                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),

                        firstDate: DateTime.now(),

                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {
                        setModal(() {
                          dueDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            23,
                            59,
                          );
                        });
                      }
                    },

                    child: Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0E17),

                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,

                            color: Colors.white54,
                          ),

                          const SizedBox(width: 12),

                          Text(
                            dueDate == null
                                ? "Select Due Date"
                                : "${dueDate!.day}/${dueDate!.month}/${dueDate!.year}",

                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C5CFC), Color(0xFF5B8DFC)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          if (dueDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Select due date")),
                            );

                            return;
                          }

                          final data = {
                            'title': titleCtrl.text.trim(),

                            'description': descCtrl.text.trim(),

                            'status': status,

                            'priority': priority,

                            'dueDate': dueDate!.toUtc().toIso8601String(),
                          };

                          String? error;

                          if (isEdit) {
                            error = await context
                                .read<TaskProvider>()
                                .updateTask(task!.id, data);
                          } else {
                            error = await context
                                .read<TaskProvider>()
                                .createTask(data);
                          }

                          if (!mounted) return;

                          Navigator.pop(ctx);

                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        child: Text(
                          isEdit ? 'Save Changes' : 'Create Task',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _modalField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    validator: validator,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: const Color(0xFF0F0E17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C5CFC), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
    ),
  );

  Widget _modalDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Map<String, String> labels,
    required ValueChanged<String?> onChanged,
  }) => DropdownButtonFormField<String>(
    value: value,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF0F0E17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C5CFC), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    dropdownColor: const Color(0xFF1E1C2E),
    style: const TextStyle(color: Colors.white, fontSize: 14),
    icon: const Icon(
      Icons.keyboard_arrow_down_rounded,
      color: Colors.white38,
      size: 20,
    ),
    items: items
        .map((e) => DropdownMenuItem(value: e, child: Text(labels[e] ?? e)))
        .toList(),
    onChanged: onChanged,
  );

  // Dialogs
  void _confirmDelete(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await context.read<TaskProvider>().deleteTask(
                task.id,
              );
              if (!mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              context.read<TaskProvider>().reset();
              await context.read<AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C5CFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1A1828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          // ── Icon header ──
          title: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_remove_outlined,
                  color: Color(0xFFFF6B6B),
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete your account and all your tasks. This action cannot be undone.',
                style: TextStyle(color: Colors.white54, height: 1.5),
              ),
              const SizedBox(height: 20),

              // ── Warning chips ──
              Row(
                children: [
                  _warnChip(Icons.task_outlined, 'All tasks'),
                  const SizedBox(width: 8),
                  _warnChip(Icons.history, 'Activity'),
                ],
              ),
              const SizedBox(height: 20),

              // ── Confirm typed input ──
              const Text(
                'Type Password to confirm',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setDialog(() {}),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(
                    color: Colors.white24,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0F0E17),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF6B6B),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                confirmCtrl.dispose();
                Navigator.pop(ctx);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              onPressed: confirmCtrl.text.trim().isNotEmpty
                  ? () async {

                      final password = confirmCtrl.text.trim();
                      log("In Delete account button password is : ${password}");

                      Navigator.pop(ctx);

                      await _deleteAccount(password);
                    }
                  : null,

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),

                disabledBackgroundColor: const Color(
                  0xFFFF6B6B,
                ).withOpacity(0.3),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _warnChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFF6B6B).withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFF6B6B), size: 13),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
        ),
      ],
    ),
  );

  Future<void> _deleteAccount(String password) async {
    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B6B)),
      ),
    );

    try {
      log("In Delete account function, password is : ${password}");
      await context.read<AuthProvider>().deleteAccount(password);

      if (!mounted) return;

      // close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      context.read<TaskProvider>().reset();

      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }
}
