package CreateDB;

use strict;
use warnings;
use utf8;
use DBI;

use constant NUMBER_OF_TABLES => 6;

# Connecting to the DBI.
our $dbh = DBI->connect(          
		"dbi:SQLite:dbname=Aquareader/resources/rss.db", 
		"",
		"",
		{ RaiseError => 1,
		  sqlite_unicode => 1,
		}
	) or die $DBI::errstr;


# Creates all the tables.
# If a table already exists, it is then deleted and created again.
sub create_tables {
	$dbh->do("DROP TABLE IF EXISTS users");
	$dbh->do("CREATE TABLE users(	
									id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
									username TEXT, 
									password TEXT,
									name TEXT,
									surname TEXT ) ");
	$dbh->do("DROP TABLE IF EXISTS logins");
	$dbh->do("CREATE TABLE logins(	
									id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
									user_id INTEGER, 
									logout INTEGER )");
	$dbh->do("DROP TABLE IF EXISTS feeds");
	$dbh->do("CREATE TABLE feeds(	
									id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
									user_id INTEGER,
									name TEXT,
									category_id INTEGER,
									url TEXT )");

	$dbh->do("DROP TABLE IF EXISTS news");
	$dbh->do("CREATE TABLE news(	
									id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
									user_id INTEGER,
									title TEXT, 
									feed_id INTEGER,
									url TEXT,
									read INTEGER,
									date DATETIME ,
									description TEXT)");
	
	$dbh->do("DROP TABLE IF EXISTS categories");
	$dbh->do("CREATE TABLE categories (
									id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
									user_id INTEGER,
									name TEXT )");

	$dbh->do("DROP TABLE IF EXISTS settings");
	$dbh->do("CREATE TABLE settings (
									user_id INTEGER,
									delete_after INTEGER)");
		
}


# By getting the number of tables that already exist 
# and comparing it to the number that they are supposed to be 
# the function call "create_table" function if necessary.
sub create_tables_if_necessary {
	my $stget = $dbh->prepare(qq{SELECT count(*) FROM sqlite_master WHERE type = 'table'});
	$stget->execute();
	if ($stget->fetchrow_array() < NUMBER_OF_TABLES + 1) {
		create_tables();
	}
}


# Disconnecting from the DB when exiting the program;
END { 
	$dbh->disconnect();
}


1;