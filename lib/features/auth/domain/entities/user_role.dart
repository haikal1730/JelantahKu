enum UserRole {
  warga,
  admin,
  owner,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.warga:
        return 'Warga';
      case UserRole.admin:
        return 'Admin Desa';
      case UserRole.owner:
        return 'Owner';
    }
  }

  String get description {
    switch (this) {
      case UserRole.warga:
        return 'Setor minyak jelantah & cek saldo';
      case UserRole.admin:
        return 'Kelola sensor tabung komunal & warga';
      case UserRole.owner:
        return 'Monitoring eksekutif & laporan wilayah';
    }
  }
}
