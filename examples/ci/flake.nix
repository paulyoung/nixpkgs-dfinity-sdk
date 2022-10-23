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
    flake-utils.lib.eachSystem ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"] (
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
            trap "dfx stop" EXIT
            jq '.dfx = "${version}"' ${./dfx.json} > dfx.json
            dfx start --background --host 127.0.0.1:0
            WEBSERVER_PORT=$(cat .dfx/webserver-port)
            # dfx deploy --network "http://127.0.0.1:$WEBSERVER_PORT"
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
        rec {
          # `nix build`
          defaultPackage = packages."0.10.101";

          packages =
            pkgs.lib.attrsets.mapAttrs
              (name: _value: mkPackage name)
              drvs
          ;

          # `nix develop`
          devShell = pkgs.mkShell {
            buildInputs = [
              dfinitySdk.latest
            ];
          };
        }
    );
}
