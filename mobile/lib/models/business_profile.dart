class BusinessProfile {
  final String businessName;
  final String ownerName;
  final String phone;
  final String? email;
  final String address;
  final String? gstin;
  final String tagline;
  final String invoiceTerms;
  final String currencySymbol;
  final String? logoPath;

  const BusinessProfile({
    this.businessName = 'Vyavhar Traders',
    this.ownerName = 'Ramesh Sharma',
    this.phone = '+91 98765 43210',
    this.email,
    this.address = 'Shop 14, APMC Market, Market Yard, Pune - 411037',
    this.gstin = '27AABCU9603R1ZM',
    this.tagline = 'Smart Business. Simple Hisaab.',
    this.invoiceTerms = 'Thank you for your business! All disputes subject to Pune jurisdiction.',
    this.currencySymbol = '₹',
    this.logoPath,
  });

  BusinessProfile copyWith({
    String? businessName,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    String? tagline,
    String? invoiceTerms,
    String? currencySymbol,
    String? logoPath,
    bool clearLogo = false,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      tagline: tagline ?? this.tagline,
      invoiceTerms: invoiceTerms ?? this.invoiceTerms,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business_name': businessName,
      'owner_name': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'gstin': gstin,
      'tagline': tagline,
      'invoice_terms': invoiceTerms,
      'currency_symbol': currencySymbol,
      'logo_path': logoPath,
    };
  }

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      businessName: map['business_name'] as String? ?? 'Vyavhar Traders',
      ownerName: map['owner_name'] as String? ?? 'Ramesh Sharma',
      phone: map['phone'] as String? ?? '+91 98765 43210',
      email: map['email'] as String?,
      address: map['address'] as String? ?? 'Shop 14, APMC Market, Pune',
      gstin: map['gstin'] as String?,
      tagline: map['tagline'] as String? ?? 'Smart Business. Simple Hisaab.',
      invoiceTerms: map['invoice_terms'] as String? ?? '',
      currencySymbol: map['currency_symbol'] as String? ?? '₹',
      logoPath: map['logo_path'] as String?,
    );
  }
}
