import 'package:flutter/material.dart';
import '../screens/detail_item_screen.dart';
import '../utils/app_color.dart';
import '../utils/format.dart';
import '../utils/item.dart';

class ItemImage extends StatelessWidget {
  final String url;
  final double? height, width;
  final double radius;
  const ItemImage(this.url,
      {super.key, this.height, this.width, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      width: width,
      color: AppColor.soft,
      child: const Icon(Icons.science, color: AppColor.primary, size: 40),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? fallback
          : Image.network(url,
              height: height,
              width: width,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (c, child, p) => p == null ? child : fallback),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = status == 'Available' ? AppColor.available : AppColor.borrowed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style:
              TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// manage = true  -> dari tab Inventaris (hanya Edit & Hapus)
/// manage = false -> dari Beranda (hanya Pinjam)
void openDetail(BuildContext context, Item i, {bool manage = false}) =>
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DetailItemScreen(item: i, manage: manage)));

/// Kartu untuk list horizontal.
class ItemCard extends StatelessWidget {
  final Item item;
  const ItemCard(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openDetail(context, item),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColor.shadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Hero(
            tag: 'img_${item.id}_h',
            child: ItemImage(item.image, height: 100, width: 160, radius: 20),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppColor.text)),
                  const SizedBox(height: 2),
                  Text(item.category,
                      style: const TextStyle(
                          color: AppColor.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  StatusBadge(item.status),
                ]),
          ),
        ]),
      ),
    );
  }
}

/// Baris untuk list vertikal.
class ItemTile extends StatelessWidget {
  final Item item;
  final bool manage;
  const ItemTile(this.item, {super.key, this.manage = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openDetail(context, item, manage: manage),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColor.shadow,
        ),
        child: Row(children: [
          Hero(
              tag: 'img_${item.id}',
              child: ItemImage(item.image, height: 76, width: 76)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColor.text)),
                  const SizedBox(height: 3),
                  Text('${item.code}  •  ${item.category}',
                      style: const TextStyle(
                          color: AppColor.grey, fontSize: 12)),
                  if (!item.available && item.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('Tenggat: ${fmtDateTime(item.dueDate!)}',
                          style: const TextStyle(
                              color: AppColor.grey, fontSize: 11)),
                    ),
                  const SizedBox(height: 8),
                  StatusBadge(item.status),
                ]),
          ),
          const Icon(Icons.chevron_right, color: AppColor.light),
        ]),
      ),
    );
  }
}