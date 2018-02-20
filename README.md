docker-munki
-----
A container that serves static files at http://munki/repo using nginx.

nginx expects the munki repo content to be located at /munki_repo. Use a data container and the --volumes-from option to add files.


Run the Munki container:
-----
You need to have an existing Munki repo on the host, you can mount that folder directly by using the -v flag:

```
docker run -d \
--name munki \
-v /path/to/munki/repo:/munki_repo \
-p 80:80 \
stilljake/munki
```
Populate the Munki server (optional):
-----
The easiest way to populate the Munki server is to hook the munki-data volume up to a Samba container and share it out to a Mac, using my [SMB-Munki container](https://registry.hub.docker.com/u/nmcspadden/smb-munki/):  

1.	`docker pull nmcspadden/smb-munki`
2.	`docker run -d -p 445:445 --volumes-from munki-data --name smb nmcspadden/smb-munki`
3.	You may need to change permissions on the mounted share, or change the samba.conf to allow for guest read/write permissions. One example:  
	`chown -R nobody:nogroup /munki_repo`  
	`chmod -R ugo+rwx /munki_repo`
4.	Populate the Munki repo using the usual tools - munkiimport, manifestutil, makecatalogs, etc.
