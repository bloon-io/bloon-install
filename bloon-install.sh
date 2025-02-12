#!/bin/sh

set -u

func_MAIN() {

    # --------------------------------------------------
    func_CHECK_SUDO_PERMISSION

    # --------------------------------------------------
    echo
    echo "[BLOON-install] Checking dependencies..."
    func_CHECK_AND_INSTALL_DEPENDENCIES
    echo
    echo "[BLOON-install] Dependencies check complete."

    # --------------------------------------------------
    func_DOWNLOAD_AND_EXTARCT_BINARY

    # --------------------------------------------------
    echo
    echo "[BLOON-install] Setting up environment..."

    # This function is totally the same as the function in the DEB "postinst" script
    func_SETUP_BLOON_ENV

    sudo chmod 755 /opt/BLOON/bloon-uninstall.sh

    echo
    echo "[BLOON-install] Environment setup complete."

    # --------------------------------------------------
    rm -rf /tmp/___bloon-init___*

    # --------------------------------------------------
    echo
    echo "[BLOON-install] Installation complete."

    echo
    echo "[BLOON-install] You can now use the following command or click the BLOON icon in the application menu to launch BLOON:"
    echo "    bloon"
    echo
    echo "[BLOON-install] If you want to uninstall BLOON, please run the following command:"
    echo "    /opt/BLOON/bloon-uninstall.sh"
    echo
}

func_CHECK_SUDO_PERMISSION() {
    echo
    echo "[BLOON-install] Installation requires sudo permission. Checking..."
    sudo echo >/dev/null
    if [ $? -ne 0 ]; then
        echo
        echo "[BLOON-install] Failed to obtain sudo permission. Aborting."
        exit 1
    else
        echo
        echo "[BLOON-install] Sudo permission granted."
    fi
}

