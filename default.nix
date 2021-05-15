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
        # Use `find $(dfx cache show) -type f -executable -print` on macOS to
        # help discover what to symlink.
        installPhase = ''
          export HOME=$TMP
          ./dfx cache install

          mkdir -p $out/cache
          cp --preserve=mode,timestamps -R $(./dfx cache show)/. $out/cache

          mkdir -p $out/bin
          ln -s $out/cache/dfx $out/bin/dfx
          ln -s $out/cache/ic-ref $out/bin/ic-ref
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
      dfinity-sdk-0_6_21 = makeSdk {
        inherit acceptLicenseAgreement system;
        systems = {
          "x86_64-darwin" = {
            # sha256 = self.stdenv.lib.fakeSha256;
            sha256 = "0i92rwk5x13q7f7nyrgc896w2mlbk63lkgmlrvmyciwbggjiv4pc";
          };
          "x86_64-linux" = {
            # sha256 = self.stdenv.lib.fakeSha256;
            sha256 = "06akn065x7vaqy56v5jn551zbw5a0wfxvn13q0hpskm2iwrwrpnb";
          };
        };
        version = "0.6.21";
      };

      dfinity-sdk-0_7_0-beta_8 = makeSdk {
        inherit acceptLicenseAgreement system;
        systems = {
          "x86_64-darwin" = {
            # sha256 = self.stdenv.lib.fakeSha256;
            sha256 = "19zq8n5ahqmbyp1bvhzv06zfaimxyfgzvanwfkf5px7gb1jcqf0m";
          };
          "x86_64-linux" = {
            # sha256 = self.stdenv.lib.fakeSha256;
            sha256 = "0nl29155076k23fx1j0zb92cr4p0dh8fk5cnjr67dy3nwlbygh3x";
          };
        };
        version = "0.7.0-beta.8";
      };
    in
      # https://sdk.dfinity.org/manifest.json
      {
        latest = dfinity-sdk-0_6_21;
        "0_6_21" = dfinity-sdk-0_6_21;
        "0_7_0-beta_8" = dfinity-sdk-0_7_0-beta_8;
      }
  );
in
  {
    dfinity-make-sdk = makeSdk;
    dfinity-sdk = allVersions;
  }
