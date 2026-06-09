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
            url = "https://github.com/can1357/oh-my-pi/releases/download/v15.8.0/omp-linux-x64";
            sha256 = "sha256-a0nNzh3jnv1dgxXPIpqs9cIa955OTlKXukINVgns7H8=";
            };
            "aarch64-linux" = {
            url = "https://github.com/can1357/oh-my-pi/releases/download/v15.8.0/omp-linux-arm64";
            sha256 = "sha256-1Mpkt3AD4c3+zTzILaMY7yNzxuEngUzykm3XsuFpH7U=";
            };
            "x86_64-darwin" = {
            url = "https://github.com/can1357/oh-my-pi/releases/download/v15.8.0/omp-darwin-x64";
            sha256 = "sha256-gCoZ/fMTzAFuea7UHVhkd7Cxkm30Tc3t3FQyCEVyPSo=";
            };
            "aarch64-darwin" = {
            url = "https://github.com/can1357/oh-my-pi/releases/download/v15.8.0/omp-darwin-arm64";
            sha256 = "sha256-RhgQRXZQSYV9sosiZdzMpqpYuqNZQKbzJCOH0+R+/iY=";
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
            version = "15.8.0";

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
            renderAgentField = key: value:
              lib.optionalString (value != null) "${key}: ${builtins.toJSON value}\n";
            hasGeneratedAgentConfig = agentCfg:
              agentCfg.name != null
              || agentCfg.description != null
              || agentCfg.extraDesc != null
              || agentCfg.tools != null
              || agentCfg.spawns != null
              || agentCfg.model != null
              || agentCfg.thinkingLevel != null
              || agentCfg.blocking != null
              || agentCfg.autoloadSkills != null
              || agentCfg.readSummarize != null
              || agentCfg.output != null
              || agentCfg.prompt != null;
            renderGeneratedAgent = agentCfg:
              let
                frontmatter =
                  [
                    "name: ${builtins.toJSON agentCfg.name}\n"
                    "description: ${builtins.toJSON agentCfg.description}\n"
                  ]
                  ++ lib.optional (agentCfg.tools != null) (renderAgentField "tools" agentCfg.tools)
                  ++ lib.optional (agentCfg.spawns != null) (renderAgentField "spawns" agentCfg.spawns)
                  ++ lib.optional (agentCfg.model != null) (renderAgentField "model" agentCfg.model)
                  ++ lib.optional (agentCfg.thinkingLevel != null) (renderAgentField "thinking-level" agentCfg.thinkingLevel)
                  ++ lib.optional (agentCfg.blocking != null) (renderAgentField "blocking" agentCfg.blocking)
                  ++ lib.optional (agentCfg.autoloadSkills != null) (renderAgentField "autoloadSkills" agentCfg.autoloadSkills)
                  ++ lib.optional (agentCfg.readSummarize != null) (renderAgentField "read-summarize" agentCfg.readSummarize)
                  ++ lib.optional (agentCfg.output != null) (renderAgentField "output" agentCfg.output);
                bodySections = lib.filter (section: section != null && section != "") [ agentCfg.extraDesc agentCfg.prompt ];
              in
              ''
                ---
                ${lib.concatStrings frontmatter}---
                ${lib.optionalString (bodySections != [ ]) "${lib.concatStringsSep "\n\n" bodySections}\n"}
              '';
            agentFileConfig = agentCfg:
              {
                inherit (agentCfg) executable;
              } // lib.optionalAttrs (agentCfg.source != null) {
                source = agentCfg.source;
              } // lib.optionalAttrs (agentCfg.text != null) {
                text = agentCfg.text;
              } // lib.optionalAttrs (hasGeneratedAgentConfig agentCfg && agentCfg.source == null && agentCfg.text == null) {
                text = renderGeneratedAgent agentCfg;
              };
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
                    name = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Generated agent frontmatter `name` field.";
                    };
                    description = lib.mkOption {
                      type = lib.types.nullOr lib.types.lines;
                      default = null;
                      description = "Generated agent frontmatter `description` field.";
                    };
                    extraDesc = lib.mkOption {
                      type = lib.types.nullOr lib.types.lines;
                      default = null;
                      description = "Additional text appended to `description` in generated frontmatter.";
                    };
                    tools = lib.mkOption {
                      type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
                      default = null;
                      description = "Generated agent frontmatter `tools` field.";
                    };
                    spawns = lib.mkOption {
                      type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
                      default = null;
                      description = "Generated agent frontmatter `spawns` field.";
                    };
                    model = lib.mkOption {
                      type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
                      default = null;
                      description = "Generated agent frontmatter `model` field.";
                    };
                    thinkingLevel = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Generated agent frontmatter `thinking-level` field.";
                    };
                    blocking = lib.mkOption {
                      type = lib.types.nullOr lib.types.bool;
                      default = null;
                      description = "Generated agent frontmatter `blocking` field.";
                    };
                    autoloadSkills = lib.mkOption {
                      type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
                      default = null;
                      description = "Generated agent frontmatter `autoloadSkills` field.";
                    };
                    readSummarize = lib.mkOption {
                      type = lib.types.nullOr lib.types.bool;
                      default = null;
                      description = "Generated agent frontmatter `read-summarize` field.";
                    };
                    output = lib.mkOption {
                      type = lib.types.nullOr lib.types.attrs;
                      default = null;
                      description = "Generated agent frontmatter `output` field.";
                    };
                    prompt = lib.mkOption {
                      type = lib.types.nullOr lib.types.lines;
                      default = null;
                      description = "Prompt body written after generated frontmatter.";
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
                  lib.nameValuePair ".omp/agents/agent/${name}" (agentFileConfig agentCfg))
                cfg.agents;
              assertions = [
                {
                  assertion = lib.all (agentCfg:
                    let
                      usesSource = agentCfg.source != null;
                      usesText = agentCfg.text != null;
                      usesGenerated = hasGeneratedAgentConfig agentCfg;
                    in
                    lib.count (mode: mode) [ usesGenerated usesSource usesText ] == 1)
                    (lib.attrValues cfg.agents);
                  message = "Each programs.oh-my-pi.agents.<name> must set exactly one mode: `source`, `text`, or generated fields.";
                }
                {
                  assertion = lib.all
                    (agentCfg:
                      let
                        usesGenerated = hasGeneratedAgentConfig agentCfg;
                      in
                      !usesGenerated || (agentCfg.name != null && agentCfg.description != null))
                    (lib.attrValues cfg.agents);
                  message = "Generated agents must set both `name` and `description`.";
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
