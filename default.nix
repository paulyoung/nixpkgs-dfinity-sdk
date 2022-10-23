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

      makeVersion = { systems, url, version }: (
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
              url = url;
            };
            nativeBuildInputs = [
              self.makeWrapper
            ] ++ self.lib.optional self.stdenv.isLinux [
              self.glibc.bin
              self.patchelf
              self.which
            ];
            # Use `find $(dfx cache show) -type f -executable -print` on macOS to
            # help discover what to symlink.
            installPhase = ''
              export HOME=$TMP

              ${self.lib.optionalString self.stdenv.isLinux ''
              local LD_LINUX_SO=$(ldd $(which iconv)|grep ld-linux-x86|cut -d' ' -f3)
              local IS_STATIC=$(ldd ./dfx | grep 'not a dynamic executable')
              local USE_LIB64=$(ldd ./dfx | grep '/lib64/ld-linux-x86-64.so.2')
              chmod +rw ./dfx
              test -n "$IS_STATIC" || test -z "$USE_LIB64" || patchelf --set-interpreter "$LD_LINUX_SO" ./dfx
              ''}

              ./dfx cache install

              local CACHE_DIR="$out/.cache/dfinity/versions/${version}"
              mkdir -p "$CACHE_DIR"
              cp --preserve=mode,timestamps -R $(./dfx cache show)/. $CACHE_DIR

              mkdir -p $out/bin

              for binary in dfx ic-ref ic-starter icx-proxy mo-doc mo-ide moc replica; do
                ${self.lib.optionalString self.stdenv.isLinux ''
                local BINARY="$CACHE_DIR/$binary"
                test -f "$BINARY" || continue
                local IS_STATIC=$(ldd "$BINARY" | grep 'not a dynamic executable')
                local USE_LIB64=$(ldd "$BINARY" | grep '/lib64/ld-linux-x86-64.so.2')
                chmod +rw "$BINARY"
                test -n "$IS_STATIC" || test -z "$USE_LIB64" || patchelf --set-interpreter "$LD_LINUX_SO" "$BINARY"
                ''}
                ln -s $CACHE_DIR/$binary $out/bin/$binary
              done

              wrapProgram $CACHE_DIR/dfx --set DFX_CACHE_ROOT $out --set DFX_CONFIG_ROOT $TMP
              rm $out/bin/dfx
              ln -s $CACHE_DIR/dfx $out/bin/dfx
            '';
            dontFixup = true;
            system = resolvedSystem;
            inherit version;
          }
      );

      buildFromGitHub = { commit, ... }@args:
        self.lib.fetchFromGitHub {
          owner = "dfinity";
          repo = "sdk";
          rev = "f4e24bfee825b4023f85123583f470fc1846008d";
          # sha256 = "FIXME";
          sha256 = self.lib.fakeSha256;
        }
      ;

      makeVersionFromGitHubRelease = { version, ... }@args:
        makeVersion (args // {
          url =  builtins.concatStringsSep "/" [
            "https://github.com"
            "dfinity"
            "sdk"
            "releases"
            "download"
            version
            "dfx-${version}-${resolvedSystem}.tar.gz"
          ];
        })
      ;

      makeVersionFromManifest = { version, ... }@args:
        makeVersion (args // {
          url =  builtins.concatStringsSep "/" [
            "https://sdk.dfinity.org"
            "downloads"
            "dfx"
            version
            "${resolvedSystem}"
            "dfx-${version}.tar.gz"
          ];
        })
      ;

      sdk-0_8_4 = makeVersionFromManifest {
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

      sdk-0_9_3 = makeVersionFromManifest {
        systems = {
          "x86_64-darwin" = {
            sha256 = "NMsETjzuZRVbnZ9slCmlHszB3GVrNGHBTKOZ6Y7EMEg=";
          };
          "x86_64-linux" = {
            sha256 = "wuuPDC34nrFc/eUdAownsb/FQ3/C7UXh4phzwZf0yQs=";
          };
        };
        version = "0.9.3";
      };

      sdk-0_10_101 = makeVersionFromGitHubRelease {
        systems = {
          "x86_64-darwin" = {
            # sha256 = self.lib.fakeSha256;
            sha256 = "YspeY5M87yRwm2iild0aMOTpVz75TKDrb5wEl6co7vI=";
          };
          "x86_64-linux" = {
            # sha256 = self.lib.fakeSha256;
            sha256 = "OI2m4KHsVEpOnAqZRo6BXB7rK0B8ra+w5f/h1zBtfb0=";
          };
        };
        version = "0.10.101";
      };

      # https://sdk.dfinity.org/manifest.json
      versions = {
        #latest = sdk-0_9_3;
        latest = sdk-0_10_101;
        "0.8.4" = sdk-0_8_4;
        "0.9.3" = sdk-0_9_3;
        "0.10.101" = sdk-0_10_101;
      };
    in
      versions // {
        inherit
          makeVersion
          makeVersionFromGitHubRelease
          makeVersionFromManifest
        ;
      }
  );
in
  {
    dfinity-sdk = sdkAttrSet;
  }
