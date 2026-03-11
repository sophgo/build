#!/bin/bash

create_debian_dir() {
    local package_name="${1:-my-package}"
    local pkg_root="${2:-./pkg_root}"
    local version="${3:-1.0}"
    local architecture="${4:-all}"
    local debian_dir="$pkg_root/DEBIAN"

    echo "Creating DEBIAN directory structure for package: $package_name"
    echo "Target directory: $pkg_root"

    mkdir -p "$debian_dir"
    mkdir -p "$pkg_root/usr/share/doc/$package_name"
    mkdir -p "$pkg_root/etc/$package_name"
    mkdir -p "$pkg_root/etc/ld.so.conf.d"
    echo "/opt/sophon/$package_name/lib" > pkg_root/etc/ld.so.conf.d/$package_name.conf
    mkdir -p "$pkg_root/opt/sophon/$package_name/lib"
    mkdir -p "$pkg_root/opt/sophon/$package_name/bin"

    cat > "$debian_dir/control" << EOF
Package: $package_name
Version: $version
Section: utils
Priority: optional
Architecture: $architecture
Maintainer: sophgo
Depends: 
Description: Package for $package_name
 This is an automatically generated package for $package_name.
EOF

    local script_file
    for script_file in preinst postinst prerm postrm; do
        case "$script_file" in
            preinst)
                cat > "$debian_dir/$script_file" << EOF
#!/bin/bash
# Pre-installation script for $package_name
# Version: $version

echo "Preparing to install $package_name..."


echo "Pre-installation steps completed."
exit 0
EOF
                ;;
            postinst)
                cat > "$debian_dir/$script_file" << EOF
#!/bin/bash
# Post-installation script for $package_name
# Version: $version

echo "Configuring $package_name after installation..."
export PATH=$PATH:/opt/sophon/$package_name/bin
ldconfig
echo "Post-installation configuration completed."
exit 0
EOF
                ;;
            prerm)
                cat > "$debian_dir/$script_file" << EOF
#!/bin/bash
# Pre-removal script for $package_name
# Version: $version

echo "Preparing to remove $package_name..."

rm -rf /etc/ld.so.conf.d/$package_name.conf
echo "Pre-removal steps completed."
exit 0
EOF
                ;;
            postrm)
                cat > "$debian_dir/$script_file" << EOF
#!/bin/bash
# Post-removal script for $package_name
# Version: $version

echo "Cleaning up after removal of $package_name..."
rm -rf /usr/share/doc/$package_name
rm -rf /etc/$package_name
rm -rf /opt/sophon/$package_name

echo "Post-removal cleanup completed."
exit 0
EOF
                ;;
        esac
        chmod +x "$debian_dir/$script_file"
    done

    touch "$debian_dir/conffiles"
    touch "$debian_dir/md5sums"
    echo "DEBIAN directory structure created successfully"
    echo "Package: $package_name"
    echo "Location: $pkg_root"
    echo ""
    echo "Next steps:"
    echo "1. Add your executable files to $pkg_root/opt/sophon/$package_name/bin/"
    echo "2. Add your share lib files to $pkg_root/opt/sophon/$package_name/lib/"
    echo "3. Edit $debian_dir/control file with your details"
    echo "4. Modify preinst/postinst scripts as needed"

    echo "DEBIAN directory structure created successfully for $package_name"
}

validate_debian_dir() {
    local pkg_root="${1:-./pkg_root}"
    local debian_dir="$pkg_root/DEBIAN"
    
    if [ ! -d "$debian_dir" ]; then
        echo "Error: DEBIAN directory not found"
        return 1
    fi
    
    local required_files=("control")
    for file in "${required_files[@]}"; do
        if [ ! -f "$debian_dir/$file" ]; then
            echo "Error: Missing required file $file"
            return 1
        fi
    done
    
    echo "DEBIAN directory structure validation passed"
    return 0
}

