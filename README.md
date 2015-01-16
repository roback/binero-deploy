# Binero::Deploy

CLI to deploy and backup PHP and HTML websites on [Binero].

[Binero]: https://www.binero.se/

## Installation

Clone the repo

    git clone git@github.com:roback/binero-deploy.git

Install dependencies

    bundle install

Install the binero-deploy executable

    rake install

## Usage

### Commands

    binero-deploy  deploy
    binero-deploy  backup
    binero-deploy  revert
    binero-deploy  setup
    binero-deploy  help

### First time setup

1. Login to Binero and create a new application/website
2. Setup ssh keys to Binero
3. Add the binero host to your `~/.ssh/config`
    ```
    Host binero
      Hostname ssh.binero.se
      User <binero-ssh-user>
    ```

4. Add a `deploy.json` file to your PHP/HTML project (see *Configuration* below)
5. Commit all your code and push to your git remote
6. Run the first time setup of the application on binero
    ```
    binero-deploy setup
    ```

7. Upload any static files to binero (see *Static files* below)
8. (optional) Configure the database backup (see *Backup* below)

### Configuration (`deploy.json`)

```javascript
{
  "host": "binero",           // Name on the host in your ssh config
  "app": "example.org",       // The name of your application

  "keep_releases": 10,        // The number of releases to keep on binero

  "static_files": [           // See "Static files" below
    {
      "filename": "file.php", // The file ~/example.org/data/static/file.php on binero
      "symlink_name": "i.php" //   becomes example.org/i.php in browser
    }, {
      "filename": "images"    // All files in ~/example.org/data/static/images/<filename> is
    }                         //   accessed from example.org/images/<filename> in browser
  ],

  "exclude": {                // Files in the repo that should not be deployed
    "files": [
      ".gitignore",
      "README.md",
      "deploy.json"
    ],
    "dirs": [
      "project-files"
    ]
  },

  "backup": {                 // Configuration for backup of the application
    "db": false,              // Whether a database should be backed up too (see "Backup" below)
    "local_dir": "/home/user" // Directory where the backup should be downloaded to
  }
}
```

### Static files/directories

Static files/directories not included in the repo, that should persist between
releases, should be put in the `data/static/` directory of your application on binero.
The include them into the `static_files` array in your `deploy.json`.

### Backup

The backup command creates a `.tar.gz` archive of the whole application and downloads it
to the the specified directory.

To be able to back up a database you have to create a file called `db-backup-config.json`
in the `data/` directory of your application. It should look like this:

```javascript
// data/db-backup-config.json
{
  "db_host": "...",
  "db_user": "...",
  "db_password": "...",
  "db_name": "..."
}
```

The file is then used to create a dump of your database which gets
included into the backup archive that is downloaded.
