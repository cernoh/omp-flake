# omp-flake

Nix flake packaging for [Oh My Pi](https://github.com/can1357/oh-my-pi).

## What this flake provides

- A default package (`packages.<system>.default`) that installs the `omp` binary.
- A default app (`apps.<system>.default`) for `nix run`.
- A Home Manager module (`homeManagerModules.default`) exposing `programs.oh-my-pi`.

Supported systems:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Usage

Run directly:

```bash
nix run github:cernoh/omp-flake
```

Build package:

```bash
nix build github:cernoh/omp-flake
```

Use in another flake:

```nix
{
  inputs.omp-flake.url = "github:cernoh/omp-flake";

  outputs = { self, nixpkgs, omp-flake, ... }: {
    # Example: expose package
    packages.x86_64-linux.omp = omp-flake.packages.x86_64-linux.default;
  };
}
```

Home Manager module example:

```nix
{
  imports = [ omp-flake.homeManagerModules.default ];

  programs.oh-my-pi = {
    enable = true;
    agents = {
      "my-agent.md" = {
        name = "my-agent";
        description = "My custom agent";
        extraDesc = "Additional behavior details shown with the description.";
        tools = [ "read" "search" "find" "web_search" ];
        model = "pi/smol";
        thinkingLevel = "med";
        prompt = ''
          You are my custom agent.
        '';
      };
    };
  };
}
```

Available Home Manager options:

- `programs.oh-my-pi.enable`: Enables installation of Oh My Pi through Home Manager.
- `programs.oh-my-pi.package`: Overrides which `oh-my-pi` package gets installed. By default, this uses `omp-flake.packages.<system>.default`.
- `programs.oh-my-pi.agents`: Attribute set of markdown agent files installed to `~/.omp/agents/agent/`; each attribute name becomes the destination filename and must end with `.md`.
  - `<name>.source`: Path to a markdown file copied into `~/.omp/agents/agent/<name>`.
  - `<name>.text`: Inline markdown contents written to `~/.omp/agents/agent/<name>`.
  - Generated markdown mode (set these instead of `source`/`text`):
    - `<name>.name` (required): Frontmatter `name`.
    - `<name>.description` (required): Frontmatter `description`.
    - `<name>.extraDesc`: Extra text written below the frontmatter `---` line (before `prompt`).
    - `<name>.tools`: Frontmatter `tools`.
    - `<name>.spawns`: Frontmatter `spawns`.
    - `<name>.model`: Frontmatter `model`.
    - `<name>.thinkingLevel`: Frontmatter `thinking-level`.
    - `<name>.blocking`: Frontmatter `blocking`.
    - `<name>.autoloadSkills`: Frontmatter `autoloadSkills`.
    - `<name>.readSummarize`: Frontmatter `read-summarize`.
    - `<name>.output`: Frontmatter `output`.
    - `<name>.prompt`: Body text written after frontmatter.
  - `<name>.executable`: Marks the installed file as executable (default: `false`).
  - Exactly one mode must be used: `<name>.source`, `<name>.text`, or generated fields.

## Development

Validate flake outputs:

```bash
nix flake check
```
