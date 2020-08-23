{ pkgs
, cleanedSource
, pkg-def-extras ? []
, ghc-ver
, index-state
, index-sha256 ? null
, plan-sha256 ? null
, materialized ? null
, configureArgs ? ""
}:
let
  butcher-nix = pkgs.haskell-nix.callCabalProjectToNix {
    src = cleanedSource;
    inherit index-state index-sha256 plan-sha256 materialized configureArgs;
    # ghc = pkgs.haskell-nix.compiler.${ghc-ver};
    compiler-nix-name = ghc-ver;
  };
  butcher-plan = pkgs.haskell-nix.importAndFilterProject { inherit (butcher-nix) projectNix sourceRepos src; };
in rec {
  inherit butcher-nix butcher-plan pkgs;

  hsPkgs = 
    let
    in let pkg-set = pkgs.haskell-nix.mkCabalProjectPkgSet
              { plan-pkgs = butcher-plan;
                pkg-def-extras = pkg-def-extras;
                modules = [ 
                  { ghc.package = pkgs.haskell-nix.compiler.${ghc-ver}; }
                ];
              };
    in pkg-set.config.hsPkgs;

  inherit (hsPkgs) butcher;
  inherit (hsPkgs.butcher) checks;
  shell = hsPkgs.shellFor {
    # Include only the *local* packages of your project.
    packages = ps: with ps; [
      butcher
    ];

    # Builds a Hoogle documentation index of all dependencies,
    # and provides a "hoogle" command to search the index.
    withHoogle = false;

    # You might want some extra tools in the shell (optional).

    # Some common tools can be added with the `tools` argument
    # tools = { cabal = "3.2.0.0"; };
    # See overlays/tools.nix for more details

    tools = { ghcid = "0.8.7"; cabal = "3.2.0.0"; };

    # Some you may need to get some other way.
    buildInputs = with pkgs.haskellPackages;
      [ bash pkgs.nix ];

    # Prevents cabal from choosing alternate plans, so that
    # *all* dependencies are provided by Nix.
    exactDeps = true;
  };
}
