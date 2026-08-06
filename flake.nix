{
  description = "Oh My Pi flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          sources = {
            "x86_64-linux" = {
              url = "https://github.com/can1357/oh-my-pi/releases/download/v17.2.10/omp-linux-x64";
              sha256 = "sha256-T+VksjSCzWJ2caJBeEJJjJey9ytfijpO+4CU5iPfejM=";
            };
            "aarch64-linux" = {
              url = "https://github.com/can1357/oh-my-pi/releases/download/v17.2.10/omp-linux-arm64";
              sha256 = "sha256-yTXV0l62d6Ylk0+B9LIbD/BbZEAP656Q8C8O/jlnY4Y=";
            };
            "x86_64-darwin" = {
              url = "https://github.com/can1357/oh-my-pi/releases/download/v17.2.10/omp-darwin-x64";
              sha256 = "sha256-IGR/4Zqy5HRRZVXbXIE/XZrv/FVuRWzfnuiQB8ipi+8=";
            };
            "aarch64-darwin" = {
              url = "https://github.com/can1357/oh-my-pi/releases/download/v17.2.10/omp-darwin-arm64";
              sha256 = "sha256-43+j1NPusVtx1bRk/eUfkT45CXikjcM7TFJ7ju1yN8Y=";
            };
          };
          srcInfo = sources.${system} or (throw "Unsupported system: ${system}");
          linuxLibPath = pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            pkgs.glibc
            pkgs.openssl
            pkgs.zlib
          ];
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "oh-my-pi";
            version = "17.2.10";

            src = pkgs.fetchurl {
              inherit (srcInfo) url sha256;
            };

            dontUnpack = true;

            # Bun-compiled omp binaries on Linux break when auto-patched/stripped by stdenv.
            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
              pkgs.bash
              pkgs.makeWrapper
              pkgs.patchelf
            ];

            installPhase =
              if pkgs.stdenv.isLinux then
                ''
                  install -Dm755 "$src" "$out/libexec/omp"
                  patchelf --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" "$out/libexec/omp"
                  makeWrapper "$out/libexec/omp" "$out/bin/omp" \
                    --prefix LD_LIBRARY_PATH : "${linuxLibPath}"
                ''
              else
                ''
                  install -Dm755 "$src" "$out/bin/omp"
                '';

            dontStrip = pkgs.stdenv.isLinux;
            dontPatchELF = pkgs.stdenv.isLinux;
            doInstallCheck = pkgs.stdenv.isLinux;
            installCheckPhase = ''
              export HOME="$TMPDIR"
              "$out/bin/omp" --version >/dev/null
            '';

            meta = {
              mainProgram = "omp";
              homepage = "https://github.com/can1357/oh-my-pi";
              description = "Oh My Pi";
            };
          };
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/omp";
        };
      });

      homeManagerModules = {
        default = { config, lib, pkgs, ... }:
          let
            cfg = config.programs.oh-my-pi;
          in
          {
            options.programs.oh-my-pi = {
              enable = lib.mkEnableOption "oh-my-pi";
              package = lib.mkOption {
                type = lib.types.package;
                default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
                description = "oh-my-pi package to install.";
              };
              agents = lib.mkOption {
                type = lib.types.attrsOf (lib.types.submodule {
                  options = {
                    source = lib.mkOption {
                      type = lib.types.nullOr lib.types.path;
                      default = null;
                      description = "Path to a markdown agent file to install.";
                    };
                    text = lib.mkOption {
                      type = lib.types.nullOr lib.types.lines;
                      default = null;
                      description = "Inline markdown agent file content to install.";
                    };
                    executable = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "Whether the installed agent file should be executable.";
                    };
                  };
                });
                default = { };
                description = "Agent markdown files installed to ~/.omp/agents/agent/, where each attribute name becomes the filename.";
              };
            };

            config = lib.mkIf cfg.enable {
              home.packages = [ cfg.package ];
              home.file = lib.mapAttrs'
                (name: agentCfg:
                  lib.nameValuePair ".omp/agents/agent/${name}" ({
                    inherit (agentCfg) executable;
                  } // lib.optionalAttrs (agentCfg.source != null) {
                    source = agentCfg.source;
                  } // lib.optionalAttrs (agentCfg.text != null) {
                    text = agentCfg.text;
                  }))
                cfg.agents;
              assertions = [
                {
                  assertion = lib.all
                    (agentCfg: (agentCfg.source == null) != (agentCfg.text == null))
                    (lib.attrValues cfg.agents);
                  message = "Each programs.oh-my-pi.agents.<name> must set exactly one of `source` or `text`.";
                }
                {
                  assertion = lib.all (name: lib.hasSuffix ".md" name) (lib.attrNames cfg.agents);
                  message = "Each programs.oh-my-pi.agents.<name> must end with `.md`.";
                }
              ];
            };
          };
      };
    };
}
