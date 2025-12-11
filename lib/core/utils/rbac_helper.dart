class RBACHelper {
  // Check if user can access specific menu
  static bool canAccessMenu(String? userRole, String menuName) {
    if (userRole == null) return false;
    if (userRole == 'admin') return true;

    final permissions = _menuPermissions[menuName] ?? [];
    return permissions.contains(userRole);
  }

  // Menu permissions mapping
  static const Map<String, List<String>> _menuPermissions = {
    // User Management - Admin Only
    'users': ['admin'],

    // Purchase Requisition - All can access
    'pr': ['admin', 'purchasing', 'warehouse', 'finance', 'kadiv', 'user'],

    // PR History - All can see their own
    'pr_history': [],

    // PR Approval - Admin, Purchasing, Kadiv
    'pr_approval': ['admin', 'kadiv'],

    // Purchase Order - Admin, Purchasing
    'po': ['admin', 'purchasing'],

    // PO Approval - Admin, Kadiv
    'po_approval': ['admin', 'kadiv'],

    // Assessment Product - Admin, Kadiv
    'assessment_product': ['admin', 'kadiv'],

    // Assessment Supplier - Admin, Kadiv
    'assessment_supplier': ['admin', 'kadiv'],

    // Master Product - Admin, Kadiv
    'master_product': [
      'admin',
    ],

    // Goods Receipt (LPB) -Admin, Warehouse, Purchasing
    'receipt': ['admin', 'warehouse', 'finance'],

    // Inventory - Admin, Warehouse
    'inventory': ['admin', 'warehouse'],

    // Asset - Admin, Warehouse
    'asset': ['admin', 'warehouse'],

    // Payment - Admin, Finance
    'Payment': ['admin', 'finance'],

    // Suppliers - Admin, Purchasing
    'suppliers': ['admin', 'purchasing'],
  };

  // Get role display name
  static String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'purchasing':
        return 'Purchasing';
      case 'warehouse':
        return 'Warehouse';
      case 'finance':
        return 'Finance';
      case 'kadiv':
        return 'Head of Division';
      default:
        return role;
    }
  }

  // Get role color
  static String getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return '#E74C3C'; // Red
      case 'purchasing':
        return '#3498DB'; // Blue
      case 'warehouse':
        return '#9B59B6'; // Purple
      case 'finance':
        return '#27AE60'; // Green
      case 'kadiv':
        return '#F39C12'; // Orange
      case 'user':
        return '#95A5A6'; // Gray
      default:
        return '#34495E'; // Dark Gray
    }
  }

  // Check if user can perform action
  static bool canPerformAction(String? userRole, String action) {
    if (userRole == null) return false;
    if (userRole == 'admin') return true;

    final actions = _actionPermissions[action] ?? [];
    return actions.contains(userRole);
  }

  // Action permissions
  static const Map<String, List<String>> _actionPermissions = {
    'create_pr': [
      'admin',
      'purchasing',
      'warehouse',
      'finance',
      'kadiv',
      'user'
    ],
    'approve_pr': ['admin', 'purchasing', 'kadiv'],
    'reject_pr': ['admin', 'purchasing', 'kadiv'],
    'create_po': ['admin', 'purchasing'],
    'approve_po': ['admin', 'warehouse', 'purchasing'],
    'manage_inventory': ['admin', 'warehouse'],
    'manage_asset': ['admin', 'warehouse'],
    'create_payment': ['admin', 'finance'],
    'verify_payment': ['admin', 'finance'],
    'process_payment': ['admin', 'finance'],
    'manage_users': ['admin'],
    'manage_suppliers': ['admin', 'purchasing'],
  };
}
