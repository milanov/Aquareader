package Categories;

use strict;
use warnings;
use utf8;
use Aquareader::Login qw (get_current_user);

my $db = $CreateDB::dbh;


# Takes a category's name and returns this category's id for the current logged in user.
sub get_category_id ($) {
	my ($category_name) = @_;
	my $user_id = Login::get_current_user();
	my $stget = $db->prepare("SELECT id FROM categories WHERE name = ? AND user_id = ? ") 
			or die "Can't prepare statement: $DBI::errstr";
	$stget->execute($category_name, $user_id)
			or die "Can't execute statement: $DBI::errstr";
	my $id = $stget->fetchrow_array();
	$stget->finish();
	# If this category doesn't exist returns 0.
	return  defined($id) ? $id : 0 ; 
}


# Takes a category's name.
# Inserts this category into the categories table.
sub insert_category($) {
	my ($category_name) = @_;
	my $user_id = Login::get_current_user();
	
	my $stins = $db->prepare("INSERT INTO categories(name, user_id) VALUES (?, ?)") 
			or die "Can't prepare statement: $DBI::errstr";
	$stins->execute($category_name, $user_id)
			or die "Can't execute statement: $DBI::errstr";
	$stins->finish();
} 


# Takes a category's name.
# Checks if the inputed category's name is already inserted.
# If it is, returns an appropriate message.
# if it's not, returns an empty string.
sub validate_insert_category ($) {
	my ($category_name) = @_;
	if ($category_name =~ /^\s*$/) {
		return "Please fill in the blank.";
	}
	# Checks if a category with the same name already exists for this user. 
	if (get_category_id($category_name)) {
		return 'This category has already been added.';
	}
	return ""; 
}


# Takes a category's name and deletes this category from the categories table.
# If there's a feed that belonged to the removed category it is transfered to the 'General' category (with id = 1).
sub delete_category ($) {
	my ($category_id) = @_;
	my $general_id = get_category_id ("General");
	my $stupd = $db->prepare("UPDATE feeds SET category_id = ? WHERE category_id = ?")
			or die "Can't prepare statement: $DBI::errstr";
	$stupd->execute($general_id, $category_id)
			or die "Can't execute statement: $DBI::errstr";
	$stupd->finish();
	my $stdel = $db->prepare("DELETE FROM categories WHERE id = ?");
	$stdel->execute($category_id)
			or die "Can't execute statement: $DBI::errstr";
	$stdel->finish();
}


# Returns as a hash the names of all categories for the current logged in user.
sub get_categories_for_current_user {
	my $user_id = Login::get_current_user();
	my $stget = $db->prepare("SELECT id, name FROM categories WHERE user_id = ?")
			or die "Can't prepare statement: $DBI::errstr";
	$stget->execute($user_id)
			or die "Can't execute statement: $DBI::errstr";
	my %hash_category;
	while (my ($id, $name) = $stget->fetchrow_array()) {
		$hash_category{$id} = $name;
	}
	$stget->finish();
	return \%hash_category;
}


1;