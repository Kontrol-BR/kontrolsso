#!/bin/sh
# Part of pf2ad script - redesigned by kontrol tecnologia


#VERSION='20180402' 

#if [ -f "/etc/samba.patch.version" ]; then
#	if [ "$(cat /etc/samba.patch.version)" = "$VERSION" ]; then
#		echo "ERROR: Changes have been applied!"
#		exit 2
#	fi
#fi

# Verifica versao Kontrol
#if [ "$(cat /etc/version)" != "2.4.3-RELEASE" ]; then
#	echo "ERROR: You need the Kontrol version 2.4.3 to apply this script"
#	exit 2
#fi

#ASSUME_ALWAYS_YES=YES
#export ASSUME_ALWAYS_YES

/usr/sbin/pkg bootstrap
/usr/sbin/pkg update

# Lock packages necessary
/usr/sbin/pkg lock pkg
/usr/sbin/pkg lock Kontrol-2.4.3

#mkdir -p /usr/local/etc/pkg/repos

cat <<EOF > /usr/local/etc/pkg/repos/kontrolsso.conf
kontrolsso: {
    url: "https://github.com/kontrolsecurity/packages/raw/11.1",
    mirror_type: "https",
    enabled: yes
}
EOF

/usr/sbin/pkg update -r kontrolsso
/usr/sbin/pkg install -r kontrolsso net/samba44 2> /dev/null

/usr/sbin/pkg unlock pkg
/usr/sbin/pkg unlock Kontrol-2.4.1

/usr/sbin/pkg update

mkdir -p /var/db/samba4/winbindd_privileged
chown -R :proxy /var/db/samba4/winbindd_privileged
chmod -R 0750 /var/db/samba4/winbindd_privileged

#fetch -o /usr/local/pkg -q https://raw.githubusercontent.com/kontrolsecurity/kontrolsso/2.4.3-SAMBA4/samba.inc
#fetch -o /usr/local/pkg -q https://raw.githubusercontent.com/kontrolsecurity/kontrolsso/2.4.3-SAMBA4/samba.xml

/usr/local/sbin/pfSsh.php <<EOF
\$samba = false;
foreach (\$config['installedpackages']['service'] as \$item) {
  if ('samba' == \$item['name']) {
    \$samba = true;
    break;
  }
}
if (\$samba == false) {
	\$config['installedpackages']['service'][] = array(
	  'name' => 'samba',
	  'rcfile' => 'samba.sh',
	  'executable' => 'smbd',
	  'description' => 'Samba daemon'
 );
}
\$samba = false;
foreach (\$config['installedpackages']['menu'] as \$item) {
  if ('Samba (AD)' == \$item['name']) {
    \$samba = true;
    break;
  }
}

if (\$samba == false) {
  \$config['installedpackages']['menu'][] = array(
    'name' => 'Samba (AD)',
    'section' => 'Services',
    'url' => '/pkg_edit.php?xml=samba.xml'
  );
}
write_config();
exec;
exit
EOF


if [ ! "$(/usr/sbin/pkg info | grep Kontrol-pkg-squid)" ]; then
	/usr/sbin/pkg install -r Kontrol Kontrol-pkg-squid
fi

#cd /usr/local/pkg
#fetch -o - -q https://raw.githubusercontent.com/kontrolsecurity/kontrolsso/2.4.3-SAMBA4/squid_winbind_auth.patch | patch -b -p0 -f
#fetch -o /usr/local/pkg -q https://raw.githubusercontent.com/kontrolsecurity/kontrolsso/2.4.3-SAMBA4/squid.inc

#if [ ! -f "/usr/local/etc/smb4.conf" ]; then
#	touch /usr/local/etc/smb4.conf
#fi


cp -f /usr/local/bin/ntlm_auth /usr/local/libexec/squid/ntlm_auth

/etc/rc.d/ldconfig restart

#echo "$VERSION" > /etc/samba.patch.version
echo  "Kontrol SSO Installed"


