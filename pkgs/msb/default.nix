{
  lib,
  craneLib,
  fetchFromGitHub,
  pkgsCross,
  libcap_ng,
  libkrunfw,
}:

let
  version = "0.5.6";
  src = fetchFromGitHub {
    owner = "superradcompany";
    repo = "microsandbox";
    rev = "v${version}";
    hash = "sha256-rRQmS/V/x2iy5Z/XFMn3Q/Hcba5hp4qbCviQTPsXV7w=";
    fetchSubmodules = false;
  };

  libkrunfwExpectedVersion =
    let
      content = builtins.readFile "${src}/crates/utils/lib/lib.rs";
      line = lib.findFirst (l: lib.hasInfix "LIBKRUNFW_VERSION" l) null (lib.splitString "\n" content);
      v = if line == null then null else builtins.elemAt (lib.splitString "\"" line) 1;
    in
    if v == null then
      throw "Failed to extract LIBKRUNFW_VERSION from microsandbox source"
    else
      v;

  libkrunfwExpected = let
    expected = libkrunfwExpectedVersion;
    actual = libkrunfw.version;
    errorMsg = "Source code expected libkrunfw version ${expected} but building with ${actual}";
  in
    if (lib.assertMsg (expected == actual) errorMsg) then "libkrunfw.so.${expected}" else null;

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

  commonArgs = {
    pname = "microsandbox-cli";
    inherit version;
    inherit src cargoVendorDir;
    cargoExtraArgs = "--locked --no-default-features --features net,ssh -p microsandbox-cli";

    preBuild = ''
      mkdir -p build
      cp ${agentd}/bin/agentd build/agentd
      touch build/agentd
    '';

    buildInputs = [ libcap_ng ];
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
    mkdir -p "$out/lib"
    # msb resolves libkrunfw by exact filename relative to msb path, not via
    # SONAME lookup. Mirror upstream installer layout by placing the expected
    # versioned filename in $out/lib.
    # Ref: https://github.com/superradcompany/microsandbox/blob/v0.5.3/crates/utils/lib/lib.rs
    ln -s "${libkrunfw}/lib/libkrunfw.so.5" "$out/lib/${libkrunfwExpected}"
  '';

  meta = {
    description = "CLI tool for the microsandbox container runtime";
    homepage = "https://github.com/superradcompany/microsandbox";
    license = lib.licenses.asl20;
    mainProgram = "msb";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
})
