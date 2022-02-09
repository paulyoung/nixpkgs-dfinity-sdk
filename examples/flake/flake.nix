{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/21.11";
    flake-utils.url = "github:numtide/flake-utils";
    dfinity-sdk = {
      url = "github:paulyoung/nixpkgs-dfinity-sdk";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, dfinity-sdk }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: (import dfinity-sdk) final prev)
          ];
        };

        dfinitySdk = (pkgs.dfinity-sdk {
          acceptLicenseAgreement = true;
          sdkSystem = system;
        })."0.8.4";
      in
        {
          # `nix develop`
          devShell = pkgs.mkShell {
            buildInputs = [
              dfinitySdk
            ];
          };
        }
    );
}
