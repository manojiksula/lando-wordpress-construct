# Lando WordPress Construct
Installs a WordPress for local development either from scratch, either from a git repository. Can also import a database if you want.

### Requirements
* Docker
* Lando

### Instalation

```sh
$ git clone https://github.com/plagioriginal/lando-wordpress-construct.git project-folder
$ cd project-folder
$ sh .scripts/project-starter.sh
```
Follow instructions.

### Database import
In the end of the script, you will be asked to import an existing Database. If you want to do so, the database must be in the root of the project with the name db.sql.
