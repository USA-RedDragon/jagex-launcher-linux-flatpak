# Jagex Launcher Flatpak

This is a Flatpak package for the Jagex Launcher. It packages the [official upstream Wine at the latest version](#why-this-flatpak-as-opposed-to-other-available-options), RuneLite, and the Jagex Launcher.

## Installation

### Installing the Launcher

It is unlikely that Flathub would accept a proprietary application like the Jagex Launcher, paricularly one that is wrapped in Wine. As such, this Flatpak is not available on Flathub.

### Flatpak Remote

You can install it by adding the remote and installing it with the following commands:

```bash
flatpak remote-add --if-not-exists usareddragon https://jagexlauncher.flatpak.mcswain.dev/.flatpakrepo
flatpak install --user usareddragon com.jagex.Launcher
```

### Manual Download

You can install it by downloading the [latest release](https://github.com/USA-RedDragon/jagex-launcher-flatpak/releases/latest) and installing it with the following command:

```bash
flatpak install --user com.jagex.Launcher.flatpak
```

### Nvidia GPU Drivers

If you are using the Nvidia proprietary drivers, you will need to install the drivers.

If you're not sure which version of the driver you're on, you can check the `/proc/driver/nvidia/version` file. If it doesn't exists, you're probably using the Nouveau drivers. If it does exist, here is an example of the output:

```bash
$ cat /proc/driver/nvidia/version
NVRM version: NVIDIA UNIX x86_64 Kernel Module  545.29.02  Thu Oct 26 21:21:38 UTC 2023
GCC version:  gcc version 13.2.1 20230801 (GCC)
```

In this case the driver version is `545.29.02`. You can then install the appropriate drivers with the following command, replacing the version with the version you found in the previous step:

```bash
flatpak install --user flathub org.freedesktop.Platform.GL.nvidia-545-29-02/x86_64
flatpak install --user flathub org.freedesktop.Platform.GL32.nvidia-545-29-02/x86_64
```

## Why this Flatpak as opposed to other available options?

### <https://github.com/nmlynch94/com.jagexlauncher.JagexLauncher>

#### Wine

The `nmlynch94` launcher [uses](https://github.com/nmlynch94/com.jagexlauncher.JagexLauncher/blob/6e1b5bf4c78b707bcb15d6f85d8b48e0337b7525/com.jagex.Launcher.yml#L21-L23) the [unoffical Flatpak Wine](https://github.com/flathub/org.winehq.Wine) package as a base. This package is not maintained by the Wine project and is several versions behind. This has several effects:

- This unofficial Wine package is missing many of the improvements that have been made to Wine recently.
- Because the unofficial Wine Flatpak is meant to be a one-size-fits-all installation of Wine, the size of the Flatpak is much larger than it needs to be, because it includes many dependencies that are not needed by the Jagex Launcher and it's games.
- The permissions required for the unofficial Wine are larger because it requests access to the host filesystem along with accessing devices. This is not needed by the Jagex Launcher and it's games, so these permissions expand the attack surface of the Flatpak without providing any benefit.

`nmlynch94`'s Flatpak also [contains a prebuilt Proton GE](https://github.com/nmlynch94/com.jagexlauncher.JagexLauncher/blob/35b90122cffb994bf506d0d36939bdb14c308973/com.jagex.Launcher.yml#L55-L65) which makes the Wine base even more unnecessary and illogical.

#### DXVK

The Jagex Launcher, Runescape's NXT client, the official OSRS client, and RuneLite all use OpenGL. (The exception is running NXT with compatibility mode) The `nmlynch94` launcher [adds DXVK](https://github.com/nmlynch94/com.jagexlauncher.JagexLauncher/blob/35b90122cffb994bf506d0d36939bdb14c308973/com.jagex.Launcher.yml#L99-L108), which just adds overhead and goes unused.

#### Custom Clients

The `nmlynch94` launcher contains support for other clients such as HDOS. If these clients are important to you, you should use the `nmlynch94` launcher. However, if you only care about the official Jagex client and RuneLite, this launcher is a better option.

#### Coherent Commit Messages

The `nmlynch94` launcher's [commit history](https://github.com/nmlynch94/com.jagexlauncher.JagexLauncher/commits/35b90122cffb994bf506d0d36939bdb14c308973) is littered with commit messages like "Update &lt;filename&gt;" and "test", so understanding the changes that were made to the repo is difficult.

#### Continuous Integration

This repository uses [GitHub Actions](https://github.com/features/actions) to test changes and ensure the Flatpak builds successfully. This means that the Flatpak will always be tested before being released and allows the next benefit: automatic dependency updates.

#### Automatic Dependency Updates

This repository uses [Renovate](https://www.mend.io/renovate/) to create automated pull requests to update dependencies. This means that the dependencies will be kept up to date without any manual intervention. This ensures that users will always have the latest versions of Wine and Runelite. `nmlynch94` does not use CI or Renovate, so the dependency update process is manual.

#### Copyrighted Content

This repository contains zero content that is the intellectual property of Jagex. The `nmlynch94` launcher [contains the Jagex launcher logo](https://github.com/nmlynch94/com.jagexlauncher.JagexLauncher/blob/6e1b5bf4c78b707bcb15d6f85d8b48e0337b7525/icons/512/512.png) that belongs to Jagex.

The lack of a license on the `nmlynch94` repository means that it is not legal to distribute or modify `nmlynch94`'s launcher package and that it is proprietary.
