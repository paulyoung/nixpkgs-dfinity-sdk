self: super:

let
  error = message: builtins.throw ("[nixpkgs-dfinity-sdk] " + message);

  sdkAttrSet = {
    acceptLicenseAgreement ? false,
    sdkSystem ? builtins.currentSystem
  }: (
    let
      resolvedSystem =
        if sdkSystem == "aarch64-darwin"
        then "x86_64-darwin"
        else sdkSystem;

      makeVersion = { systems, version }: (
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
            name = "dfinity-sdk-${version}-${resolvedSystem}";
            src = self.fetchzip {
              sha256 =
                if builtins.hasAttr resolvedSystem systems
                then systems.${resolvedSystem}.sha256
                else error ("unsupported system: " + resolvedSystem);
              stripRoot = false;
              url = builtins.concatStringsSep "/" [
                "https://sdk.dfinity.org"
                "downloads"
                "dfx"
                version
                "${resolvedSystem}"
                "dfx-${version}.tar.gz"
              ];
            };
            nativeBuildInputs = [
              self.makeWrapper
            ] ++ self.lib.optional self.stdenv.isLinux [
              self.glibc.bin
              self.patchelf
              self.which
              self.autoPatchelfHook
            ];
            buildInputs = [
              self.stdenv.cc.cc.lib
              self.libunwind
            ];
            # Use `find $(dfx cache show) -type f -executable -print` on macOS to
            # help discover what to symlink.
            installPhase = ''
              export HOME=$TMP

              chmod +rw ./dfx
              autoPatchelf .
              ./dfx cache install

              local CACHE_DIR="$out/.cache/dfinity/versions/${version}"
              mkdir -p "$CACHE_DIR"
              cp --preserve=mode,timestamps -R $(./dfx cache show)/. $CACHE_DIR

              mkdir -p $out/bin

              addAutoPatchelfSearchPath $CACHE_DIR

              for binary in dfx ic-ref ic-starter icx-proxy mo-doc mo-ide moc replica ; do
                ln -s $CACHE_DIR/$binary $out/bin/$binary
              done

              wrapProgram $CACHE_DIR/dfx --set DFX_CACHE_ROOT $out
              rm $out/bin/dfx
              ln -s $CACHE_DIR/dfx $out/bin/dfx
            '';
            system = resolvedSystem;
            inherit version;
          }
      );

      sdk-0_6_21 = makeVersion {
        systems = {
          "x86_64-darwin" = {
            sha256 = "0i92rwk5x13q7f7nyrgc896w2mlbk63lkgmlrvmyciwbggjiv4pc";
          };
          "x86_64-linux" = {
            sha256 = "06akn065x7vaqy56v5jn551zbw5a0wfxvn13q0hpskm2iwrwrpnb";
          };
        };
        version = "0.6.21";
      };

      sdk-0_7_0-beta_8 = makeVersion {
        systems = {
          "x86_64-darwin" = {
            sha256 = "19zq8n5ahqmbyp1bvhzv06zfaimxyfgzvanwfkf5px7gb1jcqf0m";
          };
          "x86_64-linux" = {
            sha256 = "0nl29155076k23fx1j0zb92cr4p0dh8fk5cnjr67dy3nwlbygh3x";
          };
        };
        version = "0.7.0-beta.8";
      };

      sdk-0_8_4 = makeVersion {
        systems = {
          "x86_64-darwin" = {
            sha256 = "JJzZzUJtrgmKJdxXGVJedhP5t9maxh3YjIq1xhTcvfU=";
          };
          "x86_64-linux" = {
            sha256 = "yht96jUJ8gTK5Ual1ofItyRBnQ+qIrbk0lOlefu/L7I=";
          };
        };
        version = "0.8.4";
      };

      sdk-0_9_2 = makeVersion {
        systems = {
          "x86_64-darwin" = {
            # sha256 = self.lib.fakeSha256;
            sha256 = "UITKzQ9XzlsyO4DU72Ah2VH8736eQeW8GL6hzJHTaYA=";
          };
          "x86_64-linux" = {
            # sha256 = self.lib.fakeSha256;
            sha256 = "41NP4AGp5Ve1Srm9a2jweOEEu6iKDGJEBr+SYtrqUSM=";
          };
        };
        version = "0.9.2";
      };

      sdk-0_14_4 = makeVersion {
        systems = {
          "x86_64-darwin" = {
            sha256 = self.lib.fakeSha256;
            # sha256 = "UITKzQ9Xzlsy00DU72Ah2VH8736eQeW8GL6hzJHTaYA=";
          };
          "x86_64-linux" = {
            # sha256 = self.lib.fakeSha256;
            sha256 = "sha256-l48yDQ8EEpcloQh0KH88LJe5WEyAPL2Y5eWcV0qOwB0=";
          };
        };
        version = "0.14.4";
      };

      # https://sdk.dfinity.org/manifest.json
      versions = {
        latest = sdk-0_14_4;
        "0.6.21" = sdk-0_6_21;
        "0.7.0-beta.8" = sdk-0_7_0-beta_8;
        "0.8.4" = sdk-0_8_4;
        "0.9.2" = sdk-0_9_2;
        "0.14.4" = sdk-0_14_4;
      };
    in
      versions // { inherit makeVersion; }
  );
in
  {
    dfinity-sdk = sdkAttrSet;
  }
