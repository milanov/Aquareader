package News;

use strict;
use warnings;
use utf8;
use HTML::Restrict;
use Date::Parse;
use XML::RSS::Parser;
use Aquareader::Login qw (get_current_user);
use Aquareader::Settings qw(convert_delete_time_to_timestamp);
use Aquareader::Feeds qw(get_feed_url_by_id);

my $db = $CreateDB::dbh;


# Deletes all news for the current user that has been added before a certain number of days.
sub delete_old_news_if_necessary {
	my $limit_time = Settings::convert_delete_time_to_timestamp();

	if ($limit_time == 0) {
		return;
	}
	my $user_id = Login::get_current_user();

	my $stdel = $db->prepare("DELETE FROM news WHERE date < ? AND user_id = ?")
		or die "Can't prepare statement: $DBI::errstr";
	$stdel->execute($limit_time, $user_id)
		or die "Can't execute statement: $DBI::errstr";
	$stdel->finish();
}


# Takes a feed's id.
# Deletes all news from this feed.
sub delete_news_for_feed ($) {
	my ($feed_id) = @_;
	my $stdel = $db->prepare ("DELETE FROM news WHERE feed_id = ?")
		or die "Can't prepare statement: $DBI::errstr";
	$stdel->execute($feed_id)
		or die "Can't execute statement: $DBI::errstr";
	$stdel->finish();
}


# Takes a feed's id.
# Returns a reference to an array which contains hash references for all news from this feed.
sub get_news_for_feed($) {
	my ($feed_id) = @_;
	my @news;
	my $stget = $db->prepare ("SELECT id, title, feed_id, url, read, date, description FROM news WHERE feed_id = ? ORDER BY date DESC")
		or die "Can't prepare statement: $DBI::errstr";
	$stget->execute($feed_id)
		or die "Can't execute statement: $DBI::errstr";
	while (my ($id, $title, $feed_id, $url, $read, $date, $desc) = $stget->fetchrow_array()) {
		# creating the hashes
		my %single_news = ( "id" =>  $id,
							"title" => $title,
							"feed_id" => $feed_id, 
							"url" => $url, 
							"read" => $read, 
							"date" =>  $date,
							"description" => $desc);
		push @news, (\%single_news);
	}
	$stget->finish();
	return \@news;
}


# Takes a feed's url and id 
# Inserts all news that haven't been inserted for this feed
sub insert_news_if_necessary ($) {
	my ($feed_id) = @_;
	my $user_id = Login::get_current_user();
	my $feed_url = Feeds::get_feed_url_by_id($feed_id);

	# Getting the timestamp limit in order to insert only new news
	my $limit_date = Settings::convert_delete_time_to_timestamp();

	# Getting the latest news from the database for this feed 
	# in order not to add already added news
	my $stget = $db->prepare("SELECT date FROM news WHERE feed_id = ? ORDER BY date DESC LIMIT 1")
			or die "Can't prepare statement: $DBI::errstr";
	$stget->execute($feed_id)
			or die "Can't execute statement: $DBI::errstr";
	my $last_date = $stget->fetchrow_array();
	$stget->finish();

	if (! defined($last_date)) {
		# If there isn't inserted news yet
		$last_date = $limit_date;
	}
	# Parsing the url:
	my $rp = new XML::RSS::Parser;
    my $feed = $rp->parse_uri($feed_url);
	my $hr = HTML::Restrict->new();
	my $stins = $db->prepare("INSERT INTO news(user_id, title, feed_id,  url, read, date, description) VALUES (?, ?, ?, ?, ?, ?, ?)") 
			or die "Can't prepare statement: $DBI::errstr";

	# The actual inserting is wrapped in eval{} in case there isn't a connection or some other error occurs
	eval {
		foreach my $i ( $feed->query('//item') ) {
			# Converts the date into seconds
			my $date = str2time($i->query('pubDate')->text_content);
			# If we reach news that is beyond our time limitations...
			next if ($date <= $last_date || $date < $limit_date);
			my $title = $i->query('title')->text_content;
			my $url = $i->query('link')->text_content;
			# Removes the unnecessary HTML tags
			my $description = $hr->process($i->query('description')->text_content);
			$stins->execute($user_id, $title, $feed_id, $url, 0, $date, $description)
					or die "Can't execute statement: $DBI::errstr";
		}
	};
	$stins->finish();
}


# Takes the url of a news item.
# Marks this news as read.
sub read_news ($) {
	my ($news_url) = @_;
	my $user_id = Login::get_current_user();
	my $stupd = $db->prepare("UPDATE news SET read = '1' WHERE url = ? AND user_id = ?")
		or die "Can't prepare statement: $DBI::errstr";
	$stupd->execute($news_url, $user_id)
		or die "Can't execute statement: $DBI::errstr";
	$stupd->finish();
}


# Marks all news in the DB for the current user as read.
sub mark_all_news_as_read  {
	my $user_id = Login::get_current_user();
	my $stupd = $db->prepare("UPDATE news SET read = '1' WHERE user_id = ?")
		or die "Can't prepare statement: $DBI::errstr";
	$stupd->execute($user_id)
		or die "Can't execute statement: $DBI::errstr";
	$stupd->finish();	
}


# Takes a string.
# Returns all news that contains this string in the title or in the description of the news.
sub search_news ($) {
	my ($string) = @_;
	my $user_id = Login::get_current_user();
	my $stget = $db->prepare("SELECT id, title, feed_id, url, read, date, description FROM news WHERE user_id = ?
							 AND (description LIKE '%$string%' OR title LIKE '%$string%') ORDER BY feed_id ASC, date DESC")
		or die "Can't prepare statement: $DBI::errstr";
	$stget->execute($user_id)
		or die "Can't execute statement: $DBI::errstr";
	my @matched_news;
	while (my ($id, $title, $feed_id, $url, $read, $date, $desc) = $stget->fetchrow_array()) {
		my %single_news = ( "id" =>  $id,
							"title" => $title,
							"feed_id" => $feed_id, 
							"url" => $url, 
							"read" => $read, 
							"date" =>  $date,
							"description" => $desc);
		push @matched_news, (\%single_news);
	}
	$stget->finish();
	return \@matched_news;
}


# Takes a feed's id.
# Returns the number of unread news for this feed.
sub get_number_unread_news_for_feed ($) {
	my ($feed_id) = @_;
	my $stget = $db->prepare("SELECT COUNT (*) FROM news WHERE read = ? AND feed_id = ?")          
		or die "Can't prepare statement: $DBI::errstr";
	$stget->execute('0', $feed_id)
		or die "Can't execute statement: $DBI::errstr";
	my $number = $stget->fetchrow_array();
	$stget->finish();
	return $number;
}


1;