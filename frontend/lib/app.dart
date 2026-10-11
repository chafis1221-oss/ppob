import 'package:flutter/material.dart';

const _green = Color(0xFF176B5B);
const _ink = Color(0xFF19332E);

class WarungMamaFahriApp extends StatelessWidget {
  const WarungMamaFahriApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WarungKu PPOB',
        theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: _green), scaffoldBackgroundColor: const Color(0xFFF7F8F6)),
        home: const Dashboard(),
      );
}

class _Service {
  final String name, hint;
  final IconData icon;
  final bool postpaid;
  final List<_Offer> offers;
  const _Service(this.name, this.hint, this.icon, this.offers, {this.postpaid = false});
}
class _Offer {
  final String name;
  final int price, margin;
  const _Offer(this.name, this.price, this.margin);
  String money(int n) => 'Rp ${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';
}

const _services = [
  _Service('Pulsa', 'Nomor HP pelanggan', Icons.phone_android, [_Offer('Pulsa 10K', 11500, 1500), _Offer('Pulsa 20K', 21500, 1500)]),
  _Service('Paket Data', 'Nomor HP pelanggan', Icons.wifi, [_Offer('Data 3 GB / 30 hari', 21500, 2500), _Offer('Data 10 GB / 30 hari', 51500, 3500)]),
  _Service('Game', 'User ID pelanggan', Icons.sports_esports, [_Offer('Voucher Game 20K', 21500, 1500), _Offer('Voucher Game 50K', 51500, 2500)]),
  _Service('E-Wallet', 'Nomor akun pelanggan', Icons.account_balance_wallet, [_Offer('Top up 25K', 26000, 1000), _Offer('Top up 50K', 51000, 1500)]),
  _Service('Token PLN', 'Nomor meter / ID pelanggan', Icons.bolt, [_Offer('Token 20K', 21500, 1000), _Offer('Token 50K', 51500, 1500)]),
  _Service('PDAM', 'Nomor pelanggan', Icons.water_drop, [_Offer('Tagihan bulan ini', 78500, 2500)], postpaid: true),
  _Service('PLN Pascabayar', 'ID pelanggan', Icons.electric_bolt, [_Offer('Tagihan berjalan', 168500, 3500)], postpaid: true),
];

class Dashboard extends StatefulWidget { const Dashboard({super.key}); @override State<Dashboard> createState() => _DashboardState(); }
class _DashboardState extends State<Dashboard> {
  int tab = 0;
  final transactions = <Map<String, dynamic>>[];
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: IndexedStack(index: tab, children: [_home(), _page('Riwayat transaksi', transactions.isEmpty ? [const _Empty(text: 'Riwayat masih kosong. Transaksi demo akan tampil di sini.')] : transactions.map(_tile).toList()), _page('Laporan hari ini', [ _stat('Transaksi', '${transactions.length}', Icons.receipt_long), const Text('Data offline dummy selama aplikasi terbuka.', style: TextStyle(color: Colors.black54))]), _page('Pengaturan', [const ListTile(leading: Icon(Icons.store_outlined), title: Text('Warung Mama Fahri'), subtitle: Text('Mode offline dummy'))])])), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Riwayat'), NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Laporan'), NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Pengaturan')]));
  Widget _home() => ListView(padding: const EdgeInsets.all(20), children: [const Text('Selamat pagi,', style: TextStyle(color: Colors.black54)), const Text('Warung Mama Fahri', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _ink)), const SizedBox(height: 20), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(20)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Saldo agen', style: TextStyle(color: Colors.white70)), SizedBox(height: 6), Text('Rp 2.450.000', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), SizedBox(height: 10), Text('Saldo demo • transaksi offline', style: TextStyle(color: Colors.white70))])), const SizedBox(height: 24), const Text('Layanan PPOB', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _services.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, mainAxisExtent: 112), itemBuilder: (_, i) => InkWell(onTap: () async { final result = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => TransactionFlow(service: _services[i]))); if (result != null) setState(() => transactions.insert(0, result)); }, child: Column(children: [CircleAvatar(backgroundColor: const Color(0xFFE3F0EC), child: Icon(_services[i].icon, color: _green)), const SizedBox(height: 8), Text(_services[i].name, textAlign: TextAlign.center)]))), const SizedBox(height: 16), if (transactions.isEmpty) const _Empty(text: 'Belum ada transaksi. Pilih layanan untuk mulai.') else ...transactions.take(3).map(_tile)]);
  Widget _page(String title, List<Widget> children) => ListView(padding: const EdgeInsets.all(20), children: [Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: _ink)), const SizedBox(height: 18), ...children]);
  Widget _stat(String label, String value, IconData icon) => Card(child: ListTile(leading: Icon(icon, color: _green), title: Text(label), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))));
  Widget _tile(Map<String, dynamic> x) => Card(child: ListTile(leading: Icon(x['icon'] as IconData, color: _green), title: Text('${x['service']} • ${x['offer']}'), subtitle: Text('${x['customer']}\n${x['status']} • ${x['orderId']}'), isThreeLine: true));
}

