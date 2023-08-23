{
  description = "deb package builder";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
      flake-utils.lib.eachDefaultSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system};
          a = pkgs: programToPatch: pkgs.stdenv.mkDerivation {
            name = "${programToPatch.name}-deb";
            src = self;
            buildInputs = with pkgs; [
              patchelf # for un-patching /nix from binaries
              file # get file info
              nfpm # package to .deb, etc
              tree # debug
            ];
            buildPhase = ''
              # DEBUG:
              set -x
              cp -r ${programToPatch} outToPatch
              cd outToPatch

              # start to unpatch:
              for binary in ./bin/*; do
                # get binary target platform (interpreter)
                interpreter="$(file "$binary" | grep -Po '/nix/store/\w+-\w+-.+/lib/\Kld-[^,]+')"
                # debug
                ls -l "$binary"
                # make it read/write
                chmod +rw "$binary"
                # patch it
                patchelf --set-interpreter ${pkgs.glibc}/lib/"$interpreter" "$binary"
                # TODO: reset permissions (use setfacl/getfacl from acl?)

                # Check if it's an elf  # <- NOT NEEDED, patchelf does this

                # # Get file info
                # info="$(file "$binary")"
                # # DEBUG:
                # echo "$info"
                # # TODO: are there any things that aren't ELF or text?
                # if echo "$info" | grep -Fq 'ELF'; then
                #   isElf=true
                # else
                #   isElf=false
                #   # means it needs to be un-patched through other means
                #   continue
                # fi
                #
                # Get the interpreter of the file (ex: ld-linux-x86-64.so.2)
                # interpreter="$(echo "$info" | grep -Po '/nix/store/\w+-\w+-.+/lib/\Kld-[^,]+')"
                #
                # check if it is a binary (not a script)
                # if "$isElf"; then
                #   patchelf --set-interpreter ${pkgs.glibc}/lib/"$interpreter" "$binary"
                # fi
              done
              # continue to patch other files, scripts, remove rpath (see doc patchelf) etc…
              # …
              # call fpm to create the .deb and put the result in $out
              nfpm --help

              # echo heloooo
              # sleep 1
              # mkdir "$out"
              # echo "testing 123" > "$out"/test
              exit 1
            '';
          };
        in {
          packages = {
            default =
              let
                package = pkgs.hello;
              in
                a pkgs package;
          };
        });
}
