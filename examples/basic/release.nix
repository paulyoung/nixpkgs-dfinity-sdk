let
  pkgs = import ./nix/nixpkgs.nix {
    config = {
      allowUnfree = true;
    };
    overlays = import ./nix/overlays.nix;
  };

  withEnv = fn: { system ? builtins.currentSystem, version ? "latest" }: (
    let
      allVersions = pkgs.dfinity-sdk {
        inherit system;
        acceptLicenseAgreement = true;
      };
      resolvedVersion =
        if version == "latest"
        then allVersions.latest.version
        else version;
      key = builtins.replaceStrings ["."] ["_"] resolvedVersion;
    in
      fn {
        dir = "$HOME/.cache/dfinity/versions/${resolvedVersion}";
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
