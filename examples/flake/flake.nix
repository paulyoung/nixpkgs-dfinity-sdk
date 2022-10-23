{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/21.11";
    flake-utils.url = "github:numtide/flake-utils";
    dfinity-sdk = {
      # Need a version of the SDK which is new enough to contain the stable64
      # APIs but a version of nixpkgs-dfinity-sdk which is old enough to not
      # encounter the read-only ./config directory issue. For newer versions of
      # the SDK we need to wait for a release which contains the fix from
      # https://github.com/dfinity/sdk/issues/2106 (commit
      # f4e24bfee825b4023f85123583f470fc1846008d)
      url = "github:paulyoung/nixpkgs-dfinity-sdk?rev=28bb54dc1912cd723dc15f427b67c5309cfe851e";
      # url = "github:paulyoung/nixpkgs-dfinity-sdk";
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
              # sha256 = pkgs.lib.fakeSha256;
              sha256 = "sha256-X2Y5V9hQDy8Qm4szkpcLo22jpPJfKWcApJg6ZXoKyVM=";
            };
            "x86_64-linux" = {
              sha256 = pkgs.lib.fakeSha256;
            };
          };
          version = "0.11.1";
        };

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
