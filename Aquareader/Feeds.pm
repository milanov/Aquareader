package Feeds;

use strict;
use warnings;
use XML::RSS::Parser;
use utf8;
use Aquareader::Login qw (get_current_user);
use Aquareader::News qw (insert_news_if_necessary delete_news_for_feed);

my $db = $CreateDB::dbh;


# Takes a feed's url and a user's id and returns the feed's id from the feeds' table.
sub get_feed_id_by_url ($) {
	my ($url) = @_;
	my $user_id = Login::get_current_user();
	my $stget = $db->prepare("SELECT id FROM feeds WHERE url = ? AND user_id = ?")
				or die "Can't prepare statement: $DBI::errstr";

	$stget->execute($url, $user_id)
				or die "Can't execute statement: $DBI::errstr";

	my $id = $stget->fetchrow_array();
	$stget->finish();
	# If this feed doesn't exist returns 0.
	return  defined($id) ? $id : 0 ;
}


# Takes a feed's id.
# Returns a feed's url corresponding to this id.
sub get_feed_url_by_id ($) {
	my ($feed_id) = @_;
	my $stget = $db->prepare("SELECT url FROM feeds WHERE id = ?")
				or die "Can't prepare statement: $DBI::errstr";

	$stget->execute($feed_id)
				or die "Can't execute statement: $DBI::errstr";

	my $url = $stget->fetchrow_array();
	$stget->finish();
	return $url;
}


# Takes a feed's url and a category.
# Inserts the feed into the feeds table.
# After finishing returns an appropriate message.
sub insert_feed ($ $) {
	my ($feed_url, $category_id) = @_;
	my $user_id = Login::get_current_user();

	my $rss_parser = new XML::RSS::Parser;
	my $feed = $rss_parser->parse_uri($feed_url);
	# The actual inserting is wrapped in eval{} in case there isn't a connection or some other error occurs
	eval {
		my $feed_name = $feed->query('/channel/title');

		my $stins = $db->prepare("INSERT INTO feeds(user_id, name, category_id,  url) VALUES (?, ?, ?, ?)")
			or die "Can't prepare statement: $DBI::errstr";
		$stins->execute($user_id, $feed_name->text_content, $category_id, $feed_url)
			or die "Can't execute statement: $DBI::errstr";
		$stins->finish();

		# Inserting the news from this feed.
		News::insert_news_if_necessary(get_feed_id_by_url($feed_url));
	};
}


# Takes a feed url.
# Checks if the inputed feed is already inserted.
# If not, returns an appropriate message.
# if it's not inserted, returns an empty string.
sub validate_insert_feed ($) {
	my ($feed_url) = @_;
	if ($feed_url =~ /^\s*$/) {
		return "Please fill in the blank.";
	}
	# Checks if an account with the same username already exists
	if (get_feed_id_by_url($feed_url)) {
		return 'This feed has already been added.';
	}
	my $rss_parser = new XML::RSS::Parser;
	my $feed = $rss_parser->parse_uri($feed_url);
	if (! defined ($feed)) {
		return "Error in parsing the feed url.";
	}
	return "";
}


# Takes a feed's url and a category's name
# Changes the feed's category to the given one as an argument.
sub change_feed_category ($ $) {
	my ($feed_id, $new_category_id) = @_;
	my $stupd = $db->prepare("UPDATE feeds SET category_id = ? WHERE id = ?")
		or die "Can't prepare statement: $DBI::errstr";
	$stupd->execute($new_category_id, $feed_id)
		or die "Can't execute statement: $DBI::errstr";
	$stupd->finish();
}


# Takes a feed's id.
# Deletes all the news from this feed from the news table and then deletes it from the feeds table.
sub delete_feed ($) {
	my ($feed_id) = @_;
	# Deleting the news:
	News::delete_news_for_feed($feed_id);
	# Deleting the feed:
	my $stdel = $db->prepare ("DELETE FROM feeds WHERE id = ?")
		or die "Can't prepare statement: $DBI::errstr";
	$stdel->execute($feed_id)
		or die "Can't execute statement: $DBI::errstr";
	$stdel->finish();
}


# Takes a category's id
# Returns an array of hash references with the ids and names of the feeds for that category
sub get_feeds_for_category($) {
	my ($category_id) = @_;
	my @feeds;
	my $stget = $db->prepare ("SELECT id, name FROM feeds WHERE category_id = ? ORDER BY id ASC")
		or die "Can't prepare statement: $DBI::errstr";
	$stget->execute($category_id)
		or die "Can't execute statement: $DBI::errstr";
	while (my ($id, $name) = $stget->fetchrow_array()) {
		my %single_feed = ( "id" => $id,
							"name" => $name);
		push @feeds, (\%single_feed);
	}
	$stget->finish();
	return \@feeds;
}


# Returns a hash reference with keys - the feeds' ids and values - the corresponding names
sub get_feeds_names {
	my $user_id = Login::get_current_user();
	my $stget = $db->prepare("SELECT id, name FROM feeds WHERE user_id = ?")
		or die "Can't prepare statement: $DBI::errstr";
	$stget->execute($user_id);
	my %hash_feeds;
	while (my ($id, $name) = $stget->fetchrow_array()) {
		$hash_feeds{$id} = $name;
	}
	$stget->finish();
	return \%hash_feeds;
}


# Returns the id of the first feed that appears in the list of feeds for the current user
sub get_first_feed_id {
	my $user_id = Login::get_current_user();
	my $stget = $db->prepare("SELECT id FROM feeds WHERE user_id = ? ORDER BY category_id ASC LIMIT 1 ")
		or die "Can't prepare statement: $DBI::errstr";
	$stget->execute($user_id)
		or die "Can't execute statement: $DBI::errstr";
	my $id = $stget->fetchrow_array();
	$stget->finish();
	return $id;
}


1;