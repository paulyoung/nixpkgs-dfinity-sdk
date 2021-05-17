let
  pkgs = import ./nix/pkgs.nix;

  dfinitySdk = pkgs.dfinity-sdk {
    acceptLicenseAgreement = true;
  };

  shell = { version ? "0.7.0-beta.8", ... }@args:
    (dfinitySdk.shell (args // { version = version; })).overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [
        pkgs.nodejs-12_x
      ];
    });
in
  {
    inherit shell;
  }
