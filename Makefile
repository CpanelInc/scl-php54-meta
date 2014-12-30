all:
	git clean -dxf
	mock -v -r ea4-php54-cent6-x86_64 --clean
	mock -v -r ea4-php54-cent6-x86_64 -D "scl php54" --unpriv --resultdir SRPMS --buildsrpm --spec SPECS/php54.spec --sources SOURCES
	mock -v -r ea4-php54-cent6-x86_64 -D "scl php54" -D "runselftest 0" --unpriv --resultdir RPMS SRPMS/php54-1.1-6.el6.src.rpm
