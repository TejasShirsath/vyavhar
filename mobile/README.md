# VYAVHAR – Smart Inventory & Business Management App

> **Tagline:** Smart Business. Simple Hisaab.  
> **Target Audience:** Small wholesale traders, distributors, and merchants. Designed to be intuitive and accessible even for non-technical users.

---

## 1. Overview & Key Capabilities

**VYAVHAR** is a production-quality, offline-first mobile application built with **Flutter** and **SQLite**. It streamlines the entire daily operational lifecycle of wholesale and retail businesses:

- **Inventory Tracking:** Real-time quantity monitoring, low-stock and out-of-stock alerts.
- **Strict Weighted Average Purchase Cost (WAC):** Automatic recalculation of inventory valuation when new batches are acquired at fluctuating rates.
- **Multi-Step Billing Experience:**
  1. *Add Items & Customer Details* (Quick pick existing customers, custom rates, subtotal).
  2. *Capture Product Photographs* (Integrated camera and gallery workflow to photograph actual delivered items).
  3. *Review & Taxes* (Discount, GST, additional charges, payment mode, paid amount).
- **Professional 2-Page PDF Invoice Generation:**
  - **Page 1:** Commercial Tax Invoice with branding, customer details, itemized table, taxes, discounts, and payment status.
  - **Page 2:** Proof of Delivery & Goods Dispatch Photographs arranged in a clean grid with timestamps and verification badges.
  - Print, Download, or Share directly via WhatsApp and other applications.
- **Financial Analytics & P&L Reports:**
  - Stock Valuation strictly at purchase cost (Weighted Average Cost).
  - Profit & Loss Statement (Gross Profit = Net Revenue - COGS; Net Profit = Gross Profit - Operating Expenses - Wastage Loss).
  - Wastage & Damage Tracker (Deducts stock and values financial loss at cost price).
  - Sales & Top Products trends.
  - Operating Expense management (Transportation, Packaging, Electricity, Labour, Rent, Misc).
- **100% Offline Persistence:** All business data and delivery photos persist locally on device. Includes complete JSON backup & restore.

---

## 2. Design System & UI Specification

The app faithfully implements the attached reference design language, upgraded to an executive **Deep Forest Green** palette:

| Element | Color / Value | Usage |
|---|---|---|
| **Primary** | `#176B45` (Deep Forest Green) | Brand identity, primary CTA buttons, hero cards |
| **Primary Container** | `#EBF4EE` (Mint Wash) | Selected chips, icon backgrounds, badges |
| **Secondary** | `#8BAF91` (Sage Green) | Subtle accents, borders, auxiliary graphs |
| **Background** | `#F8F9F5` (Warm Off-white) | Soft off-white screen background matching reference UI |
| **Surface** | `#FFFFFF` (Pure White) | Card containers with subtle 1px border (`#E4E9E2`) |
| **Primary Text** | `#202820` (Dark Charcoal) | High-contrast readable typography |
| **Secondary Text** | `#777F78` (Muted Slate) | Subtitles, SKU identifiers, metadata |
| **Status - Warning** | `#E68A00` / `#FFF7EB` | Low stock warnings, partial payment badges |
| **Status - Error** | `#D9383A` / `#FDEBEC` | Out of stock alerts, wastage loss, unpaid bills |
| **Status - Success** | `#1E8E5A` / `#E6F5ED` | Paid invoices, positive trends, profit highlights |

---

## 3. Technology Stack & Dependencies

- **Framework:** Flutter 3.47+ (Dart 3.13+)
- **Database:** SQLite via `sqflite` (with `sqflite_common_ffi` for desktop/testing support)
- **State Management:** `provider`
- **PDF Generation & Printing:** `pdf` & `printing`
- **Camera & Photos:** `image_picker` & `path_provider` (photos permanently stored in app document directory)
- **Charts:** `fl_chart`
- **Utilities:** `intl` (Indian Rupee `₹` number formatting, `DD/MM/YYYY` date formatting), `uuid`

---

