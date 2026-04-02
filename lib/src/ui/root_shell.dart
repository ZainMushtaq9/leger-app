import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import 'add_customer_screen.dart';
import 'add_udhaar_screen.dart';
import 'business_screen.dart';
import 'customer_detail_screen.dart';
import 'customer_list_screen.dart';
import 'home_screen.dart';
import 'quick_ledger_entry_sheet.dart';
import 'reports_screen.dart';
import 'record_payment_screen.dart';
import 'settings_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({
    super.key,
    required this.controller,
    required this.adsEnabled,
  });

  final HisabRakhoController controller;
  final bool adsEnabled;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tabIndex = 0;

  Future<void> _openCustomer(Customer customer) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CustomerDetailScreen(
          controller: widget.controller,
          customer: customer,
          adsEnabled: widget.adsEnabled,
        ),
      ),
    );
  }

  Future<void> _openAddCustomer() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddCustomerScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _openAddUdhaar([String? selectedCustomerId]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddUdhaarScreen(
          controller: widget.controller,
          selectedCustomerId: selectedCustomerId,
        ),
      ),
    );
  }

  Future<void> _openRecordPayment(String customerId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RecordPaymentScreen(
          controller: widget.controller,
          customerId: customerId,
        ),
      ),
    );
  }

  Future<void> _openQuickEntrySheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          QuickLedgerEntrySheet(controller: widget.controller),
    );
    if (saved != true || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick entry saved successfully.')),
    );
  }

  Future<void> _openBusinessHub() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BusinessScreen(
          controller: widget.controller,
          onOpenCustomer: _openCustomer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          if (widget.controller.isDecoySession)
            Material(
              color: Colors.amber.shade100,
              child: SafeArea(
                bottom: false,
                child: ListTile(
                  leading: const Icon(Icons.visibility_off_rounded),
                  title: const Text('Decoy mode active'),
                  subtitle: const Text(
                    'Balances are masked and data editing is disabled in this session.',
                  ),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: <Widget>[
                HomeScreen(
                  controller: widget.controller,
                  adsEnabled: widget.adsEnabled,
                  onOpenCustomer: _openCustomer,
                  onAddUdhaar: _openAddUdhaar,
                  onShowCustomers: () {
                    setState(() {
                      _tabIndex = 1;
                    });
                  },
                  onOpenReports: () {
                    setState(() {
                      _tabIndex = 2;
                    });
                  },
                  onOpenSettings: () {
                    setState(() {
                      _tabIndex = 3;
                    });
                  },
                  onOpenBusiness: _openBusinessHub,
                ),
                CustomerListScreen(
                  controller: widget.controller,
                  adsEnabled: widget.adsEnabled,
                  onOpenCustomer: _openCustomer,
                  onAddCustomer: _openAddCustomer,
                  onAddUdhaar: (customerId) => _openAddUdhaar(customerId),
                  onRecordPayment: _openRecordPayment,
                ),
                ReportsScreen(
                  controller: widget.controller,
                  adsEnabled: widget.adsEnabled,
                  onOpenCustomer: _openCustomer,
                ),
                SettingsScreen(
                  controller: widget.controller,
                  adsEnabled: widget.adsEnabled,
                  onOpenBusinessHub: _openBusinessHub,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabIndex == 3 || !widget.controller.canWriteData
          ? null
          : GestureDetector(
              onLongPress: _openAddCustomer,
              child: FloatingActionButton(
                onPressed: _openQuickEntrySheet,
                child: const Icon(Icons.add_rounded),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.dashboard_rounded),
            label: widget.controller.copy.homeTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_alt_rounded),
            label: widget.controller.entityPluralLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_rounded),
            label: widget.controller.copy.reportsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            label: widget.controller.copy.settingsTab,
          ),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _tabIndex = index;
          });
        },
      ),
    );
  }
}
