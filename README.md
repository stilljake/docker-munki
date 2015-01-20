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
	`docker run -d --name munki-data --entrypoint /bin/echo nmcspadden/munki-puppet Data-only container for munki`

Run the Munki container linked to Puppet:
-----
If you have an existing Munki repo on the host, you can mount that folder directly by using this option:

`-v /path/to/munki/repo:/munki_repo/`

Otherwise, use --volumes-from the data container.  Use --link to link up the puppetmaster to the container:  
	`docker run -d --name munki --volumes-from munki-data -p 80:80 -p 443:443 -h munki --link puppetmaster:puppet nmcspadden/munki-puppet`

Set up Puppet:
----
Run the puppet agent to generate the cert (if you are not using autosigning, you will need to manually sign the cert on the puppetmaster):  
`docker exec munki puppet agent --test`

Set up SSL for Nginx:
-----
1.	The base nginx image doesn't have vi or nano installed, so you may need to install one:  
`docker exec munki apt-get install -y nano`
2.	Add some static content to nginx, such as a site_default file in /munki_repo/manifests/site_default.
3.	Edit /etc/nginx/sites-enabled/munki-repo.conf to this:  

		# Munki Repo
		server {
		listen 443;
				
		ssl     on;
		ssl_certificate     /var/lib/puppet/ssl/certs/munki.pem;
		ssl_certificate_key     /var/lib/puppet/ssl/private_keys/munki.pem;
		ssl_client_certificate     /var/lib/puppet/ssl/certs/ca.pem;
		ssl_crl     /var/lib/puppet/ssl/crl.pem;
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
	(Note that this will fail with an invalid CA if accessed from a machine that does not have the Puppet CA certificate.)

# To Do
* Install new cert profiles on clients