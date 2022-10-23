{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/21.11";
    flake-utils.url = "github:numtide/flake-utils";

    dfinity-sdk = {
      # url = "github:paulyoung/nixpkgs-dfinity-sdk?rev=28bb54dc1912cd723dc15f427b67c5309cfe851e";
      url = "github:paulyoung/nixpkgs-dfinity-sdk";
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
        # })."0.9.3";
        }).makeVersion {
          systems = {
            "x86_64-darwin" = {
              sha256 = "sha256-0dmrknkFJ5UrGYqL2aH6xuUPJFlY6ae+4faHeF5rJBw=";
            };
            "x86_64-linux" = {
              sha256 = pkgs.lib.fakeSha256;
            };
          };
          version = "0.11.2";
        };

      in
        {
          # `nix build`
          defaultPackage = pkgs.runCommand "example" {
            buildInputs = [
              dfinitySdk
            ];
          } ''
            HOME=$TMP
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
