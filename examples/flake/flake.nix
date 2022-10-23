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
        })."0.9.3";
      in
        {
          # `nix build`
          defaultPackage = pkgs.runCommand "example" {
            buildInputs = [
              dfinitySdk
            ];
          } ''
            trap "dfx stop" EXIT
            cp ${./dfx.json} dfx.json
            dfx start --background --host 127.0.0.1:0
            WEBSERVER_PORT=$(cat .dfx/webserver-port)
            # dfx deploy --network "http://127.0.0.1:$WEBSERVER_PORT"
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
