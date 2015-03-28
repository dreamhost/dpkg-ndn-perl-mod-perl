#
# Regular cron jobs for the ndn-perl-apache2-mod-perl package
#
0 4	* * *	root	[ -x /usr/bin/ndn-perl-apache2-mod-perl_maintenance ] && /usr/bin/ndn-perl-apache2-mod-perl_maintenance