class TransactionFlow extends StatefulWidget { final _Service service; const TransactionFlow({required this.service, super.key}); @override State<TransactionFlow> createState() => _TransactionFlowState(); }
class _TransactionFlowState extends State<TransactionFlow> {
  int step = 0; final customer = TextEditingController(); _Offer? selected; final form = GlobalKey<FormState>(); bool inquiryDone = false;
  @override void dispose() { customer.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.service.postpaid ? 'Bayar ${widget.service.name}' : 'Beli ${widget.service.name}')), body: Stepper(currentStep: step, onStepContinue: _next, onStepCancel: () => step == 0 ? Navigator.pop(context) : setState(() => step--), controlsBuilder: (_, d) => Row(children: [FilledButton(onPressed: d.onStepContinue, child: Text(step == 3 || (!widget.service.postpaid && step == 2) ? 'Konfirmasi & proses' : 'Lanjutkan')), if (step > 0) TextButton(onPressed: d.onStepCancel, child: const Text('Kembali'))]), steps: [Step(title: const Text('Pelanggan'), content: Form(key: form, child: TextFormField(controller: customer, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: widget.service.hint), validator: (v) => (v ?? '').replaceAll(RegExp(r'[^0-9]'), '').length < 8 ? 'Masukkan minimal 8 digit' : null))), if (widget.service.postpaid) Step(title: const Text('Inquiry'), content: inquiryDone ? const Text('Tagihan dummy ditemukan dan siap ditinjau.') : const Text('Inquiry offline dummy akan mengambil tagihan contoh.')), if (!widget.service.postpaid) Step(title: const Text('Produk'), content: Column(children: widget.service.offers.map((o) => RadioListTile<_Offer>(value: o, groupValue: selected, onChanged: (v) => setState(() => selected = v), title: Text(o.name), subtitle: Text(o.money(o.price)))).toList())), Step(title: Text(widget.service.postpaid ? 'Ringkasan tagihan' : 'Konfirmasi'), content: Text(widget.service.postpaid ? 'Pelanggan: ${customer.text}\nTagihan dummy: ${widget.service.offers.first.money(widget.service.offers.first.price)}\n\nPeriksa detail sebelum konfirmasi.' : selected == null ? 'Pilih produk terlebih dahulu.' : 'Nomor: ${customer.text}\nProduk: ${selected!.name}\nTotal: ${selected!.money(selected!.price)}')), Step(title: const Text('Hasil'), content: const Text('Status transaksi: pending → success\nRef ID/order ID tersedia di detail.'))]));
  void _next() { final last = widget.service.postpaid ? 3 : 2; if (step == 0 && !(form.currentState?.validate() ?? false)) return; if (!widget.service.postpaid && step == 1 && selected == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih produk terlebih dahulu'))); return; } if (widget.service.postpaid && step == 1 && !inquiryDone) { setState(() => inquiryDone = true); return; } if (step < last) { setState(() => step++); return; } final id = 'DUMMY-${DateTime.now().millisecondsSinceEpoch}'; final offer = selected ?? widget.service.offers.first; Navigator.pop(context, {'service': widget.service.name, 'offer': offer.name, 'customer': customer.text, 'price': offer.price, 'margin': offer.margin, 'icon': widget.service.icon, 'status': 'Berhasil', 'orderId': id}); }
}
class _Empty extends StatelessWidget { final String text; const _Empty({required this.text}); @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(22), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)))); }
