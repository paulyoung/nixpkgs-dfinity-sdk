self: super:

let
  error = message: builtins.throw ("[nixpkgs-dfinity-sdk] " + message);

  makeSdk = { acceptLicenseAgreement ? false, system, systems, version }: (
    if !acceptLicenseAgreement then
      error (builtins.concatStringsSep "\n" [
        ""
        ""
        "You must accept the license agreement at https://sdk.dfinity.org/sdk-license-agreement.txt and indicate so by setting:"
        ""
        "  pkgs.dfinity-sdk { acceptLicenseAgreement = true; };"
        ""
      ])
    else
      self.stdenv.mkDerivation {
        name = "dfinity-sdk-${version}-${system}";
        src = self.fetchzip {
          sha256 =
            if builtins.hasAttr system systems
            then systems.${system}.sha256
            else error ("unsupported system: " + system);
          stripRoot = false;
          url = builtins.concatStringsSep "/" [
            "https://sdk.dfinity.org"
            "downloads"
            "dfx"
            version
            "${system}"
            "dfx-${version}.tar.gz"
          ];
        };
        installPhase = ''
          export HOME=$TMP
          ./dfx cache install

          mkdir -p $out/cache
          cp --preserve=mode,timestamps -R $(./dfx cache show)/. $out/cache

          mkdir -p $out/bin
          ln -s $out/cache/dfx $out/bin/dfx
          ln -s $out/cache/didc $out/bin/didc
          ln -s $out/cache/ic-starter $out/bin/ic-starter
          ln -s $out/cache/mo-doc $out/bin/mo-doc
          ln -s $out/cache/mo-ide $out/bin/mo-ide
          ln -s $out/cache/moc $out/bin/moc
          ln -s $out/cache/replica $out/bin/replica
        '';
        meta.license = self.stdenv.lib.licenses.unfree;
      }
  );

  allVersions = {
    acceptLicenseAgreement ? false,
    system ? builtins.currentSystem
  }: (
    let
      dfinity-sdk-0_6_4 = makeSdk {
        inherit acceptLicenseAgreement system;
        systems = {
          "x86_64-darwin" = {
            sha256 = "1zn6dhc2a7m6bdn06krfqlf17jhh4fy89f22q83dgdypjz8mqiqp";
          };
          "x86_64-linux" = {
            sha256 = "02adr9ady2i14wwkahdann67cqgcyrclnc1gzr01m9awwkxrklz4";
          };
        };
        version = "0.6.4";
      };
    in
      {
        latest = dfinity-sdk-0_6_4;
        "0_6_4" = dfinity-sdk-0_6_4;
      }
  );
in
  {
    dfinity-make-sdk = makeSdk;
    dfinity-sdk = allVersions;
  }
