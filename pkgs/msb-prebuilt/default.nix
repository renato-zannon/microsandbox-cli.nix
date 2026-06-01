{
  lib,
  stdenvNoCC,
  fetchurl,
  patchelf,
  libcap_ng,
  libkrunfw,
}:

let
  version = "0.5.3";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://github.com/superradcompany/microsandbox/releases/download/v${version}/msb-linux-x86_64";
      hash = "sha256-dc8gm4b5YWYtmAsWCX3W3W6qWYTGKwmEwbflb8xPPs8=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/superradcompany/microsandbox/releases/download/v${version}/msb-linux-aarch64";
      hash = "sha256-I/QSizPxjkQp6fSTVZu+auyARbICBd/DjwN/4m3nAUk=";
    };
  };

  src = srcs.${stdenvNoCC.hostPlatform.system} or (throw "microsandbox: unsupported platform ${stdenvNoCC.hostPlatform.system}");

  rpath = lib.makeLibraryPath [
    libcap_ng
    libkrunfw
  ];
in
stdenvNoCC.mkDerivation {
  pname = "msb";
  inherit version src;

  dontUnpack = true;

  nativeBuildInputs = [ patchelf ];

  installPhase = ''
    runHook preInstall

    install -D -m 755 "$src" "$out/bin/msb"
    ln -s msb "$out/bin/microsandbox"

    patchelf \
      --set-rpath "${rpath}" \
      "$out/bin/msb"

    runHook postInstall
  '';

  meta = {
    description = "CLI tool for the microsandbox container runtime";
    homepage = "https://github.com/superradcompany/microsandbox";
    license = lib.licenses.asl20;
    mainProgram = "msb";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
