# dotfiles

## nvidia-autofix

On Ubuntu, a phased update can install a new kernel and its prebuilt NVIDIA module package without that kernel's headers. The module package needs `objtool` from the headers to build `nvidia.ko`, so the build fails, the package stays half-configured, and the GPU is missing after reboot (`modprobe: FATAL: Module nvidia not found`).

`nvidia-autofix` checks every installed kernel, installs the missing headers, finishes the package with `dpkg --configure -a`, and loads the module. It runs at boot (systemd) and after every apt run (apt hook).

```
sudo bash nvidia-autofix/install.sh              # install
sudo bash nvidia-autofix/install.sh --uninstall  # remove
nvidia-autofix/nvidia-autofix                    # report only, without root
```
