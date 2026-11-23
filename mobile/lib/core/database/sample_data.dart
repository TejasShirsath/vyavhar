import 'package:sqflite/sqflite.dart';
import '../../models/business_profile.dart';

class SampleDataSeeder {
  static Future<void> seedDatabase(Database db) async {
    final now = DateTime.now();

    // 1. Business Profile
    const profile = BusinessProfile();
    await db.insert('business_profile', {
      'id': 1,
      'business_name': profile.businessName,
      'owner_name': profile.ownerName,
      'phone': profile.phone,
      'email': profile.email,
      'address': profile.address,
      'gstin': profile.gstin,
      'tagline': profile.tagline,
      'invoice_terms': profile.invoiceTerms,
      'currency_symbol': profile.currencySymbol,
      'logo_path': null,
    });

    // 2. Categories
    final categories = [
      {'id': 'cat_1', 'name': 'Snacks', 'icon_name': 'fastfood'},
      {'id': 'cat_2', 'name': 'Beverages', 'icon_name': 'local_drink'},
      {'id': 'cat_3', 'name': 'Raw Material', 'icon_name': 'inventory_2'},
      {'id': 'cat_4', 'name': 'Sweets', 'icon_name': 'cake'},
      {'id': 'cat_5', 'name': 'Spices', 'icon_name': 'grain'},
    ];
    for (final c in categories) {
      await db.insert('categories', c);
    }

    // 3. Customers
    final customers = [
      {
        'id': 'cust_1',
        'name': 'Naitik Traders',
        'phone': '+91 98231 12345',
        'address': 'Shop 4, APMC Market Yard, Pune',
        'total_purchases': 45600.0,
        'pending_balance': 0.0,
        'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': 'cust_2',
        'name': 'Shree Enterprises',
        'phone': '+91 98901 98765',
        'address': 'Plot 12, Swargate Commercial Complex, Pune',
        'total_purchases': 32400.0,
        'pending_balance': 2200.0,
        'created_at': now.subtract(const Duration(days: 25)).toIso8601String(),
      },
      {
        'id': 'cust_3',
        'name': 'Balaji Retailers',
        'phone': '+91 97654 32100',
        'address': 'MG Road, Pune Camp',
        'total_purchases': 18500.0,
        'pending_balance': 0.0,
        'created_at': now.subtract(const Duration(days: 20)).toIso8601String(),
      },
      {
        'id': 'cust_4',
        'name': 'Ganesh Provisions',
        'phone': '+91 98450 11223',
        'address': 'Near Bus Depot, Kothrud, Pune',
        'total_purchases': 24800.0,
        'pending_balance': 3500.0,
        'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
      },
    ];
    for (final cust in customers) {
      await db.insert('customers', cust);
    }

    // 4. Suppliers
    final suppliers = [
      {
        'id': 'sup_1',
        'name': 'Royal Cashew Processors',
        'phone': '+91 94220 55667',
        'address': 'MIDC Ratnagiri, Maharashtra',
        'total_supplied': 125000.0,
        'created_at': now.subtract(const Duration(days: 60)).toIso8601String(),
      },
      {
        'id': 'sup_2',
        'name': 'Gujarat Dairy Farms',
        'phone': '+91 98240 88990',
        'address': 'Anand, Gujarat',
        'total_supplied': 85000.0,
        'created_at': now.subtract(const Duration(days: 60)).toIso8601String(),
      },
    ];
    for (final sup in suppliers) {
      await db.insert('suppliers', sup);
    }

    // 5. Products (matches UI reference items and names)
    final products = [
      {
        'id': 'prod_1',
        'name': 'Kaju Katli',
        'sku': 'VYV-1001',
        'category': 'Snacks',
        'purchase_price': 650.0,
        'selling_price': 850.0,
        'current_stock': 24.0,
        'unit': 'kg',
        'min_stock_alert': 10.0,
        'supplier_name': 'Royal Cashew Processors',
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 45)).toIso8601String(),
      },
      {
        'id': 'prod_2',
        'name': 'Besan Laddu',
        'sku': 'VYV-1002',
        'category': 'Snacks',
        'purchase_price': 240.0,
        'selling_price': 360.0,
        'current_stock': 32.0,
        'unit': 'kg',
        'min_stock_alert': 8.0,
        'supplier_name': 'Gujarat Dairy Farms',
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 40)).toIso8601String(),
      },
      {
        'id': 'prod_3',
        'name': 'Motichoor Laddu',
        'sku': 'VYV-1003',
        'category': 'Snacks',
        'purchase_price': 220.0,
        'selling_price': 320.0,
        'current_stock': 18.0,
        'unit': 'kg',
        'min_stock_alert': 10.0,
        'supplier_name': 'Gujarat Dairy Farms',
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 35)).toIso8601String(),
      },
      {
        'id': 'prod_4',
        'name': 'Soan Papdi',
        'sku': 'VYV-1004',
        'category': 'Snacks',
        'purchase_price': 160.0,
        'selling_price': 240.0,
        'current_stock': 40.0,
        'unit': 'kg',
        'min_stock_alert': 12.0,
        'supplier_name': 'Gujarat Dairy Farms',
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': 'prod_5',
        'name': 'Kaju Roll',
        'sku': 'VYV-1005',
        'category': 'Snacks',
        'purchase_price': 700.0,
        'selling_price': 920.0,
        'current_stock': 12.0,
        'unit': 'kg',
        'min_stock_alert': 5.0,
        'supplier_name': 'Royal Cashew Processors',
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 28)).toIso8601String(),
      },
      {
        'id': 'prod_6',
        'name': 'Malpua Mix',
        'sku': 'VYV-1006',
        'category': 'Raw Material',
        'purchase_price': 140.0,
        'selling_price': 210.0,
        'current_stock': 6.0, // Low Stock! (min alert is 10)
        'unit': 'kg',
        'min_stock_alert': 10.0,
        'supplier_name': 'Gujarat Dairy Farms',
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 25)).toIso8601String(),
      },
      {
        'id': 'prod_7',
        'name': 'Masala Chai Premix',
        'sku': 'VYV-1007',
        'category': 'Beverages',
        'purchase_price': 95.0,
        'selling_price': 150.0,
        'current_stock': 42.0,
        'unit': 'packet',
        'min_stock_alert': 15.0,
        'supplier_name': 'Royal Cashew Processors',
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 20)).toIso8601String(),
      },
      {
        'id': 'prod_8',
        'name': 'Badam Milk Powder',
        'sku': 'VYV-1008',
        'category': 'Beverages',
        'purchase_price': 280.0,
        'selling_price': 400.0,
        'current_stock': 0.0, // Out of Stock!
        'unit': 'box',
        'min_stock_alert': 5.0,
        'supplier_name': 'Gujarat Dairy Farms',
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 18)).toIso8601String(),
      },
      {
        'id': 'prod_9',
        'name': 'Cashews Grade W320',
        'sku': 'VYV-1009',
        'category': 'Raw Material',
        'purchase_price': 620.0,
        'selling_price': 780.0,
        'current_stock': 55.0,
        'unit': 'kg',
        'min_stock_alert': 15.0,
        'supplier_name': 'Royal Cashew Processors',
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
      },
      {
        'id': 'prod_10',
        'name': 'Pure Desi Ghee',
        'sku': 'VYV-1010',
        'category': 'Raw Material',
        'purchase_price': 540.0,
        'selling_price': 680.0,
        'current_stock': 3.0, // Low Stock! (min alert is 8)
        'unit': 'liter',
        'min_stock_alert': 8.0,
        'supplier_name': 'Gujarat Dairy Farms',
        'image_path': null,
        'created_at': now.subtract(const Duration(days: 12)).toIso8601String(),
      },
    ];

    for (final prod in products) {
      await db.insert('products', prod);

      // Record opening stock movement
      await db.insert('stock_movements', {
        'id': 'sm_init_${prod['id']}',
        'product_id': prod['id'],
        'movement_type': 'INITIAL',
        'quantity': prod['current_stock'],
        'unit_price': prod['purchase_price'],
        'total_value': (prod['current_stock'] as num) * (prod['purchase_price'] as num),
        'reference_id': null,
        'reason': 'Opening stock recorded',
        'created_at': prod['created_at'],
      });
    }

    // 6. Invoices (matching reference numbers: INV-1048, INV-1047, etc.)
    final today = DateTime(now.year, now.month, now.day);
    final inv1048Time = DateTime(today.year, today.month, today.day, 10, 24);
    final inv1047Time = DateTime(today.year, today.month, today.day, 9, 41);
    final yesterdayTime = today.subtract(const Duration(days: 1, hours: 2));
    final twoDaysAgo = today.subtract(const Duration(days: 2, hours: 4));
    final threeDaysAgo = today.subtract(const Duration(days: 3, hours: 3));

    // Invoice INV-1048: Naitik Traders (₹4,800)
    await db.insert('invoices', {
      'id': 'inv_1048',
      'invoice_number': 'INV-1048',
      'customer_id': 'cust_1',
      'customer_name': 'Naitik Traders',
      'customer_phone': '+91 98231 12345',
      'customer_address': 'Shop 4, APMC Market Yard, Pune',
      'subtotal': 4800.0,
      'discount': 0.0,
      'gst_rate': 0.0,
      'gst_amount': 0.0,
      'additional_charges': 0.0,
      'grand_total': 4800.0,
      'paid_amount': 4800.0,
      'payment_status': 'Paid',
      'payment_mode': 'UPI',
      'notes': 'Delivered at APMC shop',
      'created_at': inv1048Time.toIso8601String(),
      'is_cancelled': 0,
    });
    // Items for INV-1048: 4kg Kaju Katli @ 850 (₹3,400) + 4kg Besan Laddu @ 350 (₹1,400) = ₹4,800
    await db.insert('invoice_items', {
      'id': 'item_1048_1',
      'invoice_id': 'inv_1048',
      'product_id': 'prod_1',
      'product_name': 'Kaju Katli',
      'sku': 'VYV-1001',
      'unit': 'kg',
      'quantity': 4.0,
      'purchase_price': 650.0,
      'unit_price': 850.0,
      'total_amount': 3400.0,
    });
    await db.insert('invoice_items', {
      'id': 'item_1048_2',
      'invoice_id': 'inv_1048',
      'product_id': 'prod_2',
      'product_name': 'Besan Laddu',
      'sku': 'VYV-1002',
      'unit': 'kg',
      'quantity': 4.0,
      'purchase_price': 240.0,
      'unit_price': 350.0,
      'total_amount': 1400.0,
    });

    // Invoice INV-1047: Shree Enterprises (₹2,200)
    await db.insert('invoices', {
      'id': 'inv_1047',
      'invoice_number': 'INV-1047',
      'customer_id': 'cust_2',
      'customer_name': 'Shree Enterprises',
      'customer_phone': '+91 98901 98765',
      'customer_address': 'Plot 12, Swargate Commercial Complex, Pune',
      'subtotal': 2200.0,
      'discount': 0.0,
      'gst_rate': 0.0,
      'gst_amount': 0.0,
      'additional_charges': 0.0,
      'grand_total': 2200.0,
      'paid_amount': 2200.0,
      'payment_status': 'Paid',
      'payment_mode': 'Cash',
      'notes': 'Paid in cash upon dispatch',
      'created_at': inv1047Time.toIso8601String(),
      'is_cancelled': 0,
    });
    // Items for INV-1047: 5kg Motichoor Laddu @ 320 (₹1,600) + 4 packets Masala Chai @ 150 (₹600) = ₹2,200
    await db.insert('invoice_items', {
      'id': 'item_1047_1',
      'invoice_id': 'inv_1047',
      'product_id': 'prod_3',
      'product_name': 'Motichoor Laddu',
      'sku': 'VYV-1003',
      'unit': 'kg',
      'quantity': 5.0,
      'purchase_price': 220.0,
      'unit_price': 320.0,
      'total_amount': 1600.0,
    });
    await db.insert('invoice_items', {
      'id': 'item_1047_2',
      'invoice_id': 'inv_1047',
      'product_id': 'prod_7',
      'product_name': 'Masala Chai Premix',
      'sku': 'VYV-1007',
      'unit': 'packet',
      'quantity': 4.0,
      'purchase_price': 95.0,
      'unit_price': 150.0,
      'total_amount': 600.0,
    });

    // Additional invoices for trend analytics
    await db.insert('invoices', {
      'id': 'inv_1046',
      'invoice_number': 'INV-1046',
      'customer_id': 'cust_3',
      'customer_name': 'Balaji Retailers',
      'customer_phone': '+91 97654 32100',
      'customer_address': 'MG Road, Pune Camp',
      'subtotal': 9200.0,
      'discount': 200.0,
      'gst_rate': 5.0,
      'gst_amount': 450.0,
      'additional_charges': 0.0,
      'grand_total': 9450.0,
      'paid_amount': 9450.0,
      'payment_status': 'Paid',
      'payment_mode': 'Bank Transfer',
      'notes': null,
      'created_at': yesterdayTime.toIso8601String(),
      'is_cancelled': 0,
    });
    await db.insert('invoice_items', {
      'id': 'item_1046_1',
      'invoice_id': 'inv_1046',
      'product_id': 'prod_5',
      'product_name': 'Kaju Roll',
      'sku': 'VYV-1005',
      'unit': 'kg',
      'quantity': 10.0,
      'purchase_price': 700.0,
      'unit_price': 920.0,
      'total_amount': 9200.0,
    });

    await db.insert('invoices', {
      'id': 'inv_1045',
      'invoice_number': 'INV-1045',
      'customer_id': 'cust_4',
      'customer_name': 'Ganesh Provisions',
      'customer_phone': '+91 98450 11223',
      'customer_address': 'Near Bus Depot, Kothrud',
      'subtotal': 8130.0,
      'discount': 0.0,
      'gst_rate': 0.0,
      'gst_amount': 0.0,
      'additional_charges': 0.0,
      'grand_total': 8130.0,
      'paid_amount': 4630.0,
      'payment_status': 'Partial',
      'payment_mode': 'Cash',
      'notes': 'Remaining ₹3500 due next week',
      'created_at': twoDaysAgo.toIso8601String(),
      'is_cancelled': 0,
    });
    await db.insert('invoice_items', {
      'id': 'item_1045_1',
      'invoice_id': 'inv_1045',
      'product_id': 'prod_4',
      'product_name': 'Soan Papdi',
      'sku': 'VYV-1004',
      'unit': 'kg',
      'quantity': 25.0,
      'purchase_price': 160.0,
      'unit_price': 240.0,
      'total_amount': 6000.0,
    });
    await db.insert('invoice_items', {
      'id': 'item_1045_2',
      'invoice_id': 'inv_1045',
      'product_id': 'prod_6',
      'product_name': 'Malpua Mix',
      'sku': 'VYV-1006',
      'unit': 'kg',
      'quantity': 10.0,
      'purchase_price': 140.0,
      'unit_price': 213.0,
      'total_amount': 2130.0,
    });

    // 7. Wastage Records
    await db.insert('wastage_records', {
      'id': 'w_1',
      'product_id': 'prod_2',
      'product_name': 'Besan Laddu',
      'quantity': 2.0,
      'unit': 'kg',
      'unit_cost': 240.0,
      'total_loss': 480.0,
      'reason': 'Damaged',
      'notes': 'Outer packaging crushed during warehouse handling',
      'created_at': yesterdayTime.toIso8601String(),
    });
    await db.insert('stock_movements', {
      'id': 'sm_w1',
      'product_id': 'prod_2',
      'movement_type': 'WASTAGE',
      'quantity': 2.0,
      'unit_price': 240.0,
      'total_value': 480.0,
      'reference_id': 'w_1',
      'reason': 'Damaged stock discarded',
      'created_at': yesterdayTime.toIso8601String(),
    });

    await db.insert('wastage_records', {
      'id': 'w_2',
      'product_id': 'prod_7',
      'product_name': 'Masala Chai Premix',
      'quantity': 1.0,
      'unit': 'packet',
      'unit_cost': 95.0,
      'total_loss': 95.0,
      'reason': 'Expired',
      'notes': 'Best before date passed on display rack',
      'created_at': threeDaysAgo.toIso8601String(),
    });

    // 8. Business Expenses
    final expenses = [
      {
        'id': 'exp_1',
        'title': 'Corrugated Shipping Boxes',
        'amount': 2400.0,
        'category': 'Packaging',
        'date': today.toIso8601String(),
        'notes': '50 delivery boxes purchased',
        'created_at': today.toIso8601String(),
      },
      {
        'id': 'exp_2',
        'title': 'Tempo Delivery to Swargate',
        'amount': 850.0,
        'category': 'Transportation',
        'date': today.toIso8601String(),
        'notes': 'Delivered bulk order',
        'created_at': today.toIso8601String(),
      },
      {
        'id': 'exp_3',
        'title': 'Warehouse Electricity Bill',
        'amount': 3200.0,
        'category': 'Electricity',
        'date': yesterdayTime.toIso8601String(),
        'notes': 'Monthly MSEDCL bill',
        'created_at': yesterdayTime.toIso8601String(),
      },
      {
        'id': 'exp_4',
        'title': 'Daily Loader Wages',
        'amount': 1500.0,
        'category': 'Labour',
        'date': twoDaysAgo.toIso8601String(),
        'notes': '2 workers for truck unloading',
        'created_at': twoDaysAgo.toIso8601String(),
      },
    ];
    for (final exp in expenses) {
      await db.insert('expenses', exp);
    }
  }
}
