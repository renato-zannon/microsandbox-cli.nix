{
  lib,
  craneLib,
  fetchFromGitHub,
  pkgsCross,
  patchelf,
  libcap_ng,
  libkrunfw,
}:

let
  version = "0.5.3";
  src = fetchFromGitHub {
    owner = "superradcompany";
    repo = "microsandbox";
    rev = "v${version}";
    hash = "sha256-BUwZeSQXO73rU0WULG/TdwBX6+LK79nTFCDYRc09pBI=";
    fetchSubmodules = false;
  };

  cargoVendorDir = craneLib.vendorCargoDeps { inherit src; };

  agentd = craneLib.buildPackage {
    pname = "microsandbox-agentd";
    inherit version;
    inherit src cargoVendorDir;

    CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER =
      "${pkgsCross.musl64.stdenv.cc}/bin/${pkgsCross.musl64.stdenv.cc.targetPrefix}cc";

    depsBuildBuild = [ pkgsCross.musl64.stdenv.cc ];
    cargoExtraArgs = "--locked -p microsandbox-agentd";
    doCheck = false;
  };

  rpath = "${libkrunfw}/lib:${lib.makeLibraryPath [ libcap_ng ]}";

  commonArgs = {
    pname = "microsandbox-cli";
    inherit version;
    inherit src cargoVendorDir;
    cargoExtraArgs = "--locked --no-default-features --features net,ssh -p microsandbox-cli";

    postPatch = ''
      rm .cargo/config.toml
    '';
    RUSTFLAGS = "-C link-args=-Wl,-rpath,${rpath}";

    preBuild = ''
      mkdir -p build
      cp ${agentd}/bin/agentd build/agentd
      touch build/agentd
    '';

    buildInputs = [ libcap_ng ];
    nativeBuildInputs = [ patchelf ];
    doCheck = false;
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (commonArgs // {
  inherit cargoArtifacts;
  pname = "msb";
  inherit version;

  postInstall = ''
    ln -s msb "$out/bin/microsandbox"
    patchelf --set-rpath "${rpath}" "$out/bin/msb"
  '';

  dontPatchELF = true;

  meta = {
    description = "CLI tool for the microsandbox container runtime";
    homepage = "https://github.com/superradcompany/microsandbox";
    license = lib.licenses.asl20;
    mainProgram = "msb";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
})