func_CHECK_AND_INSTALL_DEPENDENCIES() {
    local auto_install_pkg_name_list=""
    local manual_install_pkg_name_list=""
    local to_interrupt=false
    local install_cmd_to_show_str_list=""

    # To check if the required packages are installed
    {
        if func_IS_EXIST__GPG; then
            echo "[BLOON-install] gpg is already installed."
        else
            echo "[BLOON-install] gpg is not installed."
            if [ "$(func_GET_INSTALL_CMD_STR_TO_SHOW__GPG)" = "____SHOULD_INSTALL_YOURSELF____" ]; then
                to_interrupt=true
                manual_install_pkg_name_list="$manual_install_pkg_name_list gpg"
            else
                auto_install_pkg_name_list="$auto_install_pkg_name_list gpg"
                install_cmd_to_show_str_list="$install_cmd_to_show_str_list$(func_GET_INSTALL_CMD_STR_TO_SHOW__GPG)\n"
            fi
        fi

        # --------------------------------------------------
        if func_IS_EXIST__WGET; then
            echo "[BLOON-install] wget is already installed."
        else
            echo "[BLOON-install] wget is not installed."
            if [ "$(func_GET_INSTALL_CMD_STR_TO_SHOW__WGET)" = "____SHOULD_INSTALL_YOURSELF____" ]; then
                to_interrupt=true
                manual_install_pkg_name_list="$manual_install_pkg_name_list wget"
            else
                auto_install_pkg_name_list="$auto_install_pkg_name_list wget"
                install_cmd_to_show_str_list="$install_cmd_to_show_str_list$(func_GET_INSTALL_CMD_STR_TO_SHOW__WGET)\n"
            fi
        fi

        # --------------------------------------------------
        if func_IS_EXIST__PKEXEC; then
            echo "[BLOON-install] pkexec is already installed."
        else
            echo "[BLOON-install] pkexec is not installed."
            if [ "$(func_GET_INSTALL_CMD_STR_TO_SHOW__PKEXEC)" = "____SHOULD_INSTALL_YOURSELF____" ]; then
                to_interrupt=true
                manual_install_pkg_name_list="$manual_install_pkg_name_list pkexec"
            else
                auto_install_pkg_name_list="$auto_install_pkg_name_list pkexec"
                install_cmd_to_show_str_list="$install_cmd_to_show_str_list$(func_GET_INSTALL_CMD_STR_TO_SHOW__PKEXEC)\n"
            fi
        fi

        # --------------------------------------------------
        if func_IS_EXIST__LIBGTHREAD_2_0_0; then
            echo "[BLOON-install] libgthread-2.0.so.0 is already installed."
        else
            echo "[BLOON-install] libgthread-2.0.so.0 is not installed."
            if [ "$(func_GET_INSTALL_CMD_STR_TO_SHOW__LIBGTHREAD_2_0_0)" = "____SHOULD_INSTALL_YOURSELF____" ]; then
                to_interrupt=true
                manual_install_pkg_name_list="$manual_install_pkg_name_list libgthread-2.0.so.0"
            else
                auto_install_pkg_name_list="$auto_install_pkg_name_list libgthread-2.0.so.0"
                install_cmd_to_show_str_list="$install_cmd_to_show_str_list$(func_GET_INSTALL_CMD_STR_TO_SHOW__LIBGTHREAD_2_0_0)\n"
            fi
        fi

        # --------------------------------------------------
        # trim
        manual_install_pkg_name_list=$(echo "$manual_install_pkg_name_list" | sed 's/^ *//;s/ *$//')
        auto_install_pkg_name_list=$(echo "$auto_install_pkg_name_list" | sed 's/^ *//;s/ *$//')
        # remove the tailing "\n"
        install_cmd_to_show_str_list=$(printf "$install_cmd_to_show_str_list" | sed 's/\n$//')
    }

    # Get user confirmation to automatically install required packages
    {
        if [ $to_interrupt = true ]; then
            echo
            echo "[BLOON-install] BLOON itself or installation script requires the following packages. Please install them and then re-run the installation script:"
            echo "$manual_install_pkg_name_list" | tr ' ' '\n' | sed 's/^/    /'
            exit 1

        else
            # -n means not empty
            if [ -n "$auto_install_pkg_name_list" ]; then
                echo
                echo "[BLOON-install] BLOON itself or installation script requires the following packages:"
                echo "$auto_install_pkg_name_list" | tr ' ' '\n' | sed 's/^/    /'

                echo
                echo "[BLOON-install] We will execute the following commands to automatically install these packages:"
                printf "$install_cmd_to_show_str_list\n"

                read -r -p "[BLOON-install] Continue? (y/n) " response </dev/tty
                if [ "$response" != "y" ]; then
                    echo
                    echo "[BLOON-install] Aborting."
                    exit 1
                fi
            fi
        fi
    }

    # Install required packages automatically
    {
        if echo "$auto_install_pkg_name_list" | grep -q "gpg"; then
            func_DO_INSTALL__GPG
            if [ $? -ne 0 ]; then
                echo
                echo "[BLOON-install] Failed to install gpg. Aborting."
                exit 1
            fi
        fi

        if echo "$auto_install_pkg_name_list" | grep -q "wget"; then
            func_DO_INSTALL__WGET
            if [ $? -ne 0 ]; then
                echo
                echo "[BLOON-install] Failed to install wget. Aborting."
                exit 1
            fi
        fi

        if echo "$auto_install_pkg_name_list" | grep -q "pkexec"; then
            func_DO_INSTALL__PKEXEC
            if [ $? -ne 0 ]; then
                echo
                echo "[BLOON-install] Failed to install pkexec. Aborting."
                exit 1
            fi
        fi

        if echo "$auto_install_pkg_name_list" | grep -q "libgthread-2.0.so.0"; then
            func_DO_INSTALL__LIBGTHREAD_2_0_0
            if [ $? -ne 0 ]; then
                echo
                echo "[BLOON-install] Failed to install libgthread-2.0.so.0. Aborting."
                exit 1
            fi
        fi
    }
}

