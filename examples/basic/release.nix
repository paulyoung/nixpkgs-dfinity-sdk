let
  pkgs = import ./nix/nixpkgs.nix {
     overlays = import ./nix/overlays.nix;
   };

  build = { version ? "0.9.3", system ? builtins.currentSystem }:
    let
      dfinitySdk = pkgs.dfinity-sdk {
        acceptLicenseAgreement = true;
        sdkSystem = system;
      };
    in
      pkgs.runCommand "ci" {
        nativeBuildInputs = [
          pkgs.jq
        ];
        buildInputs = [
          dfinitySdk."${version}"
          pkgs.nodejs-12_x
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

  shell = { version ? "0.9.3", system ? builtins.currentSystem }:
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
    inherit build shell;
  }
