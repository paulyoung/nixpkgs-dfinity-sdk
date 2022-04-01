{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
    dfinity-sdk = {
      # url = "github:paulyoung/nixpkgs-dfinity-sdk";
      url = "../../";
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
        })."0.10.101";
      in
        {
          # `nix build`
          defaultPackage = pkgs.runCommand "example" {
            buildInputs = [
              dfinitySdk
            ];
          } ''
            cp ${./dfx.json} dfx.json
            dfx start --background
            dfx stop
            touch $out
          '';

          # `nix develop`
          devShell = pkgs.mkShell {
            buildInputs = [
              dfinitySdk
            ];
          };
        }
    );
}
