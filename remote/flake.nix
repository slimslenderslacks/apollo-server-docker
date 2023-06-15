{
  description = "Node.js application flake";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, flake-utils, devshell, gitignore, ... }:
    {
      node-project =
        { nixpkgs }:
        flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              devshell.overlays.default
            ];
          };
          nodejs = pkgs.nodejs;
          node2nixOutput = import ./default.nix { inherit pkgs nodejs system; };

          # NOTE: may want to try https://github.com/svanderburg/node2nix/issues/301 to limit rebuilds
          nodeDeps = node2nixOutput.development.nodeDependencies;
          nodeDeps-production = node2nixOutput.production.nodeDependencies;
          app = pkgs.stdenv.mkDerivation {
            name = "example-ts-node";
            version = "0.1.0";
            src = gitignore.lib.gitignoreSource ./.;
            buildInputs = [ nodejs ];
            buildPhase = ''
              runHook preBuild
              ln -sf ${nodeDeps}/lib/node_modules ./node_modules
              export HOME=$(pwd)
              export PATH="${nodeDeps}/bin:$PATH"
              echo $PATH
              npm run build
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              # Note: you need some sort of `mkdir` on $out for any of the following commands to work
              mkdir -p $out/bin
              cp package.json $out/package.json
              cp -r dist $out/dist
              ln -sf ${nodeDeps-production}/lib/node_modules $out/node_modules
              cp dist/index.js $out/bin/apollo-server
              chmod a+x $out/bin/apollo-server
              runHook postInstall
            '';
          };
        in
        with pkgs; {
          packages.default = writeShellScriptBin "entrypoint" ''
            	  ${nodejs-slim}/bin/node ${app}/bin/apollo-server
            	'';
          devShells.default = pkgs.devshell.mkShell {
            packages = [ nodejs node2nix ];
            commands = [
              {
                name = "update-deps";
                help = "Update nix deps";
                command = ''
                  node2nix;
                '';
              }
            ];
          };
        });
    };

}