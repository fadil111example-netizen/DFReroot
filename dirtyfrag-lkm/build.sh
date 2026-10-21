#!/bin/sh

set -eux

cd "$(dirname "$0")"

# Hanya build khusus untuk Android 12 (android12-5.10) sesuai perangkat Anda
for version in android12-5.10; do
    echo "Memulai build modul kernel DirtyFrag untuk $version..."
    
    docker run --rm -it -v "$(pwd)":/src -w /src --user "$(id -u)" ghcr.io/ylarod/ddk-min:"$version" make $*
    
    if [ -f "dirtyfrag.ko" ]; then
        cp dirtyfrag.ko dirtyfrag-"$version".ko
        cp dirtyfrag.ko dirtyfrag-unstripped-"$version".ko
        
        # Optimalisasi ukuran file modul (.ko)
        llvm-objcopy --strip-unneeded \
          -R .comment -R .note.gnu.build-id -R .note.gnu.property -R .note.Linux -R .note.GNU-stack \
          -R .BTF -R .BTF.base -R .llvm_addrsig \
          -R .hyp.text -R .hyp.bss -R .hyp.rodata -R .hyp.event_ids \
          -R .hyp.patchable_function_entries -R .hyp.data \
          dirtyfrag-"$version".ko
        
        # Salin otomatis ke folder jni aplikasi
        cp dirtyfrag-"$version".ko ../app/src/main/jni/dirtyfrag-"$version".ko
        echo "Berhasil! Modul untuk $version telah disalin ke folder jni."
    else
        echo "Error: file dirtyfrag.ko gagal di-compile untuk $version"
        exit 1
    fi
done
