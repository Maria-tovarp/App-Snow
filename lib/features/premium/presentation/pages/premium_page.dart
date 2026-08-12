import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snow/core/widgets/app_drawer.dart';
import 'package:snow/core/widgets/app_section_header.dart';
import '../../data/premium_service.dart';
import '../../data/purchase_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  static const primary = Color(0xFF5B4CF0);
  static const ink = Color(0xFF17132E);
  static const muted = Color(0xFF747187);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  static const primary = PremiumPage.primary;
  static const ink = PremiumPage.ink;
  static const muted = PremiumPage.muted;

  @override
  void initState() {
    super.initState();
    PurchaseService.instance.addListener(_purchaseChanged);
    PurchaseService.instance.initialize();
    PremiumService.instance.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _purchaseChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PurchaseService.instance.removeListener(_purchaseChanged);
    super.dispose();
  }

  Future<void> _startTrial(BuildContext context) async {
    final premium = PremiumService.instance;
    await premium.startTrial();
    if (!mounted || !context.mounted) return;
    setState(() {});
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: primary, size: 38),
            const SizedBox(height: 12),
            Text(premium.isPremium ? '¡Premium está activo!' : 'Prueba ya utilizada', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(premium.isPremium ? 'Disfruta todas las funciones Premium durante ${premium.trialDaysRemaining} días. No se realizó ningún cobro.' : 'Esta cuenta ya utilizó su prueba gratuita.', textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.4)),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premium = PremiumService.instance;
    final purchases = PurchaseService.instance;
    if (premium.isPremium) {
      return _PremiumActivePage(
        isTrial: premium.isTrialActive,
        trialDays: premium.trialDaysRemaining,
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: ink,
            foregroundColor: Colors.white,
            leading: IconButton(onPressed: () => context.go('/home'), icon: const Icon(Icons.arrow_back_rounded)),
            title: const Text('Snow Premium', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          SliverToBoxAdapter(child: _Hero(
            onPurchase: premium.isPremium || purchases.product == null
                ? null
                : purchases.buy,
            price: purchases.price,
            loading: purchases.loading,
            activeDays: premium.isPremium ? premium.trialDaysRemaining : null,
          )),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 36),
            sliver: SliverList.list(children: [
              const Text('Conoce lo que desbloqueas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 6),
              const Text('Tus herramientas esenciales siguen disponibles gratis.', style: TextStyle(color: muted, fontSize: 14)),
              const SizedBox(height: 18),
              const _InsightsCard(),
              const SizedBox(height: 14),
              const _GradesCard(),
              const SizedBox(height: 14),
              const _PlannerCard(),
              const SizedBox(height: 14),
              const _AssistantCard(),
              const SizedBox(height: 26),
              const _PlanComparison(),
              const SizedBox(height: 22),
              SizedBox(height: 54, child: FilledButton.icon(onPressed: premium.isPremium || purchases.product == null || purchases.loading ? null : purchases.buy, icon: purchases.loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_outline_rounded), label: Text(premium.isPremium ? 'Premium activo' : 'Suscribirme · ${purchases.price}'))),
              TextButton(onPressed: purchases.loading || !purchases.isSupported ? null : purchases.restore, child: const Text('Restaurar compras')),
              if (purchases.errorMessage != null)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(purchases.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
              SizedBox(height: 54, child: FilledButton.icon(onPressed: premium.canStartTrial ? () => _startTrial(context) : null, icon: const Icon(Icons.auto_awesome), label: Text(premium.isPremium ? 'Premium activo' : premium.canStartTrial ? 'Probar Premium 7 días gratis' : 'Prueba gratuita utilizada'))),
              const SizedBox(height: 10),
              const Text('Después, \$15.000 COP/mes · Cancela cuando quieras', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _PremiumActivePage extends StatelessWidget {
  const _PremiumActivePage({required this.isTrial, required this.trialDays});

  final bool isTrial;
  final int trialDays;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const tools = [
      (Icons.insights_rounded, 'Snow Insights', 'Estadísticas de productividad', '/premium/insights'),
      (Icons.school_rounded, 'Mis notas', 'Promedios y proyecciones', '/premium/grades'),
      (Icons.auto_awesome_rounded, 'Planificador inteligente', 'Organiza tus próximas entregas', '/premium/planner'),
      (Icons.smart_toy_rounded, 'Snow Assistant', 'Recomendaciones académicas', '/premium/assistant'),
    ];
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/premium'),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(children: [
        const AppSectionHeader(
          title: 'Snow Premium',
          subtitle: 'Todas tus herramientas desbloqueadas',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF211B52), Color(0xFF5B4CF0)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFD76A),
                    child: Icon(Icons.workspace_premium_rounded,
                        color: Color(0xFF3D3000)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Premium activo', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                      Text(isTrial ? 'Prueba gratuita · $trialDays días restantes' : 'Suscripción activa', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  )),
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF72E6A0)),
                ]),
              ),
              const SizedBox(height: 22),
              Text('Tus herramientas', style: TextStyle(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...tools.map((tool) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF5B4CF0).withValues(alpha: .12),
                    child: Icon(tool.$1, color: const Color(0xFF5B4CF0)),
                  ),
                  title: Text(tool.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(tool.$3),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(tool.$4),
                ),
              )),
              TextButton(
                onPressed: PurchaseService.instance.restore,
                child: const Text('Restaurar compras'),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onPurchase, required this.price, required this.loading, this.activeDays});
  final VoidCallback? onPurchase;
  final String price;
  final bool loading;
  final int? activeDays;
  @override
  Widget build(BuildContext context) => Container(
    color: PremiumPage.ink,
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Estudia con más claridad,\nno con más presión.', style: TextStyle(color: Colors.white, fontSize: 30, height: 1.12, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      const Text('Análisis, automatización y más capacidad para llevar tu semestre al siguiente nivel.', style: TextStyle(color: Color(0xFFC9C5E6), fontSize: 15, height: 1.45)),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(child: FilledButton(onPressed: onPurchase, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFD76A), foregroundColor: const Color(0xFF2D2300), minimumSize: const Size(0, 50)), child: Text(loading ? 'Procesando…' : activeDays == null ? 'Suscribirme' : 'Premium activo'))),
        const SizedBox(width: 14),
        Text(price, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, height: 1.2)),
      ]),
    ]),
  );
}

