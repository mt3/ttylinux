
04ttylinux07 boot options:

 hwclock=(local|utc)09 ... The hardware (CMOS) clock keeps 07local09 or 07UCT09 time.07

 tz=<timezone>09 ......... Set timezone to 07<timezone>09 by setting the TZ07
                         09environment variable. Example: 07tz=GMT-809  See the07
                         09following URL for a complete description of TZ.07
        0bhttp://www.gnu.org/s/libc/manual/html_node/TZ-Variable.html#TZ-Variable07

 host=<name.domain.tld>09 .... Set the hostname to 07<name.domain.tld>09, which07
                             09by this example is a Fully Qualified Domain07
                             09Name. You can use a simple 07<name>09.07

 login=<tty*,tty*,...>09 ..... Allow login on devices e.g., 07ttyS109, etc.07
                             09Embedded system might use this to put a getty07
                             09login(s) on a serial port(s).07

 nologin=<tty*,tty*,...>09 ... Disallow login on devices e.g., 07tty109, 07tty209, etc.07
                             09Embedded system might use this to prevent a getty07
                             09login(s) on a virtual console(s).07

0f[F1-Main] [F2-Options] [F3-Options] [F4-Options]07
