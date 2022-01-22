let
  pkgs = import ./nix/nixpkgs.nix {
     overlays = import ./nix/overlays.nix;
   };

  shell = { version ? "0.7.0-beta.8", system ? "x86_64-darwin" }:
    let
      dfinitySdk = pkgs.dfinity-sdk {
        acceptLicenseAgreement = true;
        sdkSystem = system;
      };
    in
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
