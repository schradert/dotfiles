{
  # TODO override runescape-launcher that isn't available on internet archive anymore
  # NOTE learn about buildFHSEnv
  # runescape.shortcut.exe = getExe pkgs.runescape;
  # canivete.pkgs.config.permittedInsecurePackages = ["openssl-1.1.1w"];
  # canivete.pkgs.config.allowUnfreePredicate = pkg: elem (getName pkg) ["RuneScape" "runescape-launcher"];
  # environment.systemPackages = [pkgs.runescape];
  flake.overlays.runescape = final: _: {
    rscplus = final.callPackage ({
      lib,
      stdenv,
      fetchFromGitHub,
      ant,
      jdk,
      jre,
      unixtools,
      makeWrapper,
      stripJavaArchivesHook,
    }:
      stdenv.mkDerivation rec {
        pname = "rscplus";
        version = lib.substring 0 7 src.rev;
        src = fetchFromGitHub {
          owner = "RSCPlus";
          repo = "rscplus";
          rev = "8880399c8fc9dc742755aa46e5d12f9142ab71c1";
          hash = "sha256-mbE4KjmwdhRGDCpXc4Q3ko+3pvoR4oTaVHRmUeaVG3A=";
        };
        nativeBuildInputs = [ant jdk unixtools.whereis stripJavaArchivesHook makeWrapper];
        buildPhase = ''
          runHook preBuild
          ant dist
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out/{bin,share/java}
          install --mode 644 dist/rscplus.jar $out/share/java/rscplus.jar
          makeWrapper ${jre}/bin/java $out/bin/rscplus --add-flags "-jar $out/share/java/rscplus.jar"
          runHook postInstall
        '';
        meta.mainProgram = "rscplus";
      }) {};
    saradomin = final.callPackage ({
      lib,
      buildDotnetModule,
      fetchFromGitLab,
      fetchFromGitHub,
    }:
      buildDotnetModule rec {
        pname = "saradomin";
        version = lib.substring 0 7 src.rev;
        # NOTE fetchSubmodules not working with upstream because Glitonea submodule path is missing .git suffix
        src = fetchFromGitLab {
          owner = "2009Scape";
          repo = "Saradomin-Launcher";
          rev = "ec6d05f098e32daf478ef698717183e7a125ae16";
          hash = "sha256-XDCX07BsR0iUoCkLk06AEV2DAbIlaxMjNe8t/Toq3U8=";
        };
        Glitonea = fetchFromGitHub {
          owner = "Ciastex";
          repo = "Glitonea";
          rev = "9fb6de8da53dbdde9d782ce4ab1c36c61d98ff71";
          hash = "sha256-6nef6E4SXFrSZuvhPCeafHVTX+0u6ObG3mpIZzMA8u0=";
        };
        prePatch = "cp -R ${Glitonea}/* Glitonea";
        nugetDeps = ./saradomin.json;
        executables = ["Saradomin"];
        meta.mainProgram = "Saradomin";
      }) {};
    hdos = final.callPackage ({
      stdenv,
      fetchurl,
      jre,
      makeWrapper,
    }:
      stdenv.mkDerivation rec {
        pname = "hdos";
        version = "20241106";
        src = fetchurl {
          url = "https://cdn.hdos.dev/launcher/latest/hdos-launcher.jar";
          hash = "sha256-00ddeR+ov6Tjrn+pscXoao4C0ek/iP9Hdlgq946pL8A=";
        };
        dontUnpack = true;
        nativeBuildInputs = [makeWrapper];
        installPhase = ''
          runHook preInstall
          mkdir -p $out/{bin,share/java}
          install --mode 644 $src $out/share/java/hdos.jar
          makeWrapper ${jre}/bin/java $out/bin/hdos --add-flags "-jar $out/share/java/hdos.jar"
          runHook postInstall
        '';
        meta.mainProgram = "hdos";
      }) {};
  };
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkPackageOption getExe mkIf mkMerge;
    inherit (config.dotfiles.programs.steam.external.runescape) hdos rscplus saradomin runelite;
    rscplusPath = ".config/RSCPlus/rscplus";
  in {
    options.dotfiles.programs.steam.external.runescape = {
      rscplus.enable = mkEnableOption "OpenRSC client RSC+";
      rscplus.package = mkPackageOption pkgs "rscplus" {};
      saradomin.enable = mkEnableOption "2009scape Saradomin-Launcher client access to Runescape 2";
      saradomin.package = mkPackageOption pkgs "saradomin" {};
      runelite.enable = mkEnableOption "Old School RuneScape client runelite";
      runelite.package = mkPackageOption pkgs "runelite" {};
      hdos.enable = mkEnableOption "High-Definition Old School RuneScape client";
      hdos.package = mkPackageOption pkgs "hdos" {};
    };
    config = {
      # NOTE RSC+ seems to rely on the location of the executable to generate data/caching
      home.file.${rscplusPath}.source = rscplus.package;
      dotfiles.programs.steam.external.manual = mkMerge [
        (mkIf rscplus.enable {"RSC+".shortcut.exe = "${config.home.homeDirectory}/${rscplusPath}/bin/rscplus";})
        (mkIf saradomin.enable {Saradomin.shortcut.exe = getExe saradomin.package;})
        (mkIf hdos.enable {HDOS.shortcut.exe = getExe hdos.package;})
        # TODO why doesn't runelite close properly?
        (mkIf runelite.enable {RuneLite.shortcut.exe = getExe runelite.package;})
      ];
    };
  };
}
