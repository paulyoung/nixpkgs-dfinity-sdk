let
  pkgs = import ./nix/nixpkgs.nix {
     overlays = import ./nix/overlays.nix;
   };

  dfinitySdk = pkgs.dfinity-sdk {
    acceptLicenseAgreement = true;
    sdkSystem = "x86_64-darwin";
  };

  shell = { version ? "0.7.0-beta.8", ... }:
    pkgs.mkShell {
      nativeBuildInputs = [
        dfinitySdk.${version}
        pkgs.nodejs-12_x
      ];
    };
in
  {
    inherit shell;
  }
