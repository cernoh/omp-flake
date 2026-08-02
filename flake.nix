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
              url = "https://github.com/can1357/oh-my-pi/releases/download/v17.2.4/omp-linux-x64";
              sha256 = "sha256-pucIbzuAf2ilsItJWX9DSeXONzZWObevXpyP41mYmEA=";
            };
            "aarch64-linux" = {
              url = "https://github.com/can1357/oh-my-pi/releases/download/v17.2.4/omp-linux-arm64";
              sha256 = "sha256-rEc8v2HMGiYH0og5MOZB4V6Oedos3UL/7I1wGthaIZw=";
            };
            "x86_64-darwin" = {
              url = "https://github.com/can1357/oh-my-pi/releases/download/v17.2.4/omp-darwin-x64";
              sha256 = "sha256-mXvAyYrCvTAQv4b947dTR4Mt1cEQvGxgOs5n5wokn5U=";
            };
            "aarch64-darwin" = {
              url = "https://github.com/can1357/oh-my-pi/releases/download/v17.2.4/omp-darwin-arm64";
              sha256 = "sha256-850lbGsuzn8uuFwk/Ef/vjmheW6m7qJgWtVk/OQsQI4=";
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
            version = "17.2.4";

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
