# TODO: Make this rely on things that are not straight-up exec.
class spade{
    file { "$PROJ_DIR/spade/settings/local.py":
        ensure => file,
        source => "$PROJ_DIR/spade/settings/local.sample.py",
        replace => false;
    }

    exec { "create_mysql_database":
        command => "mysql -uroot -B -e'CREATE DATABASE $DB_NAME CHARACTER SET utf8;'",
        unless  => "mysql -uroot -B --skip-column-names -e 'show databases' | /bin/grep '$DB_NAME'",
        require => File["$PROJ_DIR/spade/settings/local.py"]
    }

    exec { "grant_mysql_database":
        command => "mysql -uroot -B -e'GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost # IDENTIFIED BY \"$DB_PASS\"'",
        unless  => "mysql -uroot -B --skip-column-names mysql -e 'select user from user' | grep '$DB_USER'",
        require => Exec["create_mysql_database"];
    }

    exec { "syncdb":
        cwd => "$PROJ_DIR",
        command => "/home/vagrant/spade-venv/bin/python ./manage.py syncdb --noinput",
        require => Exec["grant_mysql_database"];
    }

    exec { "sql_migrate":
        cwd => "$PROJ_DIR",
        command => "python ./vendor/src/schematic/schematic migrations/",
        require => [
            Service["mysql"],
            Package["python2.6-dev", "libapache2-mod-wsgi", "python-wsgi-intercept" ],
            Exec["syncdb"]
        ];
    }
}