## 4. Architectural Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Forest Green design system tokens
│   │   ├── app_dimens.dart         # Spacing, border radius, card shadows
│   │   └── app_typography.dart     # Typography styles
│   ├── database/
│   │   ├── app_database.dart       # SQLite database initialization, transactions, indexes
│   │   └── sample_data.dart        # Realistic Indian wholesale inventory seed data
│   ├── utils/
│   │   ├── currency_formatter.dart # Indian Rupee (₹) formatting (e.g. ₹24,580, ₹1.5L)
│   │   ├── date_formatter.dart     # DD/MM/YYYY date formatting & time helpers
│   │   └── id_generator.dart       # Sequence SKU (VYV-1001) & Invoice (INV-1048)
│   └── widgets/
│       ├── custom_button.dart      # Standardized primary and secondary buttons
│       ├── custom_text_field.dart  # Search pill & clean form input fields
│       ├── empty_state.dart        # Empty state illustrations & actions
│       ├── stat_card.dart          # Dashboard metric stat card
│       └── status_badge.dart       # Low Stock, Out of Stock, Paid, Pending badges
├── models/
│   ├── product.dart                # Product entity with SKU, WAC cost, selling rate, stock
│   ├── category.dart               # Category classification
│   ├── customer.dart               # Customer balance, contact details, total purchases
│   ├── supplier.dart               # Vendor contact & supplied totals
│   ├── invoice.dart                # Complete invoice entity
│   ├── invoice_item.dart           # Line item with purchase price captured at sale time (COGS)
│   ├── stock_movement.dart         # Full audit trail of purchases, sales, wastage, returns
│   ├── wastage_record.dart         # Product damage/expiry tracking at cost price
│   ├── expense.dart                # Operating business expense tracking
│   └── business_profile.dart       # Business identity, GSTIN, invoice terms
├── providers/
│   ├── inventory_provider.dart     # Product CRUD, category filtering, stock adjustments
│   ├── billing_provider.dart       # Stepper form, cart, photo attachments, invoice creation
│   ├── reports_provider.dart       # P&L, stock valuation, wastage, and expense analytics
│   ├── business_provider.dart      # Business profile, JSON backup export & restore
│   └── customer_provider.dart      # Customer and supplier relations
├── services/
│   ├── inventory_service.dart      # Weighted Average Cost calculations & stock transactions
│   ├── billing_service.dart        # Atomic invoice creation, stock deduction, cancellation
│   ├── photo_service.dart          # Camera capture, gallery picker, persistent file storage
│   ├── pdf_service.dart            # 2-Page professional PDF generation with delivery photos
│   ├── reports_service.dart        # P&L, COGS, Stock Valuation at purchase cost, Wastage
│   └── business_service.dart       # Offline database JSON export & restore
└── screens/
    ├── main_navigation_screen.dart # Bottom navigation (Home, Inventory, Bills, Reports)
    ├── home/
    │   ├── home_screen.dart        # Dashboard reproducing Reference Screen 1
    │   └── widgets/                # HeroSalesCard, QuickActionsRow, StockStatusCard, RecentActivityList
    ├── inventory/
    │   ├── inventory_screen.dart   # Product list reproducing Reference Screen 2
    │   ├── add_edit_product_screen.dart
    │   ├── product_detail_screen.dart
    │   ├── record_purchase_dialog.dart
    │   └── record_wastage_dialog.dart
    ├── billing/
    │   ├── bills_list_screen.dart
    │   ├── create_bill_screen.dart # Stepper UI reproducing Reference Screen 3
    │   ├── invoice_detail_screen.dart
    │   └── invoice_pdf_preview_screen.dart
    ├── reports/
    │   ├── reports_dashboard_screen.dart # Analytics dashboard with date filters
    │   └── widgets/                      # Valuation, P&L, Wastage, Sales, Expenses tabs
    └── settings/
        └── settings_screen.dart    # Profile editor, JSON backup & restore, sample data reset
```

---

## 5. Important Business Calculations

### A. Weighted Average Purchase Cost (WAC)
When new inventory is purchased, the product purchase price is recalculated using the weighted average formula:
$$\text{New Cost} = \frac{(\text{Current Stock} \times \text{Current Cost}) + (\text{Purchased Qty} \times \text{Purchase Rate})}{\text{Current Stock} + \text{Purchased Qty}}$$

### B. Stock Valuation
Stock value is strictly calculated at purchase cost:
$$\text{Total Stock Value} = \sum (\text{Current Stock}_i \times \text{Purchase Cost}_i)$$
*Never calculated using selling price.*

### C. Cost of Goods Sold (COGS) & Gross Profit
When an invoice is issued, each item captures the product's purchase price at that exact moment:
$$\text{COGS} = \sum (\text{Quantity Sold} \times \text{Purchase Cost})$$
$$\text{Gross Profit} = \text{Net Sales Revenue} - \text{COGS}$$

### D. Net Profit
$$\text{Net Profit} = \text{Gross Profit} - \sum \text{Operating Expenses} - \sum \text{Wastage Loss}$$

### E. Wastage Loss
$$\text{Wastage Loss} = \text{Wasted Quantity} \times \text{Purchase Cost}$$

### F. Invoice Cancellation & Reversal
If an invoice is cancelled:
- Its sales revenue and profit are excluded from all financial reports.
- All product quantities sold in that bill are automatically restored back to inventory.
- 'RETURN' stock movement records are created for audit integrity.

---

## 6. Setup & Execution Instructions

### Prerequisites
- Flutter SDK (v3.13.0 or higher)
- Android Studio / VS Code / Cursor
- Android Device or Emulator (API 21+)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/tejas/vyavhar.git
   cd vyavhar
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run automated tests:
   ```bash
   flutter test test/business_logic_test.dart
   ```
4. Run application:
   ```bash
   flutter run
   ```

### Default Sample Data
On first launch, Vyavhar seeds realistic Indian wholesale business data (Kaju Katli, Besan Laddu, Motichoor Laddu, Soan Papdi, Malpua Mix, Spices, existing invoices `INV-1048`, `INV-1047`, and operating expenses) so you can immediately explore and test all features. You can also reset or refresh this data anytime from **Settings → Reload Realistic Sample Data**.
