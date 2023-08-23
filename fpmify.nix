{stdenv, patchelf, programToPatch}:

stdenv.mkDerivation {
  buildInputs = [ patchelf ];
  buildPhase = ''
    mkdir outToPatch
    cp -r ${programToPatch} outToPatch
    cd outToPatch
    # start to unpatch:
    for binary in $out/bin/*; do
      # todo: check if it is a binary (not a script)
      # todo: you might check what is the interpreter of the original file as their are multiple (32 bits/64 bits), like maybe you can just strip the /nix/store part of the file
      patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 "$binary"
    done
    # continue to patch other files, scripts, remove rpath (see doc patchelf) etc…
    # …
    # call fpm to create the .deb and put the result in $out
  '';
}
