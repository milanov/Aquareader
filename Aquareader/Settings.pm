package Settings;

use strict;
use warnings;
use Aquareader::Login qw(get_current_user);

my $db = $CreateDB::dbh;


# Takes a user's id.
# Inserts the number of 'delete_after' days in the settings table to be 1 for this user.
# This means the inserted news has an expiration period of 1 day.
sub insert_delete_days ($) {
	my ($user_id) = @_;
	my $stinsset = $db->prepare ("INSERT INTO settings (user_id, delete_after) VALUES (?, ?) ")
		or die "Can't prepare statement : $DBI::errstr";
	$stinsset->execute($user_id, '1');
	$stinsset->finish();	
}


# Takes a number of days.
# Changes the number of days for deleting news in the DB for the current logged in user.
sub update_delete_after_days ($) {
	my ($days) = @_;
	my $user_id = Login::get_current_user();
	my $stupd = $db->prepare("UPDATE settings SET delete_after = ? WHERE user_id = ?")
		or die "Can't prepare statement: $DBI::errstr";
	$stupd->execute($days, $user_id)
		or die "Can't execute statement: $DBI::errstr";
	$stupd->finish();
}


# Takes a number of days.
# Checks if the inputed data is valid.
# If not, returns an appropriate message.
# if it's valid, returns an empty string.
sub validate_update_delete_days ($) {
	my ($days) = @_;
	return "Incorrect input! Please enter only digits." unless ($days =~ /^\d+$/);
	return "Negative number of days." if ($days < 0);
	return "";
}


# Returns the number of days for deleting news for the current logged in user.
sub get_delete_after_days {
	my $user_id = Login::get_current_user();
	my $stget = $db->prepare("SELECT delete_after FROM settings WHERE user_id = ?")
		or die "Can't prepare statement: $DBI::errstr";
	$stget->execute($user_id)
		or die "Can't execute statement: $DBI::errstr";
	my $days = $stget->fetchrow_array();
	$stget->finish();
	return $days;
}


# Returns a UNIX timestamp limit that shows which news to be deleted for the current logged in user. 
# This limit is the current time minus the number of days from the DB in seconds
# and any news with a timestamp less than the limit should be deleted (or not added at all).
sub convert_delete_time_to_timestamp  {
	my $user_id = Login::get_current_user();
	my $stget = $db->prepare("SELECT delete_after FROM settings where user_id = ?")
		or die "Can't prepare statement: $DBI::errstr";
	$stget->execute($user_id)
		or die "Can't execute statement: $DBI::errstr";
	my $days = $stget->fetchrow_array();
	$stget->finish();

	if ($days == 0) {
		# The user hasn't specified a deleting period.
		return 0;
	}

	# Getting the current time.
	my $current_time = time;
	my $seconds = $days*24*60*60;
	return $current_time - $seconds;
}


1;