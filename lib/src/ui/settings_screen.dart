import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.adsEnabled,
    this.onOpenBusinessHub,
  });

  final HisabRakhoController controller;
  final bool adsEnabled;
  final Future<void> Function()? onOpenBusinessHub;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _ntnController = TextEditingController();
  final TextEditingController _strnController = TextEditingController();
  final TextEditingController _invoicePrefixController =
      TextEditingController();
  final TextEditingController _quotationPrefixController =
      TextEditingController();
  final TextEditingController _salesTaxPercentController =
      TextEditingController();
  final TextEditingController _cloudWorkspaceController =
      TextEditingController();
  final TextEditingController _cloudDeviceLabelController =
      TextEditingController();
  UserType _selectedUserType = UserType.shopkeeper;
  bool _isPaidUser = false;
  bool _lowDataMode = false;
  bool _adsEnabled = true;
  AppThemeMode _themeMode = AppThemeMode.system;
  int _autoBackupDays = 0;
  int _autoLockMinutes = 5;
  bool _appLockEnabled = false;
  bool _biometricUnlockEnabled = false;
  bool _hideBalances = false;
  bool _hideHiddenCustomers = false;
  bool _communityBlacklistEnabled = false;
  bool _decoyModeEnabled = false;
  bool _cloudSyncEnabled = false;
  bool _initialized = false;
  bool _saving = false;
  bool _storageBusy = false;
  bool _cloudBusy = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _taglineController.dispose();
    _ntnController.dispose();
    _strnController.dispose();
    _invoicePrefixController.dispose();
    _quotationPrefixController.dispose();
    _salesTaxPercentController.dispose();
    _cloudWorkspaceController.dispose();
    _cloudDeviceLabelController.dispose();
    super.dispose();
  }

  void _syncFromController() {
    final settings = widget.controller.settings;
    final activeShop = widget.controller.activeShop;
    _shopNameController.text = settings.shopName;
    _phoneController.text = settings.organizationPhone;
    _addressController.text = activeShop.address;
    _emailController.text = activeShop.email;
    _taglineController.text = activeShop.tagline;
    _ntnController.text = activeShop.ntn;
    _strnController.text = activeShop.strn;
    _invoicePrefixController.text = activeShop.invoicePrefix;
    _quotationPrefixController.text = activeShop.quotationPrefix;
    _salesTaxPercentController.text = activeShop.salesTaxPercent <= 0
        ? ''
        : activeShop.salesTaxPercent.toStringAsFixed(
            activeShop.salesTaxPercent % 1 == 0 ? 0 : 1,
          );
    _selectedUserType = settings.userType;
    _isPaidUser = settings.isPaidUser;
    _lowDataMode = settings.lowDataMode;
    _adsEnabled = settings.adsEnabled;
    _themeMode = settings.themeMode;
    _autoBackupDays = settings.autoBackupDays;
    _autoLockMinutes = settings.autoLockMinutes;
    _appLockEnabled = settings.appLockEnabled;
    _biometricUnlockEnabled = settings.biometricUnlockEnabled;
    _hideBalances = settings.hideBalances;
    _hideHiddenCustomers = settings.hideHiddenCustomers;
    _communityBlacklistEnabled = settings.communityBlacklistEnabled;
    _decoyModeEnabled = settings.decoyModeEnabled;
    _cloudSyncEnabled = settings.cloudSyncEnabled;
    _cloudWorkspaceController.text = settings.cloudWorkspaceId;
    _cloudDeviceLabelController.text = settings.cloudDeviceLabel;
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });

    await widget.controller.updateSettings(
      widget.controller.settings.copyWith(
        shopName: _shopNameController.text.trim().isEmpty
            ? widget.controller.settings.shopName
            : _shopNameController.text.trim(),
        organizationPhone: _phoneController.text.trim(),
        userType: _selectedUserType,
        isPaidUser: _isPaidUser,
        lowDataMode: _lowDataMode,
        adsEnabled: _adsEnabled,
        language: AppLanguage.english,
        themeMode: _themeMode,
        autoBackupDays: _autoBackupDays,
        autoLockMinutes: _autoLockMinutes,
        appLockEnabled: _appLockEnabled && widget.controller.hasPinConfigured,
        biometricUnlockEnabled:
            _biometricUnlockEnabled && widget.controller.hasPinConfigured,
        hideBalances: _hideBalances,
        hideHiddenCustomers: _hideHiddenCustomers,
        communityBlacklistEnabled: _communityBlacklistEnabled,
        decoyModeEnabled:
            _decoyModeEnabled && widget.controller.hasDecoyPinConfigured,
        cloudSyncEnabled: _cloudSyncEnabled,
        cloudWorkspaceId: _cloudWorkspaceController.text,
        cloudDeviceLabel: _cloudDeviceLabelController.text,
      ),
    );
    await widget.controller.saveShopProfile(
      shopId: widget.controller.activeShopId,
      name: _shopNameController.text.trim().isEmpty
          ? widget.controller.settings.shopName
          : _shopNameController.text.trim(),
      phone: _phoneController.text.trim(),
      userType: _selectedUserType,
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
      tagline: _taglineController.text.trim(),
      ntn: _ntnController.text.trim(),
      strn: _strnController.text.trim(),
      invoicePrefix: _invoicePrefixController.text.trim(),
      quotationPrefix: _quotationPrefixController.text.trim(),
      salesTaxPercent:
          double.tryParse(_salesTaxPercentController.text.trim()) ?? 0,
      activate: true,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.controller.copy.settingsSavedMessage)),
    );
  }

  Future<void> _openWorkspaceEditor([ShopProfile? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final addressController = TextEditingController(
      text: existing?.address ?? '',
    );
    final emailController = TextEditingController(text: existing?.email ?? '');
    final taglineController = TextEditingController(
      text: existing?.tagline ?? '',
    );
    final ntnController = TextEditingController(text: existing?.ntn ?? '');
    final strnController = TextEditingController(text: existing?.strn ?? '');
    final invoicePrefixController = TextEditingController(
      text: existing?.invoicePrefix ?? 'INV',
    );
    final quotationPrefixController = TextEditingController(
      text: existing?.quotationPrefix ?? 'QTN',
    );
    final salesTaxPercentController = TextEditingController(
      text: existing == null || existing.salesTaxPercent <= 0
          ? ''
          : existing.salesTaxPercent.toStringAsFixed(
              existing.salesTaxPercent % 1 == 0 ? 0 : 1,
            ),
    );
    var selectedType = existing?.userType ?? UserType.shopkeeper;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    existing == null
                        ? widget.controller.copy.addAnotherShopLabel
                        : widget.controller.copy.editLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: widget.controller.copy.shopNameLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: widget.controller.copy.phoneLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: taglineController,
                    decoration: const InputDecoration(
                      labelText: 'Tagline',
                      hintText: 'Optional short brand line for documents',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'User Type'),
                    items: UserType.values
                        .map(
                          (type) => DropdownMenuItem<UserType>(
                            value: type,
                            child: Text(
                              AppTerminology.forUserType(
                                type,
                                language: AppLanguage.english,
                              ).userTypeLabel,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setModalState(() {
                        selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: invoicePrefixController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Prefix',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: quotationPrefixController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Quotation Prefix',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: ntnController,
                          decoration: const InputDecoration(labelText: 'NTN'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: strnController,
                          decoration: const InputDecoration(labelText: 'STRN'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: salesTaxPercentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Sales Tax %',
                      hintText: '0 for no tax split on documents',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(widget.controller.copy.cancelLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              return;
                            }
                            await widget.controller.saveShopProfile(
                              shopId: existing?.id,
                              name: name,
                              phone: phoneController.text.trim(),
                              userType: selectedType,
                              address: addressController.text.trim(),
                              email: emailController.text.trim(),
                              tagline: taglineController.text.trim(),
                              ntn: ntnController.text.trim(),
                              strn: strnController.text.trim(),
                              invoicePrefix: invoicePrefixController.text
                                  .trim(),
                              quotationPrefix: quotationPrefixController.text
                                  .trim(),
                              salesTaxPercent:
                                  double.tryParse(
                                    salesTaxPercentController.text.trim(),
                                  ) ??
                                  0,
                              activate:
                                  existing?.id ==
                                  widget.controller.settings.activeShopId,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop(true);
                          },
                          child: Text(widget.controller.copy.saveLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    emailController.dispose();
    taglineController.dispose();
    ntnController.dispose();
    strnController.dispose();
    invoicePrefixController.dispose();
    quotationPrefixController.dispose();
    salesTaxPercentController.dispose();

    if (saved == true && mounted) {
      setState(() {
        _initialized = false;
      });
    }
  }

  Future<void> _reloadLocalData() async {
    setState(() {
      _storageBusy = true;
    });

    await widget.controller.reloadFromStorage();

    if (!mounted) {
      return;
    }

    setState(() {
      _storageBusy = false;
      _initialized = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Local data reloaded.')));
  }

  Future<void> _copyBackupJson() async {
    final bundle = widget.controller.buildBackupExport(source: 'clipboard');
    await Clipboard.setData(ClipboardData(text: bundle.rawJson));
    await widget.controller.recordBackupEvent(
      preview: bundle.preview,
      source: 'clipboard',
      status: 'copied',
      note: 'Backup copied to clipboard',
      payload: bundle.rawJson,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup JSON copied to the clipboard.')),
    );
  }

  Future<void> _shareBackupJson() async {
    final bundle = widget.controller.buildBackupExport(source: 'share');
    await SharePlus.instance.share(
      ShareParams(
        title: 'Hisab Rakho Backup',
        text: 'Hisab Rakho backup file',
        files: <XFile>[_backupShareFile(bundle)],
      ),
    );
    await widget.controller.recordBackupEvent(
      preview: bundle.preview,
      source: 'share',
      status: 'shared',
      note: 'Backup shared',
      payload: bundle.rawJson,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup JSON shared successfully.')),
    );
  }

  String _backupFileName([DateTime? timestamp]) {
    final value = timestamp ?? DateTime.now();
    final safeDate = value.toIso8601String().replaceAll(':', '-');
    return 'hisab-rakho-backup-$safeDate.json';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }

  Color _integrityColor(BackupIntegrityStatus status) {
    switch (status) {
      case BackupIntegrityStatus.verified:
        return kKhataSuccess;
      case BackupIntegrityStatus.legacy:
        return kKhataAmber;
      case BackupIntegrityStatus.invalid:
        return kKhataDanger;
    }
  }

  String _autoBackupLabel(int days) {
    switch (days) {
      case 0:
        return 'Manual only';
      case 1:
        return 'Daily';
      case 7:
        return 'Weekly';
      default:
        return 'Every $days days';
    }
  }

  Future<void> _createBackupCheckpoint() async {
    setState(() {
      _storageBusy = true;
    });
    await widget.controller.createLocalBackup(
      source: 'checkpoint',
      note: 'Manual checkpoint from settings',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _storageBusy = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Backup checkpoint created.')));
  }

  Future<void> _shareBackupToDestination({
    required String source,
    required String successMessage,
  }) async {
    final bundle = widget.controller.buildBackupExport(source: source);
    await SharePlus.instance.share(
      ShareParams(
        title: 'Hisab Rakho Backup',
        text: 'Hisab Rakho backup file',
        files: <XFile>[_backupShareFile(bundle)],
      ),
    );
    await widget.controller.recordBackupEvent(
      preview: bundle.preview,
      source: source,
      status: 'shared',
      note: successMessage,
      payload: bundle.rawJson,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }

  XFile _backupShareFile(BackupExportBundle bundle) {
    return XFile.fromData(
      Uint8List.fromList(utf8.encode(bundle.rawJson)),
      mimeType: 'application/json',
      name: _backupFileName(bundle.preview.exportedAt),
    );
  }

  Future<void> _persistCloudSyncSettings() async {
    await widget.controller.updateSettings(
      widget.controller.settings.copyWith(
        cloudSyncEnabled: _cloudSyncEnabled,
        cloudWorkspaceId: _cloudWorkspaceController.text,
        cloudDeviceLabel: _cloudDeviceLabelController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _cloudWorkspaceController.text = widget.controller.cloudWorkspaceId;
      _cloudDeviceLabelController.text =
          widget.controller.settings.cloudDeviceLabel;
    });
  }

  Future<void> _signInCloudAccount() async {
    setState(() {
      _cloudBusy = true;
    });
    try {
      final account = await widget.controller.signInToCloudAccountWithGoogle();
      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = false;
      });
      final label = account.email.trim().isNotEmpty
          ? account.email.trim()
          : account.label;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cloud account connected: $label')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cloud sign-in failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _cloudBusy = false;
        });
      }
    }
  }

  Future<void> _signOutCloudAccount() async {
    setState(() {
      _cloudBusy = true;
    });
    try {
      await widget.controller.signOutOfCloudAccount();
      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud account signed out.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cloud sign-out failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _cloudBusy = false;
        });
      }
    }
  }

  Future<void> _refreshAccountWorkspaces() async {
    setState(() {
      _cloudBusy = true;
    });
    try {
      await widget.controller.refreshAccountCloudWorkspaces();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Linked workspaces refreshed.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workspace refresh failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cloudBusy = false;
        });
      }
    }
  }

  Future<void> _connectAccountWorkspace(
    CloudWorkspaceDirectoryEntry entry,
  ) async {
    setState(() {
      _cloudBusy = true;
    });
    try {
      await widget.controller.connectCloudWorkspace(entry.workspaceId);
      if (!mounted) {
        return;
      }
      setState(() {
        _cloudSyncEnabled = true;
        _cloudWorkspaceController.text = widget.controller.cloudWorkspaceId;
        _cloudDeviceLabelController.text =
            widget.controller.settings.cloudDeviceLabel;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workspace ${entry.workspaceId} connected.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workspace connection failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cloudBusy = false;
        });
      }
    }
  }

  Future<void> _restoreLatestFromAccountWorkspace(
    CloudWorkspaceDirectoryEntry entry,
  ) async {
    setState(() {
      _cloudBusy = true;
    });
    try {
      await widget.controller.connectCloudWorkspace(entry.workspaceId);
      if (!mounted) {
        return;
      }
      setState(() {
        _cloudSyncEnabled = true;
        _cloudWorkspaceController.text = widget.controller.cloudWorkspaceId;
        _cloudDeviceLabelController.text =
            widget.controller.settings.cloudDeviceLabel;
      });
      final backups = await widget.controller.refreshCloudBackups(limit: 1);
      if (backups.isEmpty) {
        throw StateError('No cloud backup was found for this workspace.');
      }
      final latest = backups.first;
      final preview = await widget.controller.previewCloudBackup(latest.id);
      if (!mounted) {
        return;
      }
      final confirmed = await _confirmRestorePreview(
        preview,
        label: '${entry.shopName} | ${entry.lastDeviceLabel}',
      );
      if (!confirmed) {
        return;
      }
      await widget.controller.restoreCloudBackup(latest.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Latest cloud copy restored from ${entry.shopName}.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workspace restore failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cloudBusy = false;
        });
      }
    }
  }

  Future<void> _generateCloudWorkspaceCode() async {
    setState(() {
      _cloudSyncEnabled = true;
      _cloudWorkspaceController.text = widget.controller
          .generateCloudWorkspaceId();
    });
    await _persistCloudSyncSettings();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new cloud workspace code was created.')),
    );
  }

  Future<void> _copyCloudWorkspaceCode() async {
    final value = _cloudWorkspaceController.text.trim();
    if (value.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cloud workspace code copied.')),
    );
  }

  Future<void> _refreshCloudBackups() async {
    setState(() {
      _cloudBusy = true;
    });
    try {
      await _persistCloudSyncSettings();
      await widget.controller.refreshCloudBackups();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cloud backups refreshed.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cloud refresh failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _cloudBusy = false;
        });
      }
    }
  }

  Future<void> _syncBackupToCloud() async {
    setState(() {
      _cloudBusy = true;
    });
    try {
      await _persistCloudSyncSettings();
      await widget.controller.syncBackupToCloud();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud backup synced successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cloud sync failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _cloudBusy = false;
        });
      }
    }
  }

  Future<void> _restoreLatestCloudBackup() async {
    setState(() {
      _cloudBusy = true;
    });
    try {
      await _persistCloudSyncSettings();
      final backups = await widget.controller.refreshCloudBackups(limit: 1);
      if (backups.isEmpty) {
        throw StateError('No cloud backup was found for this workspace.');
      }
      final latest = backups.first;
      final preview = await widget.controller.previewCloudBackup(latest.id);
      if (!mounted) {
        return;
      }
      final confirmed = await _confirmRestorePreview(
        preview,
        label: '${latest.shopName} | ${latest.deviceLabel}',
      );
      if (!confirmed) {
        return;
      }
      await widget.controller.restoreCloudBackup(latest.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latest cloud backup restored.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cloud restore failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _cloudBusy = false;
        });
      }
    }
  }

  Future<void> _clearBackupHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear backup history'),
          content: const Text(
            'This removes backup history entries from the app. Your exported files stay untouched.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await widget.controller.clearBackupHistory();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Backup history cleared.')));
  }

  Future<void> _manageHiddenProfiles() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            final hiddenProfiles = widget.controller.hiddenCustomers;
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Hidden profiles',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hiddenProfiles.isEmpty
                          ? 'There are no hidden customer profiles in the active shop.'
                          : 'Unhide profiles here when you want them back in the normal customer list.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (hiddenProfiles.isEmpty)
                      const EmptyStateCard(
                        title: 'No hidden profiles',
                        message: 'Hidden customers will appear here.',
                      )
                    else
                      ...hiddenProfiles.map(
                        (customer) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              title: Text(customer.name),
                              subtitle: Text(customer.phone),
                              trailing: FilledButton.tonal(
                                onPressed: () async {
                                  await widget.controller.setCustomerHidden(
                                    customer.id,
                                    hidden: false,
                                  );
                                },
                                child: const Text('Unhide'),
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
        );
      },
    );
  }

  Future<void> _managePartnerAccess() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            final profiles = widget.controller.partnerAccessProfiles;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Partner access',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _editPartnerAccess,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profiles.isEmpty
                          ? 'Add trusted partners for controlled shop access, role assignment, and invite-code sharing.'
                          : 'Manage internal partner roles and privacy permissions for the active shop.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (profiles.isEmpty)
                      const EmptyStateCard(
                        title: 'No partner profiles',
                        message:
                            'Partner roles, invite codes, and report permissions will appear here.',
                      )
                    else
                      ...profiles.map(
                        (profile) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          profile.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                      InsightChip(
                                        label: widget.controller
                                            .partnerAccessRoleLabel(
                                              profile.role,
                                            ),
                                        color: profile.isActive
                                            ? kKhataGreen
                                            : kKhataAmber,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                          if (profile.phone.trim().isNotEmpty)
                                            profile.phone.trim(),
                                          if (profile.email.trim().isNotEmpty)
                                            profile.email.trim(),
                                        ].join(' | ').isEmpty
                                        ? 'No contact details saved'
                                        : [
                                            if (profile.phone.trim().isNotEmpty)
                                              profile.phone.trim(),
                                            if (profile.email.trim().isNotEmpty)
                                              profile.email.trim(),
                                          ].join(' | '),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      InsightChip(
                                        label: 'Invite ${profile.inviteCode}',
                                        color: kKhataAmber,
                                      ),
                                      if (profile.canViewHiddenProfiles)
                                        const InsightChip(
                                          label: 'Can view hidden profiles',
                                          color: kKhataGreen,
                                        ),
                                      if (profile.canExportReports)
                                        const InsightChip(
                                          label: 'Can export reports',
                                          color: kKhataGreen,
                                        ),
                                      InsightChip(
                                        label: profile.isActive
                                            ? 'Active'
                                            : 'Paused',
                                        color: profile.isActive
                                            ? kKhataSuccess
                                            : kKhataAmber,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      FilledButton.tonalIcon(
                                        onPressed: () =>
                                            _editPartnerAccess(profile),
                                        icon: const Icon(Icons.edit_rounded),
                                        label: const Text('Edit'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Remove partner',
                                                ),
                                                content: Text(
                                                  'Remove ${profile.name} from partner access?',
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(true),
                                                    child: const Text('Remove'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (confirmed != true || !mounted) {
                                            return;
                                          }
                                          await widget.controller
                                              .removePartnerAccess(profile.id);
                                          if (!mounted || !context.mounted) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${profile.name} removed from partner access.',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                        label: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                ],
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
        );
      },
    );
  }

  Future<void> _editPartnerAccess([PartnerAccessProfile? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    var role = existing?.role ?? PartnerAccessRole.viewer;
    var canViewHidden = existing?.canViewHiddenProfiles ?? false;
    var canExportReports = existing?.canExportReports ?? false;
    var isActive = existing?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add partner access' : 'Edit partner access',
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Partner name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PartnerAccessRole>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: PartnerAccessRole.values
                            .map(
                              (value) => DropdownMenuItem<PartnerAccessRole>(
                                value: value,
                                child: Text(
                                  widget.controller.partnerAccessRoleLabel(
                                    value,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() {
                            role = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Can view hidden profiles'),
                        value: canViewHidden,
                        onChanged: (value) {
                          setModalState(() {
                            canViewHidden = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Can export reports'),
                        value: canExportReports,
                        onChanged: (value) {
                          setModalState(() {
                            canExportReports = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Profile active'),
                        value: isActive,
                        onChanged: (value) {
                          setModalState(() {
                            isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      return;
    }

    try {
      await widget.controller.savePartnerAccess(
        profileId: existing?.id,
        name: nameController.text,
        phone: phoneController.text,
        email: emailController.text,
        role: role,
        canViewHiddenProfiles: canViewHidden,
        canExportReports: canExportReports,
        isActive: isActive,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Partner access profile saved.'
                : 'Partner access updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
    }
  }

  Future<void> _saveBackupFile() async {
    setState(() {
      _storageBusy = true;
    });

    try {
      final bundle = widget.controller.buildBackupExport(source: 'file');
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup file',
        fileName: _backupFileName(bundle.preview.exportedAt),
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
        bytes: Uint8List.fromList(utf8.encode(bundle.rawJson)),
      );

      if ((path == null && !kIsWeb) || !mounted) {
        setState(() {
          _storageBusy = false;
        });
        return;
      }

      await widget.controller.recordBackupEvent(
        preview: bundle.preview,
        source: 'file',
        status: 'saved',
        note: 'Backup file exported',
        storagePath: path ?? 'browser-download',
        payload: bundle.rawJson,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _storageBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Backup file download started.'
                : 'Backup file saved: $path',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _storageBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup could not be saved: $error')),
      );
    }
  }

  Future<void> _restoreBackup() async {
    final inputController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Backup'),
          content: SizedBox(
            width: 460,
            child: TextField(
              controller: inputController,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Paste backup JSON',
                alignLabelWithHint: true,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      inputController.dispose();
      return;
    }

    setState(() {
      _storageBusy = true;
    });

    try {
      final preview = widget.controller.previewBackupJson(inputController.text);
      if (!mounted) {
        return;
      }
      final shouldRestore = await _confirmBackupRestore(
        inputController.text,
        preview: preview,
        source: 'paste',
      );
      if (shouldRestore != true) {
        setState(() {
          _storageBusy = false;
        });
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _storageBusy = false;
        _initialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _storageBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The backup JSON was not valid.')),
      );
    } finally {
      inputController.dispose();
    }
  }

  Future<void> _restoreBackupFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select backup file',
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      _storageBusy = true;
    });

    try {
      final file = result.files.single;
      final rawBackup = await file.xFile.readAsString();
      final preview = widget.controller.previewBackupJson(rawBackup);
      if (!mounted) {
        return;
      }
      final restored = await _confirmBackupRestore(
        rawBackup,
        preview: preview,
        source: 'file',
        label: file.name,
      );
      if (restored != true) {
        setState(() {
          _storageBusy = false;
        });
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _storageBusy = false;
        _initialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore from ${file.name} completed.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _storageBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup file restore failed: $error')),
      );
    }
  }

  Future<void> _importCsvFile(CsvImportSource source) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select CSV file',
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      _storageBusy = true;
    });

    try {
      final file = result.files.single;
      final rawCsv = await file.xFile.readAsString();
      final preview = widget.controller.previewCsvImport(
        rawCsv,
        source: source,
      );
      if (!mounted) {
        return;
      }
      final shouldImport = await _confirmCsvImport(
        preview: preview,
        label: file.name,
      );
      if (shouldImport != true) {
        setState(() {
          _storageBusy = false;
        });
        return;
      }

      final importResult = await widget.controller.importCsvData(
        rawCsv,
        source: source,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _storageBusy = false;
        _initialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.controller.csvImportSourceLabel(source)} import complete: '
            '${importResult.createdCustomerCount} new, '
            '${importResult.updatedCustomerCount} updated, '
            '${importResult.creditCount} credit, '
            '${importResult.paymentCount} payment.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _storageBusy = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV import failed: $error')));
    }
  }

  Future<bool?> _confirmCsvImport({
    required CsvImportPreview preview,
    required String label,
  }) {
    final previewRows = preview.rows.take(6).toList();
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${widget.controller.csvImportSourceLabel(preview.source)} Import Preview',
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      InsightChip(
                        label: '${preview.importableRowCount} usable rows',
                        color: kKhataSuccess,
                      ),
                      InsightChip(
                        label: '${preview.customerCount} customers',
                        color: kKhataGreen,
                      ),
                      InsightChip(
                        label:
                            'Credit ${widget.controller.displayCurrency(preview.totalCredits)}',
                        color: kKhataAmber,
                      ),
                      InsightChip(
                        label:
                            'Payment ${widget.controller.displayCurrency(preview.totalPayments)}',
                        color: kKhataSuccess,
                      ),
                    ],
                  ),
                  if (preview.warningMessages.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    ...preview.warningMessages.map(
                      (warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          warning,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: kKhataDanger),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Headers: ${preview.headerColumns.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  if (previewRows.isEmpty)
                    const Text('No importable rows found.')
                  else
                    ...previewRows.map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: row.isSkipped
                                ? kKhataDanger.withValues(alpha: 0.06)
                                : kKhataGreen.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Row ${row.rowNumber}: ${row.customerName.isEmpty ? '(missing name)' : row.customerName}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${row.phone.isEmpty ? 'No phone' : row.phone} | '
                                'Credit ${widget.controller.displayCurrency(row.creditAmount)} | '
                                'Payment ${widget.controller.displayCurrency(row.paymentAmount)}',
                              ),
                              if (row.note.trim().isNotEmpty) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(row.note.trim()),
                              ],
                              if (row.warnings.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  row.warnings.join(' | '),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: kKhataDanger),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: preview.importableRowCount == 0
                  ? null
                  : () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmRestorePreview(
    BackupPreview preview, {
    String? label,
  }) async {
    final integrityColor = _integrityColor(preview.integrityStatus);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Preview'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (label != null && label.trim().isNotEmpty) ...<Widget>[
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    InsightChip(
                      label: preview.integrityLabel,
                      color: integrityColor,
                    ),
                    InsightChip(
                      label: 'Version ${preview.version}',
                      color: kKhataGreen,
                    ),
                    InsightChip(
                      label: _formatBytes(preview.sizeBytes),
                      color: kKhataAmber,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Shops: ${preview.shopCount}\nCustomers: ${preview.customerCount}\nTransactions: ${preview.transactionCount}\nReminders: ${preview.reminderCount}\nInstallments: ${preview.installmentPlanCount}\nVisits: ${preview.visitCount}',
                ),
                if (preview.shopNames.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text('Included shops: ${preview.shopNames.join(', ')}'),
                ],
                if (preview.exportedAt != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Exported at: ${widget.controller.formatDateTime(preview.exportedAt!)}',
                  ),
                ],
                if (preview.expectedChecksum.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Checksum: ${preview.expectedChecksum.substring(0, 12)}...',
                  ),
                ],
                if (preview.integrityStatus ==
                    BackupIntegrityStatus.invalid) ...<Widget>[
                  const SizedBox(height: 12),
                  const Text(
                    'The integrity check failed. This backup should not be restored.',
                  ),
                ] else if (preview.integrityStatus ==
                    BackupIntegrityStatus.legacy) ...<Widget>[
                  const SizedBox(height: 12),
                  const Text(
                    'This is a legacy backup. It can still be restored, but SHA-256 verification is not available.',
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: preview.isRestorable
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    return true;
  }

  Future<bool?> _confirmBackupRestore(
    String rawBackup, {
    required BackupPreview preview,
    required String source,
    String? label,
  }) async {
    final confirmed = await _confirmRestorePreview(preview, label: label);
    if (!confirmed) {
      return false;
    }

    await widget.controller.restoreFromBackupJson(rawBackup, source: source);
    return true;
  }

  Future<void> _restoreCloudBackupRecord(CloudBackupManifest backup) async {
    setState(() {
      _cloudBusy = true;
    });
    try {
      final preview = await widget.controller.previewCloudBackup(backup.id);
      if (!mounted) {
        return;
      }
      final confirmed = await _confirmRestorePreview(
        preview,
        label: '${backup.shopName} | ${backup.deviceLabel}',
      );
      if (!confirmed) {
        return;
      }
      await widget.controller.restoreCloudBackup(backup.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cloud restore completed.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cloud restore failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _cloudBusy = false;
        });
      }
    }
  }

  Future<void> _deleteBackupRecord(BackupRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete backup history'),
        content: Text(
          'Delete the history item ${record.source} | ${record.status}?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await widget.controller.deleteBackupRecord(record.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup history item deleted.')),
    );
  }

  Future<void> _restoreBackupRecord(BackupRecord record) async {
    final preview = widget.controller.previewBackupJson(record.payload);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore checkpoint'),
        content: Text(
          'Restore the saved checkpoint from ${widget.controller.formatDateTime(record.createdAt)}?\n\n'
          '${preview.customerCount} customers | ${preview.transactionCount} transactions | ${preview.reminderCount} reminders',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _storageBusy = true;
    });

    try {
      await widget.controller.restoreFromBackupRecord(record.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _storageBusy = false;
        _initialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkpoint restored successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _storageBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkpoint restore failed: $error')),
      );
    }
  }

  Future<void> _configurePin({required bool decoy}) async {
    if (decoy && !widget.controller.hasPinConfigured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Set the main PIN first.')));
      return;
    }

    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(decoy ? 'Set decoy PIN' : 'Set security PIN'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'PIN'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Confirm PIN'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      pinController.dispose();
      confirmController.dispose();
      return;
    }

    final pin = pinController.text.trim();
    final confirmPin = confirmController.text.trim();
    pinController.dispose();
    confirmController.dispose();

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The PIN values do not match.')),
      );
      return;
    }

    try {
      if (decoy) {
        await widget.controller.setDecoyPin(pin);
      } else {
        await widget.controller.setSecurityPin(pin);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(decoy ? 'Decoy PIN saved.' : 'Security PIN saved.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _clearPin({required bool decoy}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(decoy ? 'Clear decoy PIN' : 'Clear security PIN'),
        content: Text(
          decoy
              ? 'Decoy mode will be turned off.'
              : 'App lock and biometric unlock will be turned off.',
        ),
        actions: <Widget>[
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

    if (confirmed != true) {
      return;
    }

    if (decoy) {
      await widget.controller.clearDecoyPin();
    } else {
      await widget.controller.clearSecurityPin();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _initialized = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(decoy ? 'Decoy PIN cleared.' : 'Security PIN cleared.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          if (!_initialized) {
            _syncFromController();
          }

          final previewCustomer = widget.controller.customers.isNotEmpty
              ? widget.controller.customers.first
              : null;
          final previewLink = previewCustomer == null
              ? ''
              : widget.controller.generateWhatsAppLink(
                  previewCustomer.phone,
                  previewCustomer.name,
                  widget.controller.insightFor(previewCustomer.id).balance,
                  customerId: previewCustomer.id,
                );
          final storageIcon = widget.controller.hasStorageError
              ? Icons.sd_card_alert_rounded
              : Icons.sd_storage_rounded;
          final storageColor = widget.controller.hasStorageError
              ? kKhataDanger
              : kKhataSuccess;
          final backups = widget.controller.backups.take(8).toList();
          final restorableBackups = backups.where(
            (backup) => backup.hasPayload,
          );
          final cloudBackups = widget.controller.cloudBackups.take(8).toList();
          final cloudAccount = widget.controller.cloudAccount;
          final accountWorkspaces = widget.controller.accountCloudWorkspaces
              .take(6)
              .toList();
          final copy = widget.controller.copy;
          final readOnlySession = widget.controller.isDecoySession;

          if (readOnlySession) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              children: <Widget>[
                Text(
                  copy.settingsTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Decoy mode active',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Balances are masked and settings are read-only in this session. Lock the app and unlock it again with the main PIN or biometrics for full access.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        InsightChip(
                          label: widget.controller.securityModeLabel(),
                          color: kKhataAmber,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            await widget.controller.lockApp();
                          },
                          icon: const Icon(Icons.lock_rounded),
                          label: const Text('Lock App'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: <Widget>[
              Text(
                copy.settingsTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        copy.shopProfileTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _shopNameController,
                        decoration: InputDecoration(
                          labelText: copy.shopNameLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: copy.phoneLabel),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserType>(
                        initialValue: _selectedUserType,
                        decoration: const InputDecoration(
                          labelText: 'User Type',
                        ),
                        items: UserType.values
                            .map(
                              (type) => DropdownMenuItem<UserType>(
                                value: type,
                                child: Text(
                                  AppTerminology.forUserType(
                                    type,
                                    language: AppLanguage.english,
                                  ).userTypeLabel,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedUserType = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Cloud account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in once to link workspace backups to your Google account and restore them on another device.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          InsightChip(
                            label: widget.controller.hasCloudSignIn
                                ? 'Sign-in ready'
                                : 'Sign-in unavailable',
                            color: widget.controller.hasCloudSignIn
                                ? kKhataSuccess
                                : kKhataAmber,
                          ),
                          InsightChip(
                            label: cloudAccount == null
                                ? 'Signed out'
                                : 'Signed in',
                            color: cloudAccount == null
                                ? kKhataAmber
                                : kKhataGreen,
                          ),
                          if (cloudAccount != null)
                            InsightChip(
                              label:
                                  '${accountWorkspaces.length} linked workspaces',
                              color: kKhataGreen,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (cloudAccount == null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kKhataGreen.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'No cloud account is signed in yet. You can still use a manual workspace code, but sign-in makes cross-device restore much easier.',
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kKhataGreen.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                cloudAccount.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (cloudAccount.email
                                  .trim()
                                  .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(cloudAccount.email),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Provider: ${cloudAccount.provider.trim().isEmpty ? 'google.com' : cloudAccount.provider}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Signed in: ${widget.controller.formatDateTime(cloudAccount.signedInAt)}',
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          if (cloudAccount == null)
                            FilledButton.icon(
                              onPressed:
                                  _cloudBusy ||
                                      !widget.controller.hasCloudSignIn
                                  ? null
                                  : _signInCloudAccount,
                              icon: _cloudBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: const Text('Sign In With Google'),
                            )
                          else ...<Widget>[
                            FilledButton.tonalIcon(
                              onPressed: _cloudBusy
                                  ? null
                                  : _refreshAccountWorkspaces,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refresh Workspaces'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _cloudBusy
                                  ? null
                                  : _signOutCloudAccount,
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Sign Out'),
                            ),
                          ],
                        ],
                      ),
                      if (cloudAccount != null) ...<Widget>[
                        const SizedBox(height: 16),
                        Text(
                          'Linked workspaces',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        if (accountWorkspaces.isEmpty)
                          const Text(
                            'No workspaces are linked to this account yet. Sync a cloud backup once from this device to register the current workspace.',
                          )
                        else
                          ...accountWorkspaces.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: kKhataGreen.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            entry.shopName.isEmpty
                                                ? entry.workspaceId
                                                : entry.shopName,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                        ),
                                        Text(
                                          widget.controller.formatDateTime(
                                            entry.updatedAt,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${entry.lastDeviceLabel} | ${entry.workspaceId}',
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        InsightChip(
                                          label:
                                              '${entry.backupCount} cloud copies',
                                          color: kKhataGreen,
                                        ),
                                        if (entry.accountEmail
                                            .trim()
                                            .isNotEmpty)
                                          InsightChip(
                                            label: entry.accountEmail,
                                            color: kKhataAmber,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        FilledButton.tonalIcon(
                                          onPressed: _cloudBusy
                                              ? null
                                              : () => _connectAccountWorkspace(
                                                  entry,
                                                ),
                                          icon: const Icon(Icons.link_rounded),
                                          label: const Text('Use Workspace'),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: _cloudBusy
                                              ? null
                                              : () =>
                                                    _restoreLatestFromAccountWorkspace(
                                                      entry,
                                                    ),
                                          icon: const Icon(
                                            Icons.cloud_download_rounded,
                                          ),
                                          label: const Text('Restore Latest'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Documents and branding',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These details appear on invoices, quotations, statements, PDF exports, and print-ready documents for the active shop.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _addressController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Business address',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Business email',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _taglineController,
                        decoration: const InputDecoration(
                          labelText: 'Brand tagline',
                          hintText: 'Optional short line below the shop name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _invoicePrefixController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Invoice prefix',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _quotationPrefixController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Quotation prefix',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _ntnController,
                              decoration: const InputDecoration(
                                labelText: 'NTN',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _strnController,
                              decoration: const InputDecoration(
                                labelText: 'STRN',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _salesTaxPercentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Sales tax %',
                          hintText: 'Used for invoice and quotation tax split',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Security and privacy',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Protect the app with a PIN, optional biometrics, hidden balances, hidden profiles, and a read-only decoy mode.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          InsightChip(
                            label: widget.controller.securityModeLabel(),
                            color: widget.controller.isSecurityEnabled
                                ? kKhataSuccess
                                : kKhataAmber,
                          ),
                          InsightChip(
                            label: widget.controller.hasPinConfigured
                                ? 'Main PIN ready'
                                : 'Main PIN not set',
                            color: widget.controller.hasPinConfigured
                                ? kKhataGreen
                                : kKhataAmber,
                          ),
                          InsightChip(
                            label: widget.controller.hasDecoyPinConfigured
                                ? 'Decoy PIN ready'
                                : 'Decoy PIN not set',
                            color: widget.controller.hasDecoyPinConfigured
                                ? kKhataSuccess
                                : kKhataAmber,
                          ),
                          InsightChip(
                            label: widget
                                .controller
                                .localDataProtectionStatus
                                .statusLabel,
                            color:
                                widget
                                    .controller
                                    .localDataProtectionStatus
                                    .encryptedAtRest
                                ? kKhataSuccess
                                : kKhataAmber,
                          ),
                          InsightChip(
                            label:
                                '${widget.controller.partnerAccessCount} partner profiles',
                            color: widget.controller.partnerAccessCount > 0
                                ? kKhataGreen
                                : kKhataAmber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kKhataGreen.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget
                                  .controller
                                  .localDataProtectionStatus
                                  .storageLabel,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget
                                      .controller
                                      .localDataProtectionStatus
                                      .encryptedAtRest
                                  ? 'Local records are encrypted at rest and the vault key is kept in the device security store.'
                                  : 'This device is using standard local storage right now. Secure-vault encryption becomes active when the device key store is available.',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                InsightChip(
                                  label:
                                      widget
                                          .controller
                                          .localDataProtectionStatus
                                          .keyStoredSecurely
                                      ? 'Key stored securely'
                                      : 'Key store unavailable',
                                  color:
                                      widget
                                          .controller
                                          .localDataProtectionStatus
                                          .keyStoredSecurely
                                      ? kKhataGreen
                                      : kKhataAmber,
                                ),
                                InsightChip(
                                  label:
                                      widget
                                          .controller
                                          .localDataProtectionStatus
                                          .usesDeviceVault
                                      ? 'Device vault active'
                                      : 'Device vault inactive',
                                  color:
                                      widget
                                          .controller
                                          .localDataProtectionStatus
                                          .usesDeviceVault
                                      ? kKhataSuccess
                                      : kKhataAmber,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _configurePin(decoy: false),
                              icon: const Icon(Icons.password_rounded),
                              label: Text(
                                widget.controller.hasPinConfigured
                                    ? 'Change PIN'
                                    : 'Set PIN',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.controller.hasPinConfigured
                                  ? () => _clearPin(decoy: false)
                                  : null,
                              icon: const Icon(Icons.lock_reset_rounded),
                              label: const Text('Clear PIN'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: widget.controller.hasPinConfigured
                                  ? () => _configurePin(decoy: true)
                                  : null,
                              icon: const Icon(Icons.visibility_off_rounded),
                              label: Text(
                                widget.controller.hasDecoyPinConfigured
                                    ? 'Change Decoy PIN'
                                    : 'Set Decoy PIN',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.controller.hasDecoyPinConfigured
                                  ? () => _clearPin(decoy: true)
                                  : null,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Clear Decoy'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: widget.controller.isSecurityEnabled
                            ? () async {
                                await widget.controller.lockApp();
                              }
                            : null,
                        icon: const Icon(Icons.lock_rounded),
                        label: const Text('Lock App Now'),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('App lock'),
                        subtitle: Text(
                          widget.controller.hasPinConfigured
                              ? 'Require the main PIN when reopening the app.'
                              : 'Set a main PIN first to enable app lock.',
                        ),
                        value: _appLockEnabled,
                        onChanged: (value) async {
                          if (value && !widget.controller.hasPinConfigured) {
                            await _configurePin(decoy: false);
                            if (!mounted) {
                              return;
                            }
                          }
                          setState(() {
                            _appLockEnabled =
                                value && widget.controller.hasPinConfigured;
                            if (!_appLockEnabled) {
                              _biometricUnlockEnabled = false;
                            }
                          });
                        },
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: _autoLockMinutes,
                        decoration: const InputDecoration(
                          labelText: 'Auto-lock timer',
                        ),
                        items: const <DropdownMenuItem<int>>[
                          DropdownMenuItem(value: 0, child: Text('Never')),
                          DropdownMenuItem(value: 1, child: Text('1 minute')),
                          DropdownMenuItem(value: 5, child: Text('5 minutes')),
                          DropdownMenuItem(
                            value: 15,
                            child: Text('15 minutes'),
                          ),
                        ],
                        onChanged: !_appLockEnabled
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _autoLockMinutes = value;
                                });
                              },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Biometric unlock'),
                        subtitle: const Text(
                          'Allow fingerprint or device biometrics after the main PIN is configured.',
                        ),
                        value: _biometricUnlockEnabled,
                        onChanged:
                            !widget.controller.hasPinConfigured ||
                                !_appLockEnabled
                            ? null
                            : (value) {
                                setState(() {
                                  _biometricUnlockEnabled = value;
                                });
                              },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hide balances on screen'),
                        subtitle: const Text(
                          'Mask visible amounts across dashboards, customer screens, reports, and business views.',
                        ),
                        value: _hideBalances,
                        onChanged: (value) {
                          setState(() {
                            _hideBalances = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hide hidden profiles'),
                        subtitle: const Text(
                          'Keep hidden customer profiles out of normal lists.',
                        ),
                        value: _hideHiddenCustomers,
                        onChanged: (value) {
                          setState(() {
                            _hideHiddenCustomers = value;
                          });
                        },
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _manageHiddenProfiles,
                          icon: const Icon(Icons.manage_accounts_rounded),
                          label: Text(
                            'Manage hidden profiles (${widget.controller.hiddenCustomers.length})',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _managePartnerAccess,
                          icon: const Icon(Icons.group_rounded),
                          label: Text(
                            'Manage partner access (${widget.controller.partnerAccessCount})',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Decoy mode'),
                        subtitle: Text(
                          widget.controller.hasDecoyPinConfigured
                              ? 'Allow an alternate PIN to open a read-only privacy session.'
                              : 'Set a decoy PIN first to enable read-only privacy mode.',
                        ),
                        value: _decoyModeEnabled,
                        onChanged: (value) async {
                          if (value &&
                              !widget.controller.hasDecoyPinConfigured) {
                            await _configurePin(decoy: true);
                            if (!mounted) {
                              return;
                            }
                          }
                          setState(() {
                            _decoyModeEnabled =
                                value &&
                                widget.controller.hasDecoyPinConfigured;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Community blacklist'),
                        subtitle: const Text(
                          'Opt in to local community risk reporting and blacklist matching.',
                        ),
                        value: _communityBlacklistEnabled,
                        onChanged: (value) {
                          setState(() {
                            _communityBlacklistEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'CSV import',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Import Digital Khata, OkCredit, or generic CSV data with a preview. Customers and ledger entries will be created using real imported data.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed:
                                _storageBusy || !widget.controller.canWriteData
                                ? null
                                : () => _importCsvFile(
                                    CsvImportSource.digitalKhata,
                                  ),
                            icon: const Icon(Icons.table_view_rounded),
                            label: const Text('Digital Khata'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed:
                                _storageBusy || !widget.controller.canWriteData
                                ? null
                                : () =>
                                      _importCsvFile(CsvImportSource.okCredit),
                            icon: const Icon(Icons.file_upload_rounded),
                            label: const Text('OkCredit'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                _storageBusy || !widget.controller.canWriteData
                                ? null
                                : () => _importCsvFile(CsvImportSource.generic),
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Generic CSV'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        copy.workspaceManagerTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(copy.workspaceManagerSubtitle),
                      const SizedBox(height: 14),
                      ...widget.controller.shops.map(
                        (shop) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: shop.id == widget.controller.activeShopId
                                  ? kKhataGreen.withValues(alpha: 0.1)
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        shop.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    if (shop.id ==
                                        widget.controller.activeShopId)
                                      InsightChip(
                                        label: copy.activeLabel,
                                        color: kKhataGreen,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${shop.phone} - ${AppTerminology.forUserType(shop.userType, language: AppLanguage.english).userTypeLabel}',
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed:
                                            shop.id ==
                                                widget.controller.activeShopId
                                            ? null
                                            : () async {
                                                await widget.controller
                                                    .switchActiveShop(shop.id);
                                                if (!mounted) {
                                                  return;
                                                }
                                                setState(() {
                                                  _initialized = false;
                                                });
                                              },
                                        child: Text(copy.useThisWorkspaceLabel),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton.tonal(
                                        onPressed: () =>
                                            _openWorkspaceEditor(shop),
                                        child: Text(copy.editLabel),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${widget.controller.shopCustomerCount(shop.id)} profiles - ${widget.controller.displayCurrency(widget.controller.shopOutstandingTotal(shop.id))}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.onOpenBusinessHub != null) ...<Widget>[
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => widget.onOpenBusinessHub?.call(),
                          icon: const Icon(Icons.store_mall_directory_rounded),
                          label: const Text('Open Business Hub'),
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed: () => _openWorkspaceEditor(),
                        icon: const Icon(Icons.add_business_rounded),
                        label: Text(copy.addAnotherShopLabel),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        copy.dataStorageTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Icon(storageIcon, color: storageColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.controller.hasStorageError
                                  ? copy.dataStorageFallback
                                  : copy.dataStorageHealthy,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          InsightChip(
                            label:
                                '${widget.controller.customerCount} customers',
                            color: kKhataGreen,
                          ),
                          InsightChip(
                            label:
                                '${widget.controller.transactionCount} transactions',
                            color: kKhataAmber,
                          ),
                          InsightChip(
                            label:
                                '${widget.controller.reminderCount} reminders',
                            color: kKhataSuccess,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _storageBusy ? null : _reloadLocalData,
                        icon: _storageBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(copy.reloadLocalLabel),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        copy.appearanceSettingsTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.transparent,
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kKhataGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.language_rounded,
                                  color: kKhataGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'App language',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'English is fixed for this build.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AppThemeMode>(
                        initialValue: _themeMode,
                        decoration: InputDecoration(labelText: copy.themeLabel),
                        items: AppThemeMode.values
                            .map(
                              (themeMode) => DropdownMenuItem<AppThemeMode>(
                                value: themeMode,
                                child: Text(
                                  widget.controller.themeModeLabel(themeMode),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _themeMode = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _autoBackupDays,
                        decoration: const InputDecoration(
                          labelText: 'Auto Backup Schedule',
                        ),
                        items: const <DropdownMenuItem<int>>[
                          DropdownMenuItem(value: 0, child: Text('Manual')),
                          DropdownMenuItem(value: 1, child: Text('Daily')),
                          DropdownMenuItem(value: 7, child: Text('Weekly')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _autoBackupDays = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Paid mode'),
                        subtitle: const Text('Ads off, unlimited reminders'),
                        value: _isPaidUser,
                        onChanged: (value) {
                          setState(() {
                            _isPaidUser = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Low data mode'),
                        subtitle: const Text(
                          'Compact actions and lighter usage',
                        ),
                        value: _lowDataMode,
                        onChanged: (value) {
                          setState(() {
                            _lowDataMode = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show ads'),
                        subtitle: const Text(
                          'Disable if you are using paid mode or private build',
                        ),
                        value: _adsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _adsEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Backup and restore',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create verified JSON backups, export them through the device, and restore with an integrity preview before importing.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          InsightChip(
                            label: _autoBackupLabel(
                              widget.controller.settings.autoBackupDays,
                            ),
                            color: widget.controller.isAutoBackupDue
                                ? kKhataAmber
                                : kKhataSuccess,
                          ),
                          InsightChip(
                            label: widget.controller.isAutoBackupDue
                                ? 'Backup due'
                                : 'Backup healthy',
                            color: widget.controller.isAutoBackupDue
                                ? kKhataAmber
                                : kKhataSuccess,
                          ),
                          InsightChip(
                            label: '${restorableBackups.length} restore points',
                            color: kKhataGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _storageBusy
                                  ? null
                                  : _createBackupCheckpoint,
                              icon: const Icon(Icons.backup_rounded),
                              label: const Text('Checkpoint'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _storageBusy ? null : _copyBackupJson,
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Copy Backup'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _storageBusy ? null : _shareBackupJson,
                              icon: const Icon(Icons.share_rounded),
                              label: const Text('Share Backup'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _storageBusy
                                  ? null
                                  : () => _shareBackupToDestination(
                                      source: 'email-share',
                                      successMessage:
                                          'Backup opened in the device share sheet for email apps.',
                                    ),
                              icon: const Icon(Icons.email_outlined),
                              label: const Text('Email Share'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _storageBusy
                                  ? null
                                  : () => _shareBackupToDestination(
                                      source: 'drive-share',
                                      successMessage:
                                          'Backup opened in the device share sheet for Drive or cloud apps.',
                                    ),
                              icon: const Icon(Icons.cloud_upload_outlined),
                              label: const Text('Drive Share'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _storageBusy ? null : _saveBackupFile,
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Save File'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _storageBusy
                                  ? null
                                  : _restoreBackupFromFile,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text('Restore File'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _storageBusy ? null : _restoreBackup,
                        icon: _storageBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.restore_rounded),
                        label: const Text('Restore From JSON'),
                      ),
                      const SizedBox(height: 14),
                      if (widget.controller.settings.lastBackupAt != null)
                        Text(
                          'Last backup: ${widget.controller.formatDateTime(widget.controller.settings.lastBackupAt!)}',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Cloud backup',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep a remote restore vault for this workspace so another device can pull the latest verified backup.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          InsightChip(
                            label: widget.controller.hasCloudDatabase
                                ? 'Cloud ready'
                                : 'Cloud unavailable',
                            color: widget.controller.hasCloudDatabase
                                ? kKhataSuccess
                                : kKhataAmber,
                          ),
                          InsightChip(
                            label: _cloudSyncEnabled
                                ? 'Workspace connected'
                                : 'Workspace off',
                            color: _cloudSyncEnabled
                                ? kKhataGreen
                                : kKhataAmber,
                          ),
                          InsightChip(
                            label: '${cloudBackups.length} cloud copies',
                            color: kKhataGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable cloud workspace'),
                        subtitle: const Text(
                          'Use one workspace code across devices to sync backups.',
                        ),
                        value: _cloudSyncEnabled,
                        onChanged: (value) {
                          setState(() {
                            _cloudSyncEnabled = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cloudWorkspaceController,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Workspace code',
                          hintText: 'ABCD-EFGH-JKLM',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cloudDeviceLabelController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Device label',
                          hintText: 'Main shop phone',
                        ),
                      ),
                      if (widget
                          .controller
                          .cloudSyncLastError
                          .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kKhataDanger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            widget.controller.cloudSyncLastError,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: kKhataDanger),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton.tonalIcon(
                            onPressed: _cloudBusy
                                ? null
                                : _generateCloudWorkspaceCode,
                            icon: const Icon(Icons.key_rounded),
                            label: const Text('Generate Code'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed:
                                _cloudBusy ||
                                    _cloudWorkspaceController.text
                                        .trim()
                                        .isEmpty
                                ? null
                                : _copyCloudWorkspaceCode,
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy Code'),
                          ),
                          FilledButton.icon(
                            onPressed: _cloudBusy || !_cloudSyncEnabled
                                ? null
                                : _syncBackupToCloud,
                            icon: _cloudBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_rounded),
                            label: const Text('Sync Now'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _cloudBusy || !_cloudSyncEnabled
                                ? null
                                : _refreshCloudBackups,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh Cloud'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _cloudBusy || !_cloudSyncEnabled
                                ? null
                                : _restoreLatestCloudBackup,
                            icon: const Icon(Icons.cloud_download_rounded),
                            label: const Text('Restore Latest'),
                          ),
                        ],
                      ),
                      if (widget.controller.lastCloudSyncAt !=
                          null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          'Last cloud sync: ${widget.controller.formatDateTime(widget.controller.lastCloudSyncAt!)}',
                        ),
                      ],
                      if (widget.controller.lastCloudRestoreAt !=
                          null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          'Last cloud restore: ${widget.controller.formatDateTime(widget.controller.lastCloudRestoreAt!)}',
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Cloud restore catalog',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      if (!_cloudSyncEnabled)
                        const Text(
                          'Enable cloud workspace to show remote backups.',
                        )
                      else if (cloudBackups.isEmpty)
                        const Text('No cloud backups found yet.')
                      else
                        ...cloudBackups.map(
                          (backup) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kKhataGreen.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          backup.shopName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                      Text(
                                        widget.controller.formatDateTime(
                                          backup.createdAt,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${backup.deviceLabel} | ${backup.customerCount} customers | ${backup.transactionCount} transactions',
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      InsightChip(
                                        label: backup.integrityStatus,
                                        color:
                                            backup.integrityStatus ==
                                                BackupIntegrityStatus
                                                    .verified
                                                    .name
                                            ? kKhataSuccess
                                            : kKhataAmber,
                                      ),
                                      if (backup.sizeBytes > 0)
                                        InsightChip(
                                          label: _formatBytes(backup.sizeBytes),
                                          color: kKhataGreen,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: _cloudBusy
                                        ? null
                                        : () =>
                                              _restoreCloudBackupRecord(backup),
                                    icon: const Icon(Icons.restore_rounded),
                                    label: const Text('Restore Cloud Copy'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Backup history',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: backups.isEmpty
                              ? null
                              : _clearBackupHistory,
                          icon: const Icon(Icons.delete_sweep_rounded),
                          label: const Text('Clear history'),
                        ),
                      ),
                      if (backups.isEmpty)
                        const Text('No backup history yet.')
                      else
                        ...backups.map(
                          (backup) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kKhataGreen.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          '${backup.source} | ${backup.status}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                      Text(
                                        widget.controller.formatDateTime(
                                          backup.createdAt,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _deleteBackupRecord(backup),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                        tooltip: 'Delete history item',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${backup.customerCount} customers | ${backup.transactionCount} transactions | ${backup.reminderCount} reminders',
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      InsightChip(
                                        label: backup.integrityStatus,
                                        color:
                                            backup.integrityStatus ==
                                                BackupIntegrityStatus
                                                    .invalid
                                                    .name
                                            ? kKhataDanger
                                            : backup.integrityStatus ==
                                                  BackupIntegrityStatus
                                                      .verified
                                                      .name
                                            ? kKhataSuccess
                                            : kKhataAmber,
                                      ),
                                      if (backup.sizeBytes > 0)
                                        InsightChip(
                                          label: _formatBytes(backup.sizeBytes),
                                          color: kKhataGreen,
                                        ),
                                    ],
                                  ),
                                  if (backup.note.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 4),
                                    Text(backup.note),
                                  ],
                                  if (backup.hasPayload) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        FilledButton.tonalIcon(
                                          onPressed:
                                              _storageBusy ||
                                                  !widget
                                                      .controller
                                                      .canWriteData
                                              ? null
                                              : () => _restoreBackupRecord(
                                                  backup,
                                                ),
                                          icon: const Icon(
                                            Icons.restore_rounded,
                                          ),
                                          label: const Text('Restore Point'),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (backup
                                      .storagePath
                                      .isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 4),
                                    Text(
                                      backup.storagePath,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Dynamic wa.me preview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'The link is generated automatically with the customer, amount, and message.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SelectableText(
                          previewLink.isEmpty
                              ? 'No customer data yet'
                              : previewLink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AdBannerStrip(
                enabled: widget.adsEnabled && _adsEnabled && !_isPaidUser,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : widget.controller.copy.saveSettingsLabel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