class _FeatureShell extends StatelessWidget {
  const _FeatureShell({required this.icon, required this.title, required this.subtitle, required this.child});
  final IconData icon; final String title; final String subtitle; final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEDEAFF), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: PremiumPage.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(color: PremiumPage.muted, fontSize: 12))])), const Icon(Icons.workspace_premium_rounded, color: Color(0xFFE6AD17))]),
      const SizedBox(height: 18), child,
    ]),
  );
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard();
  @override Widget build(BuildContext context) => _FeatureShell(icon: Icons.insights_rounded, title: 'Snow Insights', subtitle: 'Tu semana de un vistazo', child: Column(children: [
    const Row(children: [Expanded(child: _Metric(value: '87%', label: 'Tareas')), SizedBox(width: 10), Expanded(child: _Metric(value: '8 h 35', label: 'Estudio'))]),
    const SizedBox(height: 10),
    Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFEAF8EF), borderRadius: BorderRadius.circular(13)), child: const Row(children: [Icon(Icons.trending_up, color: Color(0xFF23844A)), SizedBox(width: 9), Expanded(child: Text('Tu productividad aumentó 14%', style: TextStyle(color: Color(0xFF176638), fontWeight: FontWeight.w700)))])),
    TextButton(onPressed: () => context.go('/premium/insights'), child: const Text('Abrir estadísticas')),
  ]));
}

class _Metric extends StatelessWidget { const _Metric({required this.value, required this.label}); final String value; final String label; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFF5F3FA), borderRadius: BorderRadius.circular(13)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PremiumPage.ink)), Text(label, style: const TextStyle(color: PremiumPage.muted, fontSize: 12))])); }

