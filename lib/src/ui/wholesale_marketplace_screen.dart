import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class WholesaleMarketplaceScreen extends StatefulWidget {
  const WholesaleMarketplaceScreen({super.key, required this.controller});

  final HisabRakhoController controller;

  @override
  State<WholesaleMarketplaceScreen> createState() =>
      _WholesaleMarketplaceScreenState();
}

class _WholesaleMarketplaceScreenState
    extends State<WholesaleMarketplaceScreen> {
  Future<void> _openListingEditor([WholesaleListing? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final categoryController = TextEditingController(
      text: existing?.category ?? '',
    );
    final priceController = TextEditingController(
      text: existing == null ? '' : existing.price.toStringAsFixed(0),
    );
    final unitController = TextEditingController(text: existing?.unit ?? 'pcs');
    final quantityController = TextEditingController(
      text: existing?.minQuantity.toString() ?? '1',
    );
    final phoneController = TextEditingController(
      text: existing?.phone ?? widget.controller.activeShop.phone,
    );
    final noteController = TextEditingController(text: existing?.note ?? '');
    var isActive = existing?.isActive ?? true;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      existing == null
                          ? 'Add wholesale offer'
                          : 'Edit wholesale offer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Product or service',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
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
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Rate',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Minimum quantity',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact phone',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Details'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Listing is active'),
                      subtitle: const Text(
                        'Inactive listings are hidden from the marketplace.',
                      ),
                      value: isActive,
                      onChanged: (value) {
                        setModalState(() {
                          isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        try {
                          await widget.controller.saveWholesaleListing(
                            listingId: existing?.id,
                            title: titleController.text.trim(),
                            price:
                                double.tryParse(priceController.text.trim()) ??
                                0,
                            category: categoryController.text.trim(),
                            unit: unitController.text.trim(),
                            minQuantity:
                                int.tryParse(quantityController.text.trim()) ??
                                1,
                            phone: phoneController.text.trim(),
                            note: noteController.text.trim(),
                            isActive: isActive,
                          );
                        } on ArgumentError catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message.toString())),
                          );
                          return;
                        }
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        existing == null ? 'Add offer' : 'Save offer',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    titleController.dispose();
    categoryController.dispose();
    priceController.dispose();
    unitController.dispose();
    quantityController.dispose();
    phoneController.dispose();
    noteController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wholesale offer saved successfully.')),
      );
    }
  }

  Future<void> _shareListing(WholesaleListing listing) async {
    await SharePlus.instance.share(
      ShareParams(
        title: listing.title,
        text: widget.controller.buildWholesaleListingShareText(listing),
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wholesale offer shared.')));
  }

  Future<void> _removeListing(WholesaleListing listing) async {
    await widget.controller.removeWholesaleListing(listing.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wholesale offer removed.')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final listings = widget.controller.wholesaleListings;

        return Scaffold(
          appBar: AppBar(title: const Text('Wholesale Marketplace')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: <Widget>[
              SummaryCard(
                title: 'Active offers',
                value: '${widget.controller.wholesaleListingCount}',
                subtitle:
                    'Create shareable B2B offers for products or services from the active shop.',
                accentColor: kKhataGreen,
                icon: Icons.storefront_rounded,
                prominent: true,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: widget.controller.canWriteData
                    ? () => _openListingEditor()
                    : null,
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('Add offer'),
              ),
              const SizedBox(height: 18),
              if (listings.isEmpty)
                const EmptyStateCard(
                  title: 'No wholesale offers yet',
                  message:
                      'Add an offer to build a local B2B catalogue you can share with buyers.',
                )
              else
                ...listings.map((listing) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    listing.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  widget.controller.formatCurrency(
                                    listing.price,
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: kKhataGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                InsightChip(
                                  label:
                                      'Min ${listing.minQuantity} ${listing.unit}',
                                  color: kKhataAmber,
                                ),
                                if (listing.category.trim().isNotEmpty)
                                  InsightChip(
                                    label: listing.category.trim(),
                                    color: kKhataGreen,
                                  ),
                                if (listing.phone.trim().isNotEmpty)
                                  InsightChip(
                                    label: listing.phone.trim(),
                                    color: kKhataSuccess,
                                  ),
                              ],
                            ),
                            if (listing.note.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 10),
                              Text(listing.note.trim()),
                            ],
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                FilledButton.tonalIcon(
                                  onPressed: () => _shareListing(listing),
                                  icon: const Icon(Icons.ios_share_rounded),
                                  label: const Text('Share'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: widget.controller.canWriteData
                                      ? () => _openListingEditor(listing)
                                      : null,
                                  icon: const Icon(Icons.edit_rounded),
                                  label: const Text('Edit'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: widget.controller.canWriteData
                                      ? () => _removeListing(listing)
                                      : null,
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
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
