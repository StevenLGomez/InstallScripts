
# From: https://www.linuxtechi.com/install-kvm-on-rocky-linux-almalinux/

##########################################################################
# Step 1
function VerifyVirtualizationEnabled
{
    echo "Function VerifyVirtualizationEnabled starting"

    cat /proc/cpuinfo | egrep "vmx|svm"

    echo "Function VerifyVirtualizationEnabled complete"
}
# ------------------------------------------------------------------------

##########################################################################
# Step 2
function InstallKvm
{
    echo "Function InstallKvm starting"
    # sudo dnf install -y qemu-kvm virt-manager libvirt virt-install virt-viewer virt-top bridge-utils  bridge-utils virt-top libguestfs-tools
    sudo lsmod | grep kvm

    echo "Function InstallKvm complete"
}
# ------------------------------------------------------------------------

##########################################################################
# Step 3
function EnableLibvirtd
{
    echo "Function EnableLibvirtd starting"
    # Start libvirt daemon
    sudo systemctl start libvirtd

    # Enable the service
    sudo systemctl enable --now libvirtd

    # Verify the daemon is running
    sudo systemctl status libvirtd

    

    echo "Function EnableLibvirtd complete"
}
# ------------------------------------------------------------------------

##########################################################################
# Step 4
function SetupBridgeInterface
{
    echo "Function SetupBridgeInterface starting"

    sudo nmcli connection show

    echo "Function SetupBridgeInterface complete"
}
# ------------------------------------------------------------------------

##########################################################################
# Step 4
function PlaceHolder
{
    echo "Function PlaceHolder starting"
    # Code

    echo "Function VerifyVirtualizationEnabled complete"
}
# ------------------------------------------------------------------------























##########################################################################
# 12Y
function PlaceHolder
{
    echo "Function PlaceHolder starting"
    # Code

    echo "Function VerifyVirtualizationEnabled complete"
}
# ------------------------------------------------------------------------



# ====================================================================================
# ====================================================================================
# ====================================================================================
#
# Script execution begins here
#
# ====================================================================================

VerifyVirtualizationEnabled
InstallKvm
EnableLibvirtd










