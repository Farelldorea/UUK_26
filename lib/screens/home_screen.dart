import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_color.dart';
import '../utils/item.dart';
import '../utils/seed_data.dart';
import '../widgets/item_card.dart';
import 'all_item_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool _seedStarted = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan masuk untuk melanjutkan')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Gagal memuat tipe akun: ${snap.error}')),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = snap.data?.data()?['role'] == 'admin';
        if (isAdmin && !_seedStarted) {
          _seedStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await seedDummyData();
            } on FirebaseException catch (error, stackTrace) {
              debugPrint('Gagal mengisi data awal inventaris: $error');
              debugPrintStack(stackTrace: stackTrace);
            }
          });
        }

        final pages = [
          const _BerandaTab(),
          AllItemScreen(isAdmin: isAdmin),
          const ProfileScreen(),
        ];
        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: Container(
            decoration:
                BoxDecoration(color: Colors.white, boxShadow: AppColor.shadow),
            child: NavigationBar(
              backgroundColor: Colors.white,
              indicatorColor: AppColor.soft,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home, color: AppColor.primary),
                    label: 'Beranda'),
                NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon:
                        Icon(Icons.inventory_2, color: AppColor.primary),
                    label: 'Inventaris'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person, color: AppColor.primary),
                    label: 'Profil'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BerandaTab extends StatefulWidget {
  const _BerandaTab();
  @override
  State<_BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<_BerandaTab> {
  final _search = TextEditingController();
  final _page = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _cur = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_page.hasClients) {
        _cur = (_cur + 1) % 4;
        _page.animateToPage(_cur,
            duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    _search.dispose();
    super.dispose();
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
        child: Text(t,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.text)),
      );

  Widget _hList(List<Widget> children, {double height = 205}) => SizedBox(
        height: height,
        child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: children),
      );

  // Kartu kategori/status dengan gambar sebagai latar
  Widget _infoCard(IconData icon, String title, int count, String image) =>
      GestureDetector(
        onTap: () => setState(() => _search.text = title),
        child: Container(
          width: 150,
          margin: const EdgeInsets.only(right: 14, bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColor.shadow,
          ),
          child: Stack(fit: StackFit.expand, children: [
            ItemImage(image, radius: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColor.dark.withOpacity(0.92),
                    AppColor.primary.withOpacity(0.35),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(icon, color: AppColor.primary, size: 20)),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$count',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ]),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final name = FirebaseAuth.instance.currentUser?.displayName ?? 'Siswa';
    return StreamBuilder(
      stream: itemsRef.orderBy('created_at', descending: true).snapshots(),
      builder: (context, snap) {
        final items = snap.hasData
            ? snap.data!.docs.map((d) => Item.fromDoc(d)).toList()
            : <Item>[];
        final q = _search.text.toLowerCase().trim();
        final results = items
            .where((i) =>
                '${i.name} ${i.category} ${i.status} ${i.code}'
                    .toLowerCase()
                    .contains(q))
            .toList();

        final cats = <String, int>{};
        final catImg = <String, String>{};
        for (final i in items) {
          cats[i.category] = (cats[i.category] ?? 0) + 1;
          catImg.putIfAbsent(i.category, () => i.image);
        }
        final ready = items.where((i) => i.available).length;

        return ListView(padding: EdgeInsets.zero, children: [
          // Header + Search bar
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 28),
            decoration: const BoxDecoration(
              gradient: AppColor.gradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Halo, $name 👋',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Inventaris Alat Lab',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari alat inventaris...',
                  prefixIcon: const Icon(Icons.search, color: AppColor.primary),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _search.clear())),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none),
                ),
              ),
            ]),
          ),

          if (snap.connectionState == ConnectionState.waiting)
            const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()))
          else if (q.isNotEmpty) ...[
            _title('Hasil pencarian (${results.length})'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: results.isEmpty
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Text('Alat tidak ditemukan',
                              style: TextStyle(color: AppColor.grey))))
                  : Column(children: results.map((i) => ItemTile(i)).toList()),
            ),
          ] else ...[
            // Carousel slider
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _page,
                itemCount: items.length < 4 ? items.length : 4,
                onPageChanged: (i) => _cur = i,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => openDetail(context, items[i]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Stack(fit: StackFit.expand, children: [
                      ItemImage(items[i].image, radius: 22),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColor.dark.withValues(alpha: 0.85),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 14,
                        right: 16,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(items[i].name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(items[i].category,
                                  style: const TextStyle(color: Colors.white70)),
                            ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            // Horizontal scroll 1: Semua data
            _title('Semua Data'),
            _hList(items.map((i) => ItemCard(i)).toList()),

            // Horizontal scroll 2: Kategori (pakai gambar)
            _title('Kategori Peralatan'),
            _hList(
              cats.entries
                  .map((e) => _infoCard(
                      Icons.category, e.key, e.value, catImg[e.key] ?? ''))
                  .toList(),
              height: 150,
            ),

            // Horizontal scroll 3: Status (pakai gambar)
            _title('Status'),
            _hList([
              _infoCard(Icons.check_circle, 'Available', ready,
                  'https://picsum.photos/seed/available/400/300'),
              _infoCard(Icons.pending_actions, 'Borrowed',
                  items.length - ready,
                  'https://picsum.photos/seed/borrowed/400/300'),
            ], height: 150),
            const SizedBox(height: 20),
          ],
        ]);
      },
    );
  }
}