let
  pkgs = import ./nix/pkgs.nix;

  dfinitySdk = pkgs.dfinity-sdk {
    acceptLicenseAgreement = true;
  };

  shell = { ... }@args: (dfinitySdk.shell args).overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [
      pkgs.nodejs-12_x
    ];
  });
in
  {
    inherit shell;
  }