class _GradesCard extends StatelessWidget {
  const _GradesCard();
  @override Widget build(BuildContext context) => _FeatureShell(icon: Icons.school_outlined, title: 'Mis notas', subtitle: 'Promedio y proyecciones automáticas', child: Column(children: [
    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cálculo', style: TextStyle(fontWeight: FontWeight.w800)), Text('Promedio 4.28', style: TextStyle(color: PremiumPage.primary, fontWeight: FontWeight.w900))]),
    const SizedBox(height: 10),
    const LinearProgressIndicator(value: .856, minHeight: 9, borderRadius: BorderRadius.all(Radius.circular(8))),
    const SizedBox(height: 12),
    const Text('Necesitas mínimo 3.6 en el examen final para aprobar con 3.5.', style: TextStyle(color: PremiumPage.muted, fontSize: 13, height: 1.35)),
    TextButton(onPressed: () => context.go('/premium/grades'), child: const Text('Abrir mis notas')),
  ]));
}

class _PlannerCard extends StatelessWidget {
  const _PlannerCard();
  @override Widget build(BuildContext context) => _FeatureShell(icon: Icons.auto_awesome_outlined, title: 'Planificador inteligente', subtitle: 'Tu semana organizada por prioridad', child: Column(children: [
    const _PlanRow(day: 'HOY', time: '18:00', task: 'Inglés'), const _PlanRow(day: '', time: '19:00', task: 'Cálculo'), const _PlanRow(day: 'MAÑANA', time: '17:30', task: 'Proyecto'),
    TextButton(onPressed: () => context.go('/premium/planner'), child: const Text('Abrir planificador')),
  ]));
}

class _PlanRow extends StatelessWidget { const _PlanRow({required this.day, required this.time, required this.task}); final String day; final String time; final String task; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [SizedBox(width: 70, child: Text(day, style: const TextStyle(color: PremiumPage.primary, fontSize: 11, fontWeight: FontWeight.w800))), Text(time, style: const TextStyle(color: PremiumPage.muted)), const SizedBox(width: 14), Expanded(child: Text(task, style: const TextStyle(fontWeight: FontWeight.w700)))])); }

class _AssistantCard extends StatelessWidget {
  const _AssistantCard();
  @override Widget build(BuildContext context) => _FeatureShell(icon: Icons.smart_toy_outlined, title: 'Snow Assistant', subtitle: 'Hasta 50 consultas al mes', child: Column(children: [Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF0EDFF), borderRadius: BorderRadius.circular(15)), child: const Text('🐰  Te recomiendo priorizar Cálculo lunes, martes y jueves. Dejemos Inglés para el miércoles.', style: TextStyle(color: PremiumPage.ink, height: 1.45, fontSize: 13))), TextButton(onPressed: () => context.go('/premium/assistant'), child: const Text('Abrir Assistant'))]));
}

class _PlanComparison extends StatelessWidget {
  const _PlanComparison();
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Premium mejora lo que ya funciona', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: PremiumPage.ink)),
    const SizedBox(height: 14),
    ...const [
      ('Materias', 'Hasta 5', 'Ilimitadas'), ('Tareas', '20 activas', 'Ilimitadas + subtareas'), ('Proyectos', 'Hasta 3', 'Ilimitados + seguimiento'), ('Pomodoro', 'Temporizador básico', 'Historial y estadísticas'), ('Snow Assistant', '3 consultas/mes', '50 consultas/mes'),
    ].map((row) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14)), child: Row(children: [Expanded(flex: 3, child: Text(row.$1, style: const TextStyle(fontWeight: FontWeight.w800))), Expanded(flex: 3, child: Text(row.$2, style: const TextStyle(color: PremiumPage.muted, fontSize: 12))), Expanded(flex: 4, child: Text(row.$3, style: const TextStyle(color: PremiumPage.primary, fontSize: 12, fontWeight: FontWeight.w700)))]))),
    const Padding(padding: EdgeInsets.only(top: 7), child: Row(children: [Icon(Icons.check_circle, color: Color(0xFF2A9D5B), size: 19), SizedBox(width: 8), Expanded(child: Text('Calendario, horario y herramientas esenciales siguen gratis.', style: TextStyle(color: PremiumPage.muted, fontSize: 13)))])),
  ]);
}
