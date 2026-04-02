import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/ui/staff_payroll_screen.dart';

void main() {
  group('Phase 10 staff and payroll', () {
    test(
      'calculates monthly, daily, and hourly payroll with advances',
      () async {
        final controller = HisabRakhoController(
          repository: InMemoryLedgerRepository(
            initialSnapshot: AppDataSnapshot(
              shops: <ShopProfile>[
                ShopProfile(
                  id: 'shop-1',
                  name: 'Rehmat Traders',
                  phone: '03001234567',
                  userType: UserType.shopkeeper,
                  createdAt: DateTime(2026, 1, 1),
                ),
              ],
              customers: const <Customer>[],
              transactions: const <LedgerTransaction>[],
              settings: const AppSettings(
                shopName: 'Rehmat Traders',
                organizationPhone: '03001234567',
                userType: UserType.shopkeeper,
                hasCompletedOnboarding: true,
                isPaidUser: true,
                lowDataMode: false,
                activeShopId: 'shop-1',
              ),
            ),
          ),
        );
        await controller.load();

        final monthlyStaff = await controller.saveStaffMember(
          name: 'Ahsan',
          role: 'Manager',
          payType: StaffPayType.monthly,
          baseRate: 30000,
        );
        final dailyStaff = await controller.saveStaffMember(
          name: 'Bilal',
          role: 'Helper',
          payType: StaffPayType.daily,
          baseRate: 1500,
        );
        final hourlyStaff = await controller.saveStaffMember(
          name: 'Sana',
          role: 'Designer',
          payType: StaffPayType.hourly,
          baseRate: 500,
        );

        await controller.saveStaffAttendance(
          staffId: monthlyStaff.id,
          date: DateTime(2026, 1, 1),
          status: StaffAttendanceStatus.present,
          workedHours: 8,
          overtimeHours: 2,
        );
        await controller.saveStaffAttendance(
          staffId: monthlyStaff.id,
          date: DateTime(2026, 1, 2),
          status: StaffAttendanceStatus.absent,
        );
        await controller.saveStaffAttendance(
          staffId: monthlyStaff.id,
          date: DateTime(2026, 1, 5),
          status: StaffAttendanceStatus.leave,
        );
        await controller.recordStaffAdvance(
          staffId: monthlyStaff.id,
          amount: 5000,
          note: 'Early cash',
          date: DateTime(2026, 1, 2),
        );

        await controller.saveStaffAttendance(
          staffId: dailyStaff.id,
          date: DateTime(2026, 1, 1),
          status: StaffAttendanceStatus.present,
          workedHours: 8,
          overtimeHours: 2,
        );
        await controller.saveStaffAttendance(
          staffId: dailyStaff.id,
          date: DateTime(2026, 1, 2),
          status: StaffAttendanceStatus.halfDay,
          workedHours: 4,
        );

        await controller.saveStaffAttendance(
          staffId: hourlyStaff.id,
          date: DateTime(2026, 1, 1),
          status: StaffAttendanceStatus.present,
          workedHours: 5,
          overtimeHours: 1,
        );
        await controller.saveStaffAttendance(
          staffId: hourlyStaff.id,
          date: DateTime(2026, 1, 2),
          status: StaffAttendanceStatus.present,
          workedHours: 3,
        );

        final monthlyRun = await controller.runStaffPayroll(
          staffId: monthlyStaff.id,
          periodStart: DateTime(2026, 1, 1),
          periodEnd: DateTime(2026, 1, 5),
          payDate: DateTime(2026, 1, 31),
        );
        final dailyRun = await controller.runStaffPayroll(
          staffId: dailyStaff.id,
          periodStart: DateTime(2026, 1, 1),
          periodEnd: DateTime(2026, 1, 2),
          payDate: DateTime(2026, 1, 31),
        );
        final hourlyRun = await controller.runStaffPayroll(
          staffId: hourlyStaff.id,
          periodStart: DateTime(2026, 1, 1),
          periodEnd: DateTime(2026, 1, 2),
          payDate: DateTime(2026, 1, 31),
        );

        expect(monthlyRun.basePay, closeTo(20000, 0.01));
        expect(monthlyRun.overtimePay, closeTo(2500, 0.01));
        expect(monthlyRun.advanceDeduction, closeTo(5000, 0.01));
        expect(monthlyRun.netPay, closeTo(17500, 0.01));

        expect(dailyRun.basePay, closeTo(2250, 0.01));
        expect(dailyRun.overtimePay, closeTo(375, 0.01));
        expect(dailyRun.netPay, closeTo(2625, 0.01));

        expect(hourlyRun.basePay, closeTo(4000, 0.01));
        expect(hourlyRun.overtimePay, closeTo(500, 0.01));
        expect(hourlyRun.netPay, closeTo(4500, 0.01));

        expect(controller.totalOutstandingStaffAdvances, 0);
        expect(controller.presentStaffTodayCount, greaterThanOrEqualTo(0));

        final slip = controller.buildSalarySlipDocument(monthlyRun);
        expect(slip, contains('SALARY SLIP'));
        expect(slip, contains('Ahsan'));
        expect(slip, contains('Advance deduction: Rs 5,000'));
        expect(slip, contains('Net pay: Rs 17,500'));
      },
    );

    testWidgets('renders the staff payroll hub', (tester) async {
      final shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Traders',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 1, 1),
      );
      final staff = StaffMember(
        id: 'staff-1',
        shopId: shop.id,
        name: 'Ahsan',
        phone: '03009998888',
        role: 'Manager',
        payType: StaffPayType.monthly,
        baseRate: 30000,
        createdAt: DateTime(2026, 1, 1),
      );
      final payrollRun = StaffPayrollRun(
        id: 'pay-1',
        shopId: shop.id,
        staffId: staff.id,
        payType: StaffPayType.monthly,
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 31),
        payDate: DateTime(2026, 1, 31),
        createdAt: DateTime(2026, 1, 31),
        basePay: 30000,
        overtimePay: 0,
        advanceDeduction: 0,
        netPay: 30000,
        paidUnits: 26,
        workingHours: 208,
        overtimeHours: 0,
      );
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(
          initialSnapshot: AppDataSnapshot(
            shops: <ShopProfile>[shop],
            customers: const <Customer>[],
            transactions: const <LedgerTransaction>[],
            staffMembers: <StaffMember>[staff],
            staffPayrollRuns: <StaffPayrollRun>[payrollRun],
            settings: const AppSettings(
              shopName: 'Rehmat Traders',
              organizationPhone: '03001234567',
              userType: UserType.shopkeeper,
              hasCompletedOnboarding: true,
              isPaidUser: true,
              lowDataMode: false,
              activeShopId: 'shop-1',
            ),
          ),
        ),
      );
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StaffPayrollScreen(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff and Payroll'), findsOneWidget);
      expect(find.text('Active staff'), findsOneWidget);
      expect(find.text('Ahsan', skipOffstage: false), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Payroll History'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Payroll History'), findsOneWidget);
    });
  });
}
