{
  description = "Sample Nix Apollo Server";
  inputs = {
    platform-engineering.url = "./remote";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }@inputs:
    inputs.platform-engineering.node-project
      {
        inherit nixpkgs;
        dir = ./.;
      };
}

