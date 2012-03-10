
04ttylinux07 boot options:

 enet09 ..................... Startup networking for Ethernet interfaces found07
                            09by the kernel. DHCP is used. Any started interface07
                            09will be 07eth009, 07eth109, 07eth209 or 07eth309.07

 nofirewall09 ............... Do not startup the firewall.07

 nofsck09 ................... Do not run fsck on any file systems.07

 nosshd09 ................... Do not start sshd or make ssh keys; recommended07
                            09for any CPU slower than 1 Ghz. A script that07
                            09makes the ssh keys will be left in the /root07
                            09directory.07

 modules=<module>[,<module>]09 ... Load specific kernel module(s) named 07<module>09.07
                                 09Use this to load your sound card module,07
                                 09secure digital module (0fsdhci_pci09 if on07
                                 09the PCI bus), etc.07


0f[F1-Main] [F2-Options] [F3-Options] [F4-Options]07
