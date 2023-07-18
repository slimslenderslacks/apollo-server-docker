{
  description = "Sample Nix Apollo Server";
  inputs = {
    platform-engineering.url = "github:slimslenderslacks/nix-modules";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, platform-engineering }:
    platform-engineering.node-project
      {
        inherit nixpkgs;
        dir = ./.;
        name = "apollo-server";
        version = "0.1.0";
      };
}

