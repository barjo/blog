In this post we will show how to use [OpenDJ](https://github.com/OpenIdentityPlatform/OpenDJ) ldap server to authenticate user on an ubuntu workstation.

## OpenDJ setup

I will assume that you already have an OpenDJ server running. If not please, have a look at the OpenDJ [installation guide](https://github.com/OpenIdentityPlatform/OpenDJ/wiki/Installation-Guide).

### PosixAccount and posixGroup

One important step before setting up ubuntu is to add the ldap user, you want to allows on the workstation, to the auxiliary `objectClass posixAccount` and `posixGroup`. It can easily be done through the OpenDJ control-panel, in the *Manage Entries* section of the *Directory Data*.

You will need to set the field `uidNumber`, `gidNumber` and the `homeDirectory`. They must contains respectively the user id number, the group id number and the user home directory path. For example:

```
uidNumber = 1100
uidNumber = 1100
homeDirectory = /home/foo
```

If you don't add those `objectclass` to your ldap user, he won't be able to be authenticated on the workstation. If that the case, you will likely have a log saying that the credential are wrong on both the work station and OpenDJ.

## Workstation setup

### Setup the ldap-auth-client

The first step is too install the `ldap-auth-client` and `nscd`. The first allows for authentication through ldap via PAM. The name service cache daemon is just a cache of the nss (name service switch).

```
sudo apt-get install ldap-auth-client nscd
```

You will be ask about your ldap configuration. You can change it later by editing the `/etc/ldap.conf` file.
It should look something like that:

```
# You ldap host, an ip is ok too
host ldap.myserver.com
# Your ldap base dn.
base dc=myserver,dc=com

# If your server don't allow for anonymous bind
binddn cn=workstation,ou=App,dc=myserver,dc=com
bindpw thepassword
```

Don't forget to comment out `pam_password md5`. OpenDJ need to received the password in clear by default, not in md5. If your server is running on the port 389, you don't need anything else. However, please note that it is not secure at all. It would be better to use ldap over ssl and have proper certificate.

### Setup the name service switch
We need to configure nss so that it looks for ldap authentication. It can be done via the following command:

```
sudo auth-client-config -t nss -p lac_ldap
```

Otherwise you have to edit `/etc/nsswitch.conf` and append ldap for passwd, group and shadow. It should look like that:

```
passwd: files ldap
groups: files ldap
shadow: files ldap
```

### Home dir and group

In order for your ldap user to have their home created as well as be part of some usefull group, you need to configure pam.
For the home dir, create the file `/usr/share/pam-configs/my_mkhomedir` with the following content.

```
Name: activate mkhomedir
Default: yes
Priority: 900
Session-Type: Additional
Session:
        required    pam_mkhomedir.so umask=0022 skel=/etc/skel
```

For the group, first add the group you want for the new user.

```
echo "*;*;*;Al0000-2400;audio,cdrom,dialout,usb" >> /etc/security/group.conf
```

Then create the file `/usr/share/pam-configs/my_mkhomedir` with the following content.

```
Name: activate /etc/security/group.conf
Default: yes
Priority: 900
Auth-Type: Primary
Auth:
        required    pam_group.so use_first_pass
```

Finally update pam auth to process the configuration and restart the nss cache service.

```
sudo pam-auth-update
service nscd restart
```

At this point you should be good to go. Don't forget that you will need the network in order to be able to communicate with the ldap server, so be sure that your network interface is properly set up before the login phase. User will be created on the fly with the information retrieved from your ldap server.

## References

This post is based on the following articles/documentation.

- [Ubuntu Ldap client authentication doc](https://web.archive.org/web/20190202024947/http://blog.davekoelmeyer.co.nz/2011/04/09/set-up-ldap-authentication-between-ubuntu-10-04-and-opendj-2-4-1/)
- [Dave Koelmeyer blog](https://web.archive.org/web/20190202024947/http://blog.davekoelmeyer.co.nz/2011/04/09/set-up-ldap-authentication-between-ubuntu-10-04-and-opendj-2-4-1/)
- [TLDP LDAP howto](http://www.tldp.org/HOWTO/archived/LDAP-Implementation-HOWTO/pamnss.html)