func_DOWNLOAD_AND_EXTARCT_BINARY() {
    rm -rf /tmp/___bloon-init___*
    local TMP_WORK_DIR=$(mktemp -d -t ___bloon-init___XXXXXX)

    local BLOON_RELEASE_KEY="https://www.bloon.io/security/bloon-release-key.gpg"
    local TGZ_FILE_URL="https://dl.bloon.io/dl-hero?pkg=tgz"
    local TGZ_ASC_FILE_URL="https://dl.bloon.io/dl-hero?pkg=tgz&asc"

    # --------------------------------------------------
    cd $TMP_WORK_DIR
    echo
    echo "[BLOON-install] Downloading binary..."

    wget --max-redirect=0 --https-only --secure-protocol=TLSv1_2 --content-disposition "$BLOON_RELEASE_KEY"
    if [ $? -ne 0 ]; then
        echo
        echo "[BLOON-install] Failed to download the gpg key. Aborting."
        exit 1
    fi

    wget --max-redirect=0 --https-only --secure-protocol=TLSv1_2 --content-disposition "$TGZ_ASC_FILE_URL"
    if [ $? -ne 0 ]; then
        echo
        echo "[BLOON-install] Failed to download the binary's signature. Aborting."
        exit 1
    fi

    wget --max-redirect=0 --https-only --secure-protocol=TLSv1_2 --content-disposition "$TGZ_FILE_URL"
    if [ $? -ne 0 ]; then
        echo
        echo "[BLOON-install] Failed to download the binary. Aborting."
        exit 1
    fi

    echo
    echo "[BLOON-install] Download complete."

    # --------------------------------------------------
    local TGZ_FILE_NAME=$(ls *.tgz)
    local TGZ_ASC_FILE_NAME=$(ls *.tgz.asc)
    local BLOON_RELEASE_KEY_FILE_NAME="bloon-release-key.gpg"

    echo
    echo "[BLOON-install] Fingerprint information of the BLOON release key:"

    # gpg version 2.2.4 (ubuntu 18.04) not support "--show-keys" option
    # gpg --show-keys --keyid-format LONG --fingerprint $BLOON_RELEASE_KEY_FILE_NAME
    gpg --import-options show-only --fingerprint --import $BLOON_RELEASE_KEY_FILE_NAME

    ##################################################
    # This hard-coded fingerprint should match the fingerprint on the official website:
    # TODO Fill in the real URL that has the fingerprint
    ##################################################
    local BLOON_CORRECT_FINGERPRINT="C89F 9564 72FB BE40 A5BF  4AA2 F4DF 8C43 B4BB 8D49"
    ##################################################

    BLOON_CORRECT_FINGERPRINT=$(echo $BLOON_CORRECT_FINGERPRINT | tr -d '[:space:]')
    
    # gpg version 2.2.4 (ubuntu 18.04) not support "--show-keys" option
    # local TMP_FIND_FINGERPRINT=$(
    #     gpg --show-keys --keyid-format LONG --with-colons --fingerprint $BLOON_RELEASE_KEY_FILE_NAME |
    #         awk -F: '/^pub/ {pub=1} /^fpr/ && pub {print $10; pub=0}'
    # )
    local TMP_FIND_FINGERPRINT=$(
        gpg --import-options show-only --fingerprint --with-colons --import $BLOON_RELEASE_KEY_FILE_NAME 2>&1 |
            awk -F: '/^pub/ {pub=1} /^fpr/ && pub {print $10; pub=0}'
    )
    if [ "$TMP_FIND_FINGERPRINT" != "$BLOON_CORRECT_FINGERPRINT" ]; then
        echo
        echo "[BLOON-install] The fingerprint of the BLOON release key is incorrect. Aborting."
        exit 1
    else
        echo
        echo "[BLOON-install] The fingerprint of the BLOON release key is correct."
    fi

    # --------------------------------------------------
    echo
    echo "[BLOON-install] Verifying signature of the binary..."
    cd $TMP_WORK_DIR
    gpg --batch --import $BLOON_RELEASE_KEY_FILE_NAME
    gpg --verify $TGZ_ASC_FILE_NAME $TGZ_FILE_NAME
    if [ $? -ne 0 ]; then
        echo
        echo "[BLOON-install] Signature verification failed. Aborting."
        gpg --batch --yes --delete-keys $BLOON_CORRECT_FINGERPRINT
        exit 1
    else
        echo
        echo "[BLOON-install] Signature verification successful."
        gpg --batch --yes --delete-keys $BLOON_CORRECT_FINGERPRINT
    fi

    # --------------------------------------------------
    cd $TMP_WORK_DIR
    echo
    echo "[BLOON-install] Extracting binary..."
    tar zxf $TGZ_FILE_NAME

    echo
    echo "[BLOON-install] Extract complete."

    # --------------------------------------------------
    cd $TMP_WORK_DIR
    echo
    echo "[BLOON-install] Installing binary..."

    # No matter what, delete the old installation first
    sudo rm -rf /opt/BLOON

    # If installed via deb, rpm and then removed, it may cause the /opt folder to be removed. Check if /opt exists here first
    if [ ! -d /opt ]; then
        sudo mkdir /opt
        sudo chmod 755 /opt
    fi

    sudo mv BLOON /opt
}

