package Login;

use utf8;
use Digest::SHA qw (sha1);
use Aquareader::Categories qw (insert_category);
use Aquareader::Settings qw (insert_delete_days);
my $db = $CreateDB::dbh;


# Takes a username.
# Returns the corresponding id.
# If this user doesn't exist returns 0.
sub get_user_id ( $ ) {
  my ($username) = @_;
  my $stget = $db->prepare("SELECT id FROM users WHERE username = ?")
      or die "Can't prepare statement: $DBI::errstr";
  $stget->execute($username)
      or die "Can't execute statement: $DBI::errstr";
  my $id = $stget->fetchrow_array();
  $stget->finish();
  return  defined($id) ? $id : 0 ;
}


# Returns an array containing the names of the current user.
sub get_names  {
  my $user_id = get_current_user();
  my $sthget = $db->prepare("SELECT name, surname FROM users WHERE id = ?")
      or die "Can't prepare statement: $DBI::errstr";
  $sthget->execute($user_id)
      or die "Can't execute statement: $DBI::errstr";
  my @names = $sthget->fetchrow_array();
  $sthget->finish();
  return \@names;
}


# Returns the id of the current logged in user.
# If there is not a logged in user returns 0.
sub get_current_user {
  my $stget = $db->prepare("SELECT user_id FROM logins WHERE logout = '0' ")
       or die "Can't prepare statement: $DBI::errstr";
  $stget->execute()
       or die "Can't execute statement: $DBI::errstr";
  my ($user_id) = $stget->fetchrow_array();
  $stget->finish();
  return defined($user_id) ? $user_id : 0 ;
}


# Takes a username and a password and logs in the corresponding user.
# If this operation is succesfull, returns 1.
# If there is no such user in the users table, returns 0.
sub login ($ $) {
  my ($username, $password) = @_;
  my $converted_password = sha1($password);

  my $stget = $db->prepare("SELECT id FROM users WHERE username = ? AND password = ?")
       or die "Can't prepare statement: $DBI::errstr";
  $stget->execute($username, $converted_password)
      or die "Can't execute statement: $DBI::errstr";
  my $user_id = $stget->fetchrow_array();
  $stget->finish();

  return 0 if (!defined($user_id));

  my $stupd = $db->prepare("UPDATE logins SET logout = '0' WHERE user_id = ?")
       or die "Can't prepare statement: $DBI::errstr";
  $stupd->execute($user_id)
       or die "Can't execute statement: $DBI::errstr";
  $stupd->finish();
  return 1;
}


# Takes a username, passowrd, name and surname
# Registers new user.
sub register($ $ $ $) {
  my ($username, $password, $name, $surname) = @_;
  my $converted_password = sha1($password);

  my $stins_users = $db->prepare("INSERT INTO users (username, password, name, surname) VALUES (?, ?, ?, ?)")
      or die "Can't prepare statement: $DBI::errstr";
  $stins_users->execute($username, $converted_password, $name, $surname)
      or die "Can't execute statement: $DBI::errstr";
  $stins_users->finish();

  my $user_id = get_user_id($username);

  my $stins_logins = $db->prepare("INSERT INTO logins (user_id, logout) VALUES (?, ?)")
      or die "Can't prepare statement: $DBI::errstr";
  $stins_logins->execute($user_id, '0')
      or die "Can't execute statement: $DBI::errstr";
  $stins_logins->finish();
  Settings::insert_delete_days($user_id);
  Categories::insert_category('General');
}


# Takes a username, passowrd, name and surname.
# Checks if the inputed data is valid.
# If not, returns an appropriate message.
# if it's valid, returns an empty string.
sub validate_register ($ $ $ $) {
  my ($username) = @_;
  if (scalar (grep (!/^\s*$/, @_)) != scalar (@_) ) {
    return "Please fill in all the blanks.";
  }
  # Checks if an account with the same username already exists
  if (get_user_id($username)) {
    return "There is an account with the same username.";
  }
  unless ($username =~ /^\w+$/) {
    return "The username should contain only alphanumeric characters and underscores.";
  }
  return "";
}


# Logs out the current logged in user.
sub logout {
  my ($user_id) = get_current_user();
  my $stupd = $db->prepare ("UPDATE logins SET logout = '1' WHERE user_id = ? ")
      or die "Can't prepare statement: $DBI::errstr";
  $stupd->execute($user_id)
       or die "Can't execute statement: $DBI::errstr";
  $stupd->finish();
}


# Deletes the account of the current logged in user.
sub delete_account {
  my $user_id = get_current_user();

  my %categories = %{Categories::get_categories_for_current_user()};

  # Deleting the categories, feeds and news for this user.
  foreach my $key (keys %categories) {
    my @feeds = @{Feeds::get_feeds_for_category($key)};
    foreach my $feed_hash_ref (@feeds) {
      Feeds::delete_feed($$feed_hash_ref{"id"});
    }
  }

  # Deleting the data from the logins table.
  my $stdel_logins = $db->prepare("DELETE FROM logins WHERE user_id = ?")
      or die "Can't prepare statement: $DBI::errstr";
  $stdel_logins->execute($user_id)
      or die "Can't execute statement: $DBI::errstr";
  $stdel_logins->finish();

  # Deleting the data from the settings table.
  my $stdel_set = $db->prepare("DELETE FROM settings WHERE user_id = ?")
      or die "Can't prepare statement: $DBI::errstr";
  $stdel_set->execute($user_id)
      or die "Can't execute statement: $DBI::errstr";
  $stdel_set->finish();

  # Deleting the data from the users table.
  my $stdel_users = $db->prepare("DELETE FROM users WHERE id = ?")
      or die "Can't prepare statement: $DBI::errstr";
  $stdel_users->execute($user_id)
      or die "Can't execute statement: $DBI::errstr";
  $stdel_users->finish();
}


1;