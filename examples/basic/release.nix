let
  pkgs = import ./nix/nixpkgs.nix {
    config = {
      allowUnfree = true;
    };
    overlays = import ./nix/overlays.nix;
  };

  withEnv = fn: { system ? builtins.currentSystem, version ? "0.6.4" }: (
    let
      allVersions = pkgs.dfinity-sdk {
        inherit system;
        acceptLicenseAgreement = true;
      };
      key = builtins.replaceStrings ["."] ["_"] version;
    in
      fn {
        dir = "$HOME/.cache/dfinity/versions/${version}";
        sdk = allVersions.${key};
      }
  );

  shell = withEnv ({ dir, sdk }: pkgs.mkShell {
    buildInputs = [
      sdk
    ];
    shellHook = ''
      export HOME=$TMP
      chmod -R --silent 755 ${dir}
      mkdir -p ${dir}
      cp --no-clobber --preserve=mode,timestamps -R ${sdk}/cache/. ${dir}
    '';
  });
in
  {
    inherit shell;
  }
