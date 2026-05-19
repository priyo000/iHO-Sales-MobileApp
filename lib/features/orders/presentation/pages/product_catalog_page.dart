import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../controllers/product_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/promo_controller.dart';
import '../../data/models/product_model.dart';

class ProductCatalogPage extends ConsumerStatefulWidget {
  final dynamic kunjunganId;
  final dynamic pelangganId;
  final Map<String, dynamic>?
  pelangganData; // NEW: Data pelanggan untuk display langsung
  final bool isEdit;
  final dynamic orderId;
  final String? localRef;
  final String? initialNotes;

  const ProductCatalogPage({
    super.key,
    this.kunjunganId,
    this.pelangganId,
    this.pelangganData,
    this.isEdit = false,
    this.orderId,
    this.localRef,
    this.initialNotes,
  });

  @override
  ConsumerState<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends ConsumerState<ProductCatalogPage> {
  String? _selectedCategoryId; // null = All
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isRefreshingPromo = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Inisialisasi keranjang untuk pelanggan ini
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(cartControllerProvider.notifier)
          .initForCustomer(
            widget.pelangganId,
            widget.pelangganData,
            widget.kunjunganId,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshPromo() async {
    final pelangganId = widget.pelangganId;
    if (pelangganId == null) return;
    final id = int.tryParse(pelangganId.toString());
    if (id == null) return;

    setState(() => _isRefreshingPromo = true);
    try {
      await refreshPromos(ref, id.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Data promo berhasil diperbarui'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshingPromo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // SSOT: Watch productControllerProvider to trigger build -> sync/revalidate
    // This ensures that products are fetched if DB is empty.
    ref.watch(productControllerProvider);

    // SSOT: Use StreamBuilder with SQL-based category + search
    // Category and search are combined at DB level for 10k+ products
    late final Stream<List<Product>> productsStream;
    if (_selectedCategoryId != null) {
      if (_searchQuery.isNotEmpty) {
        // Both category + search → combined DB query
        productsStream = ref.watch(
          productsByCategoryAndSearchStreamProvider((
            kategoriId: _selectedCategoryId!,
            query: _searchQuery,
          )),
        );
      } else {
        // Category only → DB query by category
        productsStream = ref.watch(
          productsByCategoryStreamProvider(_selectedCategoryId!),
        );
      }
    } else {
      // No category → search or all products
      productsStream = _searchQuery.isEmpty
          ? ref.watch(productsStreamProvider)
          : ref.watch(productSearchStreamProvider(_searchQuery));
    }

    final cartState = ref.watch(cartControllerProvider);
    final cartItems = cartState;
    final promoSelection = ref.watch(promoSelectionProvider);
    final cartTotal = cartState.items.fold<double>(
      0,
      (sum, item) =>
          sum +
          item.totalPrice -
          (promoSelection.promoForProduct(item.product.id)?.diskonAmount ?? 0),
    );

    // Cek apakah ada pelangganId untuk tampilkan tombol refresh promo
    final pelangganIdStr = widget.pelangganId?.toString();
    final hasPelanggan = pelangganIdStr != null && pelangganIdStr.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header & Search
            Container(
              padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari produk...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      if (hasPelanggan) ...[
                        const SizedBox(width: 8),
                        _isRefreshingPromo
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.discount_outlined),
                                tooltip: 'Refresh Promo',
                                onPressed: _refreshPromo,
                                color: AppTheme.primary,
                              ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Categories Row — from CategoriesTable (separate query, not from products)
                  Consumer(
                    builder: (context, ref, _) {
                      final categoriesAsync = ref.watch(
                        categoriesStreamProvider,
                      );
                      return categoriesAsync.when(
                        data: (categories) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // All chip
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: const Text('All'),
                                    selected: _selectedCategoryId == null,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(
                                          () => _selectedCategoryId = null,
                                        );
                                      }
                                    },
                                    selectedColor: AppTheme.primary,
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: _selectedCategoryId == null
                                          ? Colors.transparent
                                          : Colors.grey.withValues(alpha: 0.3),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    showCheckmark: false,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                  ),
                                ),
                                // Category chips from DB
                                ...categories.map((cat) {
                                  final isSelected =
                                      _selectedCategoryId == cat.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(cat.namaKategori),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(
                                            () => _selectedCategoryId = cat.id,
                                          );
                                        }
                                      },
                                      selectedColor: AppTheme.primary,
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: isSelected
                                            ? Colors.transparent
                                            : Colors.grey.withValues(
                                                alpha: 0.3,
                                              ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      showCheckmark: false,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => const SizedBox(height: 40),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Product Grid - SSOT with StreamBuilder
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: productsStream,
                builder: (context, snapshot) {
                  // SSOT: Data is instant from Drift - show skeleton only on first load
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final products = snapshot.data ?? [];

                  // No in-memory filter needed — category already filtered via DB query

                  if (products.isEmpty) {
                    return Center(child: Text('Produk tidak ditemukan'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    cacheExtent: 200,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final formatter = NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      );
                      final existingItem = cartState.items
                          .where((i) => i.product.id == product.id)
                          .firstOrNull;
                      final inCart = existingItem != null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProductCard(
                          product: product,
                          formattedPrice: formatter.format(
                            product.defaultUnit?.hargaJual ?? product.hargaJual,
                          ),
                          unitLabel: product.defaultUnit?.nama ?? product.satuan,
                          inCart: inCart,
                          cartQty: existingItem?.quantity ?? 0,
                          onTap: () => context.push(
                            '/product-order',
                            extra: {
                              'product': product,
                              'pelangganId': widget.pelangganId is int
                                  ? widget.pelangganId
                                  : int.tryParse(
                                      widget.pelangganId?.toString() ?? '',
                                    ),
                              'existingCartItem': existingItem,
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: cartItems.items.isEmpty
          ? null
          : SafeArea(
              bottom: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.isEdit) {
                        // Jika sedang edit, cukup pop kembali ke OrderReview yang sudah ada di stack
                        context.pop();
                      } else {
                        context.push(
                          '/order-review',
                          extra: {
                            'kunjunganId': widget.kunjunganId,
                            'pelangganId': widget.pelangganId,
                            'pelangganData': widget.pelangganData,
                            'isEdit': widget.isEdit,
                            'orderId': widget.orderId,
                            'localRef': widget.localRef,
                            'initialNotes': widget.initialNotes,
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shopping_cart),
                            SizedBox(width: 8),
                            Text(
                              'Lihat Keranjang',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${cartItems.items.length} Item | ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(cartTotal)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String formattedPrice;
  final String unitLabel;
  final bool inCart;
  final int cartQty;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.formattedPrice,
    required this.unitLabel,
    required this.inCart,
    required this.cartQty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: inCart
                ? AppTheme.primary.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product.gambarUrl ?? 'https://placehold.co/200',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                // Badge qty jika sudah di keranjang
                if (inCart)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(6),
                        ),
                      ),
                      child: Text(
                        '$cartQty',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.namaProduk,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.kodeBarang,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (unitLabel.isNotEmpty)
                              Text(
                                '/ $unitLabel',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              formattedPrice,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: inCart
                                  ? Colors.white
                                  : AppTheme.primary,
                              foregroundColor: inCart
                                  ? AppTheme.primary
                                  : Colors.white,
                              elevation: 0,
                              side: inCart
                                  ? const BorderSide(color: AppTheme.primary)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Text(
                              inCart ? 'Edit' : '+ Pilih',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
