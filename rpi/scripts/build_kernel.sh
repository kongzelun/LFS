KERNEL=kernel8
SCRIPT_DIR="$(pwd)"
KERNEL_OUT_DIR="$SCRIPT_DIR/kernel_out"
KERNEL_INSTALL_DIR="$SCRIPT_DIR/kernel_install"

set -e
# set -x

# # source
if [ ! -d linux ]; then
    git clone --depth 1 -b rpi-5.4.y https://github.com/raspberrypi/linux.git
fi
source_dir="linux"

# dependency
sudo apt install -y build-essential libncurses-dev flex bison bc libssl-dev

# .config file
if [ -f "${SCRIPT_DIR}"/config ]; then
    mkdir -p "${KERNEL_OUT_DIR}"
    cp "${SCRIPT_DIR}"/config "${KERNEL_OUT_DIR}"/.config
fi

if [ ! -f "${KERNEL_OUT_DIR}"/.config ]; then
    make -C "${source_dir}" O="${KERNEL_OUT_DIR}" bcmrpi3_defconfig
fi

make -C "${source_dir}" O="${KERNEL_OUT_DIR}" -j4 nconfig
cp "${KERNEL_OUT_DIR}"/.config "${SCRIPT_DIR}"/config

# build
make -C "${source_dir}" O="${KERNEL_OUT_DIR}" -j4 --output-sync=target Image modules dtbs

kernelrelease=$(make -C "${source_dir}" O="${KERNEL_OUT_DIR}" -s kernelrelease)
# image_name=$(make -C "${source_dir}" O="${KERNEL_OUT_DIR}" -s image_name)
image_name="arch/arm64/boot/Image"

echo "Kernel sources compiled successfully!"

# install
if [ -d "${KERNEL_INSTALL_DIR}" ]; then
    rm -rf "${KERNEL_INSTALL_DIR}"
fi
mkdir -p "${KERNEL_INSTALL_DIR}"/boot/overlays/

make -C "${source_dir}" O="${KERNEL_OUT_DIR}" \
    INSTALL_MOD_STRIP="--strip-unneeded" \
    INSTALL_MOD_PATH="${KERNEL_INSTALL_DIR}"/usr \
    -j4 --output-sync=target modules_install

cp "${KERNEL_OUT_DIR}/${image_name}" "${KERNEL_INSTALL_DIR}"/boot/$KERNEL.img
cp "${KERNEL_OUT_DIR}"/arch/arm64/boot/dts/broadcom/*.dtb "${KERNEL_INSTALL_DIR}"/boot/
cp "${KERNEL_OUT_DIR}"/arch/arm64/boot/dts/overlays/*.dtb* "${KERNEL_INSTALL_DIR}"/boot/overlays/

# rm "$tegra_kernel_install"/lib/modules/4.9.140-KZL/build
# cp -a "$KERNEL_OUT_DIR" "$tegra_kernel_install"/lib/modules/4.9.140-KZL/build
# rm "$tegra_kernel_install"/lib/modules/4.9.140-KZL/source
# cp -a "$source_dir" "$tegra_kernel_install"/lib/modules/4.9.140-KZL/source
