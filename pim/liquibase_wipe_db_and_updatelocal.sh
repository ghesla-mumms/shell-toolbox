#! /bin/bash

ant -f ~/dev/hummingbird/hbgwt/HBJPA/build.xml \
	-Ddatabase.url=jdbc:postgresql://localhost:5432/ \
	-Ddatabase.username=hummingbird \
	-Ddatabase.password=hummingbird \
	-Ddb.changelog.file=/Users/g.hesla/dev/hummingbird/hbgwt/HBJPA/liquibase/changelog/db.changelog-localmaster.xml \
	liquibase-drop-all

ant -f ~/dev/hummingbird/hbgwt/HBJPA/build.xml \
	-Ddatabase.url=jdbc:postgresql://localhost:5432/ \
	-Ddatabase.username=hummingbird \
	-Ddatabase.password=hummingbird \
	-Ddb.changelog.file=/Users/g.hesla/dev/hummingbird/hbgwt/HBJPA/liquibase/changelog/db.changelog-localmaster.xml \
	liquibase-update-database
