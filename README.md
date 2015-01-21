docker-munki-puppet
-----
A container that serves static files at http://munki/repo using nginx, with Puppet used for SSL certificates.

nginx expects the munki repo content to be located at /munki_repo. Use a data container and the --volumes-from option to add files.

# Using this container:

1.	Setup up a [generic Puppetmaster](https://github.com/nmcspadden/docker-puppetmaster) container.
2.	Alternatively, hook this up to [Puppetmaster + WHD](https://github.com/macadmins/docker-puppetmaster-whdcli) for policy-based autosigning based on inventory which autosigns Docker and virtual images.

Create a Data Container:
-----
Create a data-only container to host the Munki repo:  
	`docker run -d --name munki-data --entrypoint /bin/echo macadmins/munki-puppet Data-only container for munki`

Run the Munki container linked to Puppet:
-----
If you have an existing Munki repo on the host, you can mount that folder directly by using this option:

`-v /path/to/munki/repo:/munki_repo`

Otherwise, use --volumes-from the data container.  Use --link to link up the puppetmaster to the container:  
	`docker run -d --name munki --volumes-from munki-data -p 80:80 -p 443:443 -h munki --link puppetmaster:puppet macadmins/munki-puppet`

Set up Puppet:
----
Run the puppet agent on the Munki container to generate the cert (if you are not using autosigning, you will need to manually sign the cert on the puppetmaster):  
`docker exec munki puppet agent --test`

Set up SSL for Nginx:
-----
1.	Add some static content to nginx, such as a site_default file in /munki_repo/manifests/site_default.
2.	For the following example, you'll probably need to edit munki-ssl-repo.conf to use the correct hostname.  "munki.pem" may be named "munki.domain.com" depending on your network setup. Make appropriate changes.  
	Edit /etc/nginx/sites-enabled/munki-repo.conf to the contents of munki-repo-ssl.conf by using cat:  
	`cat munki-repo-ssl.conf | docker exec -i munki sh -c 'cat > /etc/nginx/sites-enabled/munki-repo.conf'`  

		# Munki Repo
		server {
		listen 443;
				
		ssl     on;
		ssl_certificate     /var/lib/puppet/ssl/certs/munki.pem;
		ssl_certificate_key     /var/lib/puppet/ssl/private_keys/munki.pem;
		ssl_client_certificate     /var/lib/puppet/ssl/certs/ca.pem;
		ssl_crl     /var/lib/puppet/ssl/crl.pem;
		ssl_protocols     TLSv1.2 TLSv1.1 TLSv1;
		ssl_prefer_server_ciphers     on;
		ssl_ciphers     "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";
		server_name munki;
		location /repo/ {
			alias /munki_repo/;
			autoindex off;
			}
		}
4.	Restart nginx:  
	`docker stop munki`  
	`docker start munki`  
5.	Now try accessing the nginx server via web browser at https://localhost/repo/manifests/site_default  
	(Note that this will fail and report an invalid CA if accessed from a machine that does not have the Puppet CA certificate in the browser store, but you can safely ignore that for now.)

Populate the Munki server (optional):
-----
The easiest way to populate the Munki server is to hook the munki-data volume up to a Samba container and share it out to a Mac, using my [SMB-Munki container](https://registry.hub.docker.com/u/nmcspadden/smb-munki/):  

1.	`docker pull nmcspadden/smb-munki`
2.	`docker run -d -p 445:445 --volumes-from munki-data --name smb nmcspadden/smb-munki`
3.	You may need to change permissions on the mounted share, or change the samba.conf to allow for guest read/write permissions. One example:  
	`chown -R nobody:nogroup /munki_repo`  
	`chmod -R ugo+rwx /munki_repo`
4.	Populate the Munki repo using the usual tools - munkiimport, manifestutil, makecatalogs, etc.

Set up clients to use Munki with SSL:
-----
In the following steps, I'm using the default Mac sharing name of "mac.local", but you should change these to match the hostname of your client.  
All of these steps should be done on the client:  

1.	`puppet agent --test` to get a signed cert from the Puppetmaster
2.	Copy the certs into /Library/Managed Installs/:
	1.	`sudo mkdir -p /Library/Managed\ Installs/certs`
	2.	`sudo chmod 0700 /Library/Managed\ Installs/certs`
	3.	`sudo cp /etc/puppet/ssl/certs/mac.local.pem /Library/Managed\ Installs/certs/clientcert.pem`
	4.	`sudo cp /etc/puppet/ssl/private_keys/mac.local.pem /Library/Managed\ Installs/certs/clientkey.pem`
	5.	`sudo cp /etc/puppet/ssl/certs/ca.pem /Library/Managed\ Installs/certs/ca.pem`
3.	Change the ManagedInstalls.plist defaults:
	1.	`sudo defaults write /Library/Preferences/ManagedInstalls SoftwareRepoURL "https://munki2.sacredsf.org/repo"`
	2.	`sudo defaults write /Library/Preferences/ManagedInstalls SoftwareRepoCACertificate "/Library/Managed Installs/certs/ca.pem"`
	3.	`sudo defaults write /Library/Preferences/ManagedInstalls ClientCertificatePath "/Library/Managed Installs/certs/clientcert.pem"`
	4.	`sudo defaults write /Library/Preferences/ManagedInstalls ClientKeyPath "/Library/Managed Installs/certs/clientkey.pem"`
	5.	`sudo defaults write /Library/Preferences/ManagedInstalls UseClientCertificate -bool TRUE`
4.	Test out the client:  
	`sudo /usr/local/munki/managedsoftwareupdate -vvv --checkonly`