# This function is totally the same as the function in the DEB "postinst" script
func_SETUP_BLOON_ENV() {
    # mkdir -p /usr/bin
    sudo ln -sf /opt/BLOON/scripts/bloon-cli.sh /usr/bin/bloon

    # --------------------------------------------------
    ##################################################
    # known results of "dpkg -L nautilus | grep extensions":
    #     ubuntu 16.04
    #         /usr/lib/nautilus/extensions-3.0
    #         /usr/lib/nautilus/extensions-3.0/libnautilus-sendto.so
    #     ubuntu 18.04
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0/libnautilus-sendto.so
    #     ubuntu 20.04
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0/libnautilus-image-properties.so
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0/libnautilus-sendto.so
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0/libtotem-properties-page.so
    #     ubuntu 22.04
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0/libnautilus-image-properties.so
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0/libnautilus-sendto.so
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-3.0/libtotem-properties-page.so
    #     ubuntu 24.04
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-4
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-4/libnautilus-image-properties.so
    #         /usr/lib/x86_64-linux-gnu/nautilus/extensions-4/libtotem-properties-page.so
    ##################################################
    if command -v dpkg >/dev/null; then
        nautilus_ext_dir_path=$(dpkg -L nautilus | grep extensions | grep -v ".so$")
        if [ -n "$nautilus_ext_dir_path" ]; then
            # mkdir -p $nautilus_ext_dir_path
            sudo ln -sf /opt/BLOON/lib/libnautilus-bloon.so $nautilus_ext_dir_path/libnautilus-bloon.so
        else
            echo "[BLOON-install] This system does not seem to support Nautilus. To skip the Nautilus extension installation."
        fi
    fi

    # --------------------------------------------------
    sudo mkdir -p /usr/share/applications
    sudo ln -sf /opt/BLOON/bloon.desktop /usr/share/applications/bloon.desktop

    # --------------------------------------------------
    sudo mkdir -p /usr/share/mime/packages
    sudo ln -sf /opt/BLOON/bloon-stub.xml /usr/share/mime/packages/bloon-stub.xml

    # --------------------------------------------------
    tmp_ary="16x16 32x32 64x64 128x128 256x256 512x512"
    for i in $tmp_ary; do
        tmp_dir="/usr/share/icons/hicolor/${i}"
        sudo mkdir -p "$tmp_dir/apps"
        sudo mkdir -p "$tmp_dir/emblems"
        sudo mkdir -p "$tmp_dir/mimetypes"
        sudo ln -sf "/opt/BLOON/resources/img/bloon_${i}.png" "$tmp_dir/apps/bloon.png"
        sudo ln -sf "/opt/BLOON/resources/img/bloon-syncing_${i}.png" "$tmp_dir/emblems/bloon-syncing.png"
        sudo ln -sf "/opt/BLOON/resources/img/bloon-uptodate_${i}.png" "$tmp_dir/emblems/bloon-uptodate.png"
        sudo ln -sf "/opt/BLOON/resources/img/bloon-watching_${i}.png" "$tmp_dir/emblems/bloon-watching.png"
        sudo ln -sf "/opt/BLOON/resources/img/bloon-stub_${i}.png" "$tmp_dir/mimetypes/bloon-stub.png"
    done

    sudo gtk-update-icon-cache /usr/share/icons/hicolor

    # --------------------------------------------------
    # Recursively change file permissions only, not folder permissions
    sudo find /opt/BLOON -type f -exec chmod 644 {} \;

    sudo find /opt/BLOON/scripts -type f -exec chmod 755 {} \;

    sudo chmod 755 /opt/BLOON/libexec/QtWebEngineProcess
    sudo chmod 755 /opt/BLOON/Bloon
    sudo chmod 755 /opt/BLOON/ffmpeg
    sudo chmod 755 /opt/BLOON/launcher
    sudo chmod 755 /opt/BLOON/upgrade
    sudo chmod 755 /opt/BLOON/webparser

    # this "if" is for GUI only version
    if [ -f /opt/BLOON/hero_cli_connector ]; then
        sudo chmod 755 /opt/BLOON/hero_cli_connector
    fi

    # this "if" is for GUI only version
    if [ -f /opt/BLOON/bloond ]; then
        sudo chmod 755 /opt/BLOON/bloond
    fi

    sudo chown -R root:root /opt/BLOON

    # --------------------------------------------------
    # this "if" is for GUI only version
    if [ -f /usr/share/bash-completion/completions/bloon ]; then
        sudo chmod 644 /usr/share/bash-completion/completions/bloon

        if [ -f /usr/share/bash-completion/bash_completion ]; then
            . /usr/share/bash-completion/bash_completion
        fi
    fi

    # --------------------------------------------------
    sudo killall nautilus >/dev/null 2>&1

    # Request to resolve bloon-stub.xml. Make .bloon a system-recognizable file format
    sudo update-mime-database /usr/share/mime

    # Tested and found that debian 12 does not have this command, so add an if judgment to avoid displaying error messages. However, its "Specify to open the .bloon file with the BLOON App" still takes effect
    if [ -x /usr/bin/update-desktop-database ]; then
        # Request to resolve bloon.desktop. One of the effects is to specify to open the .bloon file with the BLOON App
        sudo update-desktop-database /usr/share/applications
    fi

    if [ -x /usr/sbin/update-icon-caches ]; then
        sudo update-icon-caches /usr/share/icons/*
    fi
}

# --------------------------------------------------
func_IS_EXIST__GPG() {
    if command -v gpg >/dev/null; then
        return 0
    else
        return 1
    fi
}

func_GET_INSTALL_CMD_STR_TO_SHOW__GPG() {
    local cmd_to_show_str=""
    if command -v apt-get >/dev/null; then
        cmd_to_show_str="    sudo apt-get update\n    sudo apt-get install -y gpg"

    elif command -v zypper >/dev/null; then
        cmd_to_show_str="    sudo zypper install -y gpg2"

    elif command -v dnf >/dev/null; then
        cmd_to_show_str="    sudo dnf install -y gnupg2"

    else
        cmd_to_show_str="____SHOULD_INSTALL_YOURSELF____"

    fi
    echo "$cmd_to_show_str"
}

func_DO_INSTALL__GPG() {
    if command -v apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y gpg

    elif command -v zypper >/dev/null; then
        sudo zypper install -y gpg2

    elif command -v dnf >/dev/null; then
        sudo dnf install -y gnupg2

    else
        # assert false
        echo
        echo "[BLOON-install] BLOON requires gpg. Please install gpg."
        exit 1
    fi
}

# --------------------------------------------------
func_IS_EXIST__WGET() {
    if command -v wget >/dev/null; then
        return 0
    else
        return 1
    fi
}

func_GET_INSTALL_CMD_STR_TO_SHOW__WGET() {
    local cmd_to_show_str=""
    if command -v apt-get >/dev/null; then
        cmd_to_show_str="    sudo apt-get update\n    sudo apt-get install -y wget"

    elif command -v zypper >/dev/null; then
        cmd_to_show_str="    sudo zypper install -y wget"

    elif command -v dnf >/dev/null; then
        cmd_to_show_str="    sudo dnf install -y wget"

    else
        cmd_to_show_str="____SHOULD_INSTALL_YOURSELF____"

    fi
    echo "$cmd_to_show_str"
}

func_DO_INSTALL__WGET() {
    if command -v apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y wget

    elif command -v zypper >/dev/null; then
        sudo zypper install -y wget

    elif command -v dnf >/dev/null; then
        sudo dnf install -y wget

    else
        # assert false
        echo
        echo "[BLOON-install] BLOON requires wget. Please install wget."
        exit 1
    fi
}

# --------------------------------------------------
func_IS_EXIST__PKEXEC() {
    if command -v pkexec >/dev/null; then
        return 0
    else
        return 1
    fi
}

func_GET_INSTALL_CMD_STR_TO_SHOW__PKEXEC() {
    local cmd_to_show_str=""
    if command -v apt-get >/dev/null; then
        cmd_to_show_str="    sudo apt-get update\n    sudo apt-get install -y policykit-1"

    elif command -v zypper >/dev/null; then
        cmd_to_show_str="    sudo zypper install -y pkexec"

    elif command -v dnf >/dev/null; then
        cmd_to_show_str="    sudo dnf install -y pkexec"

    else
        cmd_to_show_str="____SHOULD_INSTALL_YOURSELF____"

    fi
    echo "$cmd_to_show_str"
}

func_DO_INSTALL__PKEXEC() {
    if command -v apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y policykit-1

    elif command -v zypper >/dev/null; then
        sudo zypper install -y pkexec

    elif command -v dnf >/dev/null; then
        sudo dnf install -y pkexec

    else
        # assert false
        echo
        echo "[BLOON-install] BLOON requires pkexec. Please install pkexec."
        exit 1
    fi
}

# --------------------------------------------------
func_IS_EXIST__LIBGTHREAD_2_0_0() {
    if sudo ldconfig -p | grep -q libgthread-2.0.so.0; then
        return 0
    else
        return 1
    fi
}

func_GET_INSTALL_CMD_STR_TO_SHOW__LIBGTHREAD_2_0_0() {
    local cmd_to_show_str=""
    if command -v apt-get >/dev/null; then
        cmd_to_show_str="    sudo apt-get update\n    sudo apt-get install -y libglib2.0-0"

    elif command -v zypper >/dev/null; then
        cmd_to_show_str="    sudo zypper install -y libgthread-2_0-0"

    elif command -v dnf >/dev/null; then
        cmd_to_show_str="    sudo dnf install -y glib2"

    else
        cmd_to_show_str="____SHOULD_INSTALL_YOURSELF____"

    fi
    echo "$cmd_to_show_str"
}

func_DO_INSTALL__LIBGTHREAD_2_0_0() {
    if command -v apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y libglib2.0-0

    elif command -v zypper >/dev/null; then
        sudo zypper install -y libgthread-2_0-0

    elif command -v dnf >/dev/null; then
        sudo dnf install -y glib2

    else
        # assert false
        echo
        echo "[BLOON-install] BLOON requires libgthread-2.0.so.0. Please install libgthread-2.0.so.0."
        exit 1
    fi
}

# --------------------------------------------------
func_MAIN
