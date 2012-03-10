
04ttylinux07 boot options:

09A few of the 04Linux kernel09 boot options, some also used by 04ttylinux09:07

 console=<ttyS*>09 ....... Use serial dev 07<ttyS*>09 for console login.  The kernel07
                         09will use it for console output and 04ttylinux09 will also07
                         09put a getty login on it.07
                         09For 07<ttyS*>09 use one of 07ttyS009, 07ttyS109, 07ttyS209 or 07ttyS309.07

 vga=<mode>09 ............ Use VESA frame buffer with 07<mode>09.  Try 07vga=ask07
                         09to get a list of modes support by the kernel.07
                         vga=0x30109 640x480   8-bit | 07vga=0x16109 1152x864   8-bit07
                         vga=0x31109 640x480  16-bit | 07vga=0x16309 1152x864  16-bit07
                         vga=0x30309 800x600   8-bit | 07vga=0x30709 1280x1024  8-bit07
                         vga=0x31309 800x600  16-bit | 07vga=0x31A09 1280x1024 16-bit07
                         vga=0x30509 1024x768  8-bit | 07vga=0x31C09 1600x1200  8-bit07
                         vga=0x31709 1024x768 16-bit | 07vga=0x31E09 1600x1200 16-bit07

 quiet09 ................. Don't print a bunch of stuff while booting; show07
                         09anomalies and errors.07

0f[F1-Main] [F2-Options] [F3-Options] [F4-Options]07
