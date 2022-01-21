let
  pkgs = import ./nix/nixpkgs.nix {
     config = {
       allowUnfree = true;
     };
     overlays = import ./nix/overlays.nix;
   };

  dfinitySdk = pkgs.dfinity-sdk {
    acceptLicenseAgreement = true;
  };

  shell = { version ? "0.7.0-beta.8", ... }@args:
    ((pkgs.dfinity-sdk {
        acceptLicenseAgreement = true;
        sdkSystem = args.system;
    }).shell (args // { version = version; })).overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [
        pkgs.nodejs-12_x
      ];
    });
in
  {
    inherit shell;
  }
