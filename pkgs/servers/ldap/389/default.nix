{ lib
, stdenv
, fetchFromGitHub
, autoconf
, automake
, cargo
, libtool
, pkg-config
, cracklib
, lmdb
, json_c
, linux-pam
, libevent
, libxcrypt
, nspr
, nss
, openldap
, withOpenldap ? true
, db
, withBdb ? true
, cyrus_sasl
, icu
, net-snmp
, withNetSnmp ? true
, krb5
, pcre2
, python3
, rustPlatform
, rustc
, openssl
, withSystemd ? lib.meta.availableOn stdenv.hostPlatform systemd, systemd
, zlib
, rsync
, fetchpatch
, withCockpit ? true
, withAsan ? false
}:

stdenv.mkDerivation rec {
  pname = "389-ds-base";
  version = "2.4.5";

  src = fetchFromGitHub {
    owner = "389ds";
    repo = pname;
    rev = "${pname}-${version}";
    hash = "sha256-12JCd2R00L0T5EPUNO/Aw2HRID+z2krNQ09RSX9Qkj8=";
  };

  patches = [
    (fetchpatch {
      name = "fix-32bit.patch";
      url = "https://github.com/389ds/389-ds-base/commit/1fe029c495cc9f069c989cfbb09d449a078c56e2.patch";
      hash = "sha256-b0HSaDjuEUKERIXKg8np+lZDdZNmrCTAXybJzF+0hq0=";
    })
    (fetchpatch {
      name = "CVE-2024-2199.patch";
      url = "https://git.rockylinux.org/staging/rpms/389-ds-base/-/raw/dae373bd6b4e7d6f35a096e6f27be1c3bf1e48ac/SOURCES/0004-CVE-2024-2199.patch";
      hash = "sha256-grANphTafCoa9NQy+FowwPhGQnvuCbfGnSpQ1Wp69Vg=";
    })
    (fetchpatch {
      name = "CVE-2024-3657.patch";
      url = "https://git.rockylinux.org/staging/rpms/389-ds-base/-/raw/dae373bd6b4e7d6f35a096e6f27be1c3bf1e48ac/SOURCES/0005-CVE-2024-3657.patch";
      hash = "sha256-CuiCXQp3PMiYERzFk7oH3T91yQ1dP/gtLNWF0eqGAQ4=";
    })
  ];

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    sourceRoot = "${src.name}/src";
    name = "${pname}-${version}";
    hash = "sha256-fE3bJROwti9Ru0jhCiWhXcuQdxXTqzN9yOd2nlhKABI=";
  };

  nativeBuildInputs = [
    autoconf
    automake
    libtool
    pkg-config
    python3
    cargo
    rustc
  ]
  ++ lib.optional withCockpit rsync;

  buildInputs = [
    cracklib
    lmdb
    json_c
    linux-pam
    libevent
    libxcrypt
    nspr
    nss
    cyrus_sasl
    icu
    krb5
    pcre2
    openssl
    zlib
  ]
  ++ lib.optional withSystemd systemd
  ++ lib.optional withOpenldap openldap
  ++ lib.optional withBdb db
  ++ lib.optional withNetSnmp net-snmp;

  postPatch = ''
    patchShebangs ./buildnum.py ./ldap/servers/slapd/mkDBErrStrs.py
  '';

  preConfigure = ''
    ./autogen.sh --prefix="$out"
  '';

  preBuild = ''
    mkdir -p ./vendor
    tar -xzf ${cargoDeps} -C ./vendor --strip-components=1
  '';

  configureFlags = [
    "--enable-rust-offline"
    "--enable-autobind"
  ]
  ++ lib.optionals withSystemd [
    "--with-systemd"
    "--with-systemdsystemunitdir=${placeholder "out"}/etc/systemd/system"
  ] ++ lib.optionals withOpenldap [
    "--with-openldap"
  ] ++ lib.optionals withBdb [
    "--with-db-inc=${lib.getDev db}/include"
    "--with-db-lib=${lib.getLib db}/lib"
  ] ++ lib.optionals withNetSnmp [
    "--with-netsnmp-inc=${lib.getDev net-snmp}/include"
    "--with-netsnmp-lib=${lib.getLib net-snmp}/lib"
  ] ++ lib.optionals (!withCockpit) [
    "--disable-cockpit"
  ] ++ lib.optionals withAsan [
    "--enable-asan"
    "--enable-debug"
  ];

  enableParallelBuilding = true;
  # Disable parallel builds as those lack some dependencies:
  #   ld: cannot find -lslapd: No such file or directory
  # https://hydra.nixos.org/log/h38bj77gav0r6jbi4bgzy1lfjq22k2wy-389-ds-base-2.3.1.drv
  enableParallelInstalling = false;

  doCheck = true;

  installFlags = [
    "sysconfdir=${placeholder "out"}/etc"
    "localstatedir=${placeholder "TMPDIR"}"
  ];

  passthru.version = version;

  meta = with lib; {
    homepage = "https://www.port389.org/";
    description = "Enterprise-class Open Source LDAP server for Linux";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.ners ];
  };
}
