let
  owner = "NixOS";
  repo = "nixpkgs";
  rev = "21.11";
  sha256 = "162dywda2dvfj1248afxc45kcrg83appjd0nmdb541hl7rnncf02";
in
  import (builtins.fetchTarball {
    inherit sha256;
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
  })
