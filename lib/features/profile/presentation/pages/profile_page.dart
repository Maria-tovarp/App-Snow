import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:helloworld/core/services/auth_session_service.dart';
import 'package:helloworld/core/services/local_data_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _store = LocalDataStore.instance;
  final _auth = AuthSessionService.instance;

  bool loading = true;
  bool showEditForm = false;

  Map<String, dynamic> profile = {};

  int materias = 0;
  int tareasCompletadas = 0;
  int tareasPendientes = 0;
  int proyectos = 0;
  int metas = 0;
  int sesionesPomodoro = 0;
  int minutosEstudio = 0;

  static const Color primary = Color(0xFF5B4CF0);
  static const Color primaryDark = Color(0xFF4A3AFF);
  static const Color textDark = Color(0xFF20202A);
  static const Color textMuted = Color(0xFF7C7C90);
  static const Color softBg = Color(0xFFF8F7FF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _store.initialize();

    final materiasData = await _store.getMaterias();
    final tareasData = await _store.getTareas();
    final proyectosData = await _store.getProyectos();
    final metasData = await _store.getMetas();
    final pomodoro = await _store.getTodayPomodoroStats();

    if (!mounted) return;

    setState(() {
      profile = Map<String, dynamic>.from(_store.profile);
      materias = materiasData.length;
      tareasCompletadas =
          tareasData.where((t) => t['estado'] == 'completada').length;
      tareasPendientes =
          tareasData.where((t) => t['estado'] != 'completada').length;
      proyectos = proyectosData.length;
      metas = metasData.length;
      sesionesPomodoro = pomodoro['sesionesEstudio'] ?? 0;
      minutosEstudio = pomodoro['minutosEstudio'] ?? 0;
      loading = false;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  String get _name {
    final profileName = profile['nombre']?.toString().trim();
    final sessionName = _auth.currentUser?.nombre.trim();

    if (profileName != null && profileName.isNotEmpty) return profileName;
    if (sessionName != null && sessionName.isNotEmpty) return sessionName;

    return 'Maria Tovar';
  }

  String get _initials {
    final parts = _name.split(' ').where((p) => p.trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'MT';

    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';

    return (first + last).toUpperCase();
  }

  String get _career {
    final value = profile['carrera']?.toString().trim();
    return value == null || value.isEmpty ? 'Sistemas' : value;
  }

  String get _semester {
    final value = profile['semestre']?.toString().trim();
    return value == null || value.isEmpty ? '7' : value;
  }

  String get _email {
    final sessionEmail = _auth.currentUser?.email.trim();
    final profileEmail = profile['email']?.toString().trim();

    if (sessionEmail != null && sessionEmail.isNotEmpty) return sessionEmail;
    if (profileEmail != null && profileEmail.isNotEmpty) return profileEmail;

    return 'mariaa-tovarp@unilibre.edu.co';
  }

  String get _university {
    final value = profile['universidad']?.toString().trim();
    return value == null || value.isEmpty ? 'Universidad Libre' : value;
  }

  String get _identification {
    final value = profile['identificacion']?.toString().trim();
    return value == null || value.isEmpty ? '11028174076' : value;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _saveProfile(Map<String, dynamic> data) {
    final updatedProfile = Map<String, dynamic>.from(profile);

    updatedProfile.addAll(data);
    updatedProfile['email'] = _email;
    updatedProfile['identificacion'] = _identification;

    _store.profile
      ..clear()
      ..addAll(updatedProfile);

    setState(() {
      profile = updatedProfile;
      showEditForm = false;
    });

    _showMessage('Perfil actualizado');
  }

  void _toggleEditForm() {
    setState(() {
      showEditForm = !showEditForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(onEdit: _toggleEditForm),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _ProfileCard(
                      initials: _initials,
                      name: _name,
                      career: _career,
                      semester: _semester,
                    ),
                  ),
                ),
                if (showEditForm)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: _EditProfileCard(
                        name: _name,
                        idNumber: _identification,
                        career: _career,
                        semester: _semester,
                        university: _university,
                        onSave: _saveProfile,
                        onCancel: () {
                          setState(() {
                            showEditForm = false;
                          });
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estadísticas Académicas',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 2.15,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            _StatCard(
                              icon: Icons.menu_book_outlined,
                              value: '$materias',
                              label: 'Materias',
                              iconColor: const Color(0xFF2F80ED),
                              iconBg: const Color(0xFFEAF3FF),
                            ),
                            _StatCard(
                              icon: Icons.check_circle_outline,
                              value: '$tareasCompletadas',
                              label: 'Completadas',
                              iconColor: const Color(0xFF00C853),
                              iconBg: const Color(0xFFE9FFF2),
                            ),
                            _StatCard(
                              icon: Icons.work_outline,
                              value: '$proyectos',
                              label: 'Proyectos',
                              iconColor: const Color(0xFFFF6D00),
                              iconBg: const Color(0xFFFFF0E3),
                            ),
                            _StatCard(
                              icon: Icons.track_changes_outlined,
                              value: '$metas',
                              label: 'Metas',
                              iconColor: const Color(0xFF9C27B0),
                              iconBg: const Color(0xFFF7E8FF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _PerformanceCard(
                          minutes: minutosEstudio,
                          pending: tareasPendientes,
                          sessions: sesionesPomodoro,
                        ),
                        const SizedBox(height: 18),
                        _AccountInfoCard(
                          email: _email,
                          university: _university,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE11445),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _ProfileBottomNav(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onEdit;

  const _Header({
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 38, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ProfilePageState.primaryDark,
            _ProfilePageState.primary,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.go('/home'),
            borderRadius: BorderRadius.circular(18),
            child: const Padding(
              padding: EdgeInsets.only(top: 6, right: 12, bottom: 6),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Información personal y estadísticas',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(18),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String initials;
  final String name;
  final String career;
  final String semester;

  const _ProfileCard({
    required this.initials,
    required this.name,
    required this.career,
    required this.semester,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: _ProfilePageState.softBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEDEBFF),
              border: Border.all(
                color: const Color(0xFFD5D0FF),
                width: 4,
              ),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 27,
                color: _ProfilePageState.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfilePageState.textDark,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            career,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfilePageState.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: _ProfilePageState.textDark,
                ),
                const SizedBox(width: 8),
                Text(
                  '$semester Semestre',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileCard extends StatefulWidget {
  final String name;
  final String idNumber;
  final String career;
  final String semester;
  final String university;
  final ValueChanged<Map<String, dynamic>> onSave;
  final VoidCallback onCancel;

  const _EditProfileCard({
    required this.name,
    required this.idNumber,
    required this.career,
    required this.semester,
    required this.university,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_EditProfileCard> createState() => _EditProfileCardState();
}

class _EditProfileCardState extends State<_EditProfileCard> {
  late final TextEditingController nameCtrl;
  late final TextEditingController idCtrl;
  late final TextEditingController careerCtrl;
  late final TextEditingController semesterCtrl;
  late final TextEditingController universityCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.name);
    idCtrl = TextEditingController(text: widget.idNumber);
    careerCtrl = TextEditingController(text: widget.career);
    semesterCtrl = TextEditingController(text: widget.semester);
    universityCtrl = TextEditingController(text: widget.university);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    idCtrl.dispose();
    careerCtrl.dispose();
    semesterCtrl.dispose();
    universityCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration({bool readOnly = false}) {
    return InputDecoration(
      filled: true,
      fillColor: readOnly ? const Color(0xFFE6E6EB) : const Color(0xFFF2F2F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _ProfilePageState.textDark,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          enableInteractiveSelection: !readOnly,
          decoration: _decoration(readOnly: readOnly),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _save() {
    widget.onSave({
      'nombre': nameCtrl.text.trim(),
      'identificacion': widget.idNumber,
      'carrera': careerCtrl.text.trim(),
      'semestre': semesterCtrl.text.trim(),
      'universidad': universityCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCD6FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editar Información',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ProfilePageState.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Actualiza tus datos personales',
            style: TextStyle(
              fontSize: 15,
              color: _ProfilePageState.textMuted,
            ),
          ),
          const SizedBox(height: 22),
          _field('Nombre completo', nameCtrl),
          _field(
            'Número de identificación',
            idCtrl,
            keyboardType: TextInputType.number,
            readOnly: true,
          ),
          _field('Carrera *', careerCtrl),
          _field(
            'Semestre actual',
            semesterCtrl,
            keyboardType: TextInputType.number,
          ),
          _field('Universidad', universityCtrl),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(
                    Icons.save_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Guardar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ProfilePageState.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2DFFF),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProfilePageState.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final int minutes;
  final int pending;
  final int sessions;

  const _PerformanceCard({
    required this.minutes,
    required this.pending,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up,
                color: _ProfilePageState.primary,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Rendimiento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _ProfilePageState.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _MetricRow(
            icon: Icons.schedule,
            title: 'Tiempo de estudio',
            value: '${hours}h ${mins}m',
            color: _ProfilePageState.primary,
          ),
          const SizedBox(height: 12),
          _MetricRow(
            icon: Icons.check_circle_outline,
            title: 'Tareas pendientes',
            value: '$pending',
            color: const Color(0xFFFF6D00),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            icon: Icons.workspace_premium_outlined,
            title: 'Sesiones Pomodoro',
            value: '$sessions',
            color: const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _ProfilePageState.textDark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final String email;
  final String university;

  const _AccountInfoCard({
    required this.email,
    required this.university,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de la cuenta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.email_outlined,
            title: 'Email',
            value: email,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.menu_book_outlined,
            title: 'Universidad',
            value: university,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: _ProfilePageState.textMuted, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ProfilePageState.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ProfilePageState.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBottomNav extends StatelessWidget {
  const _ProfileBottomNav();

  void _go(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/materias');
        break;
      case 2:
        context.go('/tareas');
        break;
      case 3:
        context.go('/metas');
        break;
      case 4:
        context.go('/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const active = _ProfilePageState.primary;
    const inactive = _ProfilePageState.textMuted;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE7E7EF)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                active: false,
                activeColor: active,
                inactiveColor: inactive,
                onTap: () => _go(context, 0),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                label: 'Materias',
                active: false,
                activeColor: active,
                inactiveColor: inactive,
                onTap: () => _go(context, 1),
              ),
              _NavItem(
                icon: Icons.checklist_outlined,
                label: 'Tareas',
                active: false,
                activeColor: active,
                inactiveColor: inactive,
                onTap: () => _go(context, 2),
              ),
              _NavItem(
                icon: Icons.track_changes_outlined,
                label: 'Metas',
                active: false,
                activeColor: active,
                inactiveColor: inactive,
                onTap: () => _go(context, 3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                active: true,
                activeColor: active,
                inactiveColor: inactive,
                onTap: () => _go(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
