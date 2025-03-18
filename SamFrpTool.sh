#!/bin/bash

# Instalar dependencias necesarias
echo "Instalando dependencias..."
sudo apt update && sudo apt install -y p7zip-full lz4 tar md5sum || {
    echo "Error instalando dependencias. Intenta instalar manualmente."; exit 1;
}

# Pedir la ubicación del firmware
read -p "Introduce la ruta del archivo AP.tar.md5: " firmware_path

# Verificar si el archivo existe
if [ ! -f "$firmware_path" ]; then
    echo "Error: No se encontró el archivo en la ruta proporcionada."; exit 1;
fi

# Crear carpeta de trabajo
work_dir="firmware_mod"
mkdir -p "$work_dir"
cp "$firmware_path" "$work_dir/AP.tar.md5"
cd "$work_dir"

# Extraer el firmware
echo "Extrayendo el firmware..."
7z x AP.tar.md5 || { echo "Error extrayendo AP.tar.md5"; exit 1; }

# Extraer system.img.lz4
echo "Extrayendo system.img.lz4..."
lz4 -d system.img.lz4 system.img || { echo "Error extrayendo system.img"; exit 1; }

# Montar la imagen del sistema
mkdir -p system_mount
sudo mount -o loop system.img system_mount || { echo "Error montando system.img"; exit 1; }

# Copiar el archivo build.prop para modificarlo
echo "Extrayendo build.prop..."
sudo cp system_mount/system/build.prop ./
sudo chown $USER:$USER build.prop

# Informar al usuario que edite build.prop
echo "Edita build.prop con cualquier editor de texto y luego presiona ENTER para continuar."
read -p "Presiona ENTER cuando termines de modificar build.prop..."

# Volver a copiar el archivo editado
sudo cp build.prop system_mount/system/build.prop

# Desmontar la imagen modificada
sudo umount system_mount
rm -rf system_mount

# Reconstruir system.img
echo "Reconstruyendo system.img..."
make_ext4fs -s -l 3G -a system system.img || { echo "Error creando system.img"; exit 1; }

# Convertir de nuevo a lz4
lz4 system.img system.img.lz4 || { echo "Error comprimiendo system.img.lz4"; exit 1; }

# Volver a empaquetar AP.tar.md5
echo "Empaquetando AP.tar.md5..."
tar -H ustar -c -f AP.tar system.img.lz4
md5sum -t AP.tar > AP.tar.md5
mv AP.tar.md5 AP_modificado.tar.md5

# Finalización
echo "Proceso completado. El firmware modificado se encuentra en: $work_dir/AP_modificado.tar.md5 , no seas malo."
