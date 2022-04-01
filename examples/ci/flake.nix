{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/21.11";
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
        });

        mkPackage = version:
          pkgs.runCommand "ci" {
            nativeBuildInputs = [
              pkgs.jq
            ];
            buildInputs = [
              dfinitySdk."${version}"
            ];
          } ''
            jq '.dfx = "${version}"' ${./dfx.json} > dfx.json
            dfx start --background
            dfx stop
            touch $out
          ''
        ;

        drvs =
          pkgs.lib.attrsets.filterAttrs
            (_name: value: pkgs.lib.attrsets.isDerivation value)
            dfinitySdk
        ;
      in
        {
          # `nix build`
          defaultPackage = mkPackage "latest";

          packages =
            pkgs.lib.attrsets.mapAttrs
              (name: _value: mkPackage name)
              drvs
          ;

          # packages."0.10.101" = mkPackage "0.10.101";

          # `nix develop`
          devShell = pkgs.mkShell {
            buildInputs = [
              dfinitySdk.latest
            ];
          };
        }
    );
}
