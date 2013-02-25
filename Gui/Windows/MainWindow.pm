package MainWindow;

use strict;
use warnings;
use utf8;
use Gui::Panels::LeftPanel;
use Gui::Panels::RightPanel;
use Gui::Windows::SplitterWindow;
use Gui::Windows::InsertFeedWindow;
use Gui::Windows::ChangeFeedCategoryWindow;
use Gui::Windows::SettingsWindow;
use Gui::Windows::LoginWindow;
use Aquareader::Login;
use Aquareader::Categories;
use POSIX qw(strftime);
use Wx qw(:everything);
use Wx::Event qw(EVT_MENU);

use base qw(Wx::Frame);

our ($ID_SEARCH, $ID_MARK_NEWS, $ID_INSERT_FEED, $ID_DELETE_FEED, $ID_CHANGE_FEED_CATEGORY,
$ID_INSERT_CATEGORY, $ID_DELETE_CATEGORY, $ID_SETTINGS, $ID_LOGOUT, $ID_ABOUT, $ID_DELETE_ACCOUNT) = (0 .. 11); # IDs array

sub new {
	my ($class) = shift;
	my ($self) = $class->SUPER::new(@_);

	# News submenu
	my $news = Wx::Menu->new();
	$news->Append($ID_SEARCH, "Search news\tCtrl+F");
	$news->AppendSeparator();
	$news->Append($ID_MARK_NEWS, "Mark all news as read\tCtrl+M");

	# Feeds submenu
	my $feeds = Wx::Menu->new();
	$feeds->Append($ID_INSERT_FEED, "Add feed\tCtrl+A");
	$feeds->AppendSeparator();
	$feeds->Append($ID_DELETE_FEED, "Delete feed\tCtrl+D");
	$feeds->AppendSeparator();
	$feeds->Append($ID_CHANGE_FEED_CATEGORY, "Change feed's category");

	# Categories submenu
	my $categories = Wx::Menu->new();
	$categories->Append($ID_INSERT_CATEGORY, "Add category");
	$categories->AppendSeparator();
	$categories->Append($ID_DELETE_CATEGORY, "Delete category");

	# Options submenu
	my $options = Wx::Menu->new();
	$options->Append($ID_SETTINGS, "Settings\tCtrl+S");
	$options->Append($ID_DELETE_ACCOUNT, "Delete account");
	$options->Append($ID_ABOUT, 'About Aquareader');

	# Exit submenu
	my $exit = Wx::Menu->new();
	$exit->Append($ID_LOGOUT, "Logout\tCtrl+L");
	$exit->Append(wxID_EXIT, "Exit\tCtrl+X");

	# Create the menu bar
	my $menubar = Wx::MenuBar->new();
	$menubar->Append($news, "News");
	$menubar->Append($feeds, "Feeds");
	$menubar->Append($categories, "Categories");
	$menubar->Append($options, "Options");
	$menubar->Append($exit, "Exit");

	# Attach the menubar to the window
	$self->SetMenuBar($menubar);

	# Set a status bar
	$self->CreateStatusBar(4);

	my $user_names = join(' ', @{Login::get_names()});
	my $time = POSIX::strftime("%d.%m.%Y", gmtime());

	$self->SetStatusText("Logged as: $user_names", 2);
	$self->SetStatusText($time, 3);


	# Split the window into two subwindows
	my ($splitter) = SplitterWindow->new($self);

	# Initialize the two subwindows with the left and right panels
	my ($left_panel) = LeftPanel->new($splitter);
	my ($right_panel) = RightPanel->new($splitter, $self);
	$splitter->Initialize($left_panel);
	$splitter->Initialize($right_panel);

	my ($left_panel_minimum_size) = 210;

	# Set the minimum panel size for the left panel and split the main window
	$splitter->SetMinimumPaneSize($left_panel_minimum_size);
	$splitter->SplitVertically($left_panel, $right_panel, $left_panel_minimum_size);


	# Handle clicks on the menu items
	EVT_MENU($self, $ID_SEARCH, \&search_in_news);
	EVT_MENU($self, $ID_MARK_NEWS, \&mark_as_read);
	EVT_MENU($self, $ID_INSERT_FEED, \&insert_feed);
	EVT_MENU($self, $ID_DELETE_FEED, \&delete_feed);
	EVT_MENU($self, $ID_CHANGE_FEED_CATEGORY, \&change_feed_category);
	EVT_MENU($self, $ID_INSERT_CATEGORY, \&insert_category);
	EVT_MENU($self, $ID_DELETE_CATEGORY, \&delete_category);
	EVT_MENU($self, $ID_SETTINGS, \&update_settings);
	EVT_MENU($self, $ID_LOGOUT, \&logout);
	EVT_MENU($self, $ID_ABOUT, \&display_about);
	EVT_MENU($self, wxID_EXIT, \&close_window);
	EVT_MENU($self, $ID_DELETE_ACCOUNT, \&delete_account);

	return $self;
}

sub search_in_news {
	my ($self) = @_;

	# Create the dialog box
	my $dialog = Wx::TextEntryDialog->new($self, "What to search for:", "Search in all news");

	# If the user clicked okay and not cancel do the search and display the results
	if ($dialog->ShowModal() == wxID_OK) {
		my ($search_word) = $dialog->GetValue();

		# Get the news the match the search and show them in the right panel
		my $found_news = News::search_news($search_word);
		RightPanel::generate_news_list($found_news);
	}
}

sub mark_as_read {
	# Mark all the news as read
	News::mark_all_news_as_read();

	# Refresh the left panel so that the nubmers of read news are updated
	LeftPanel::generate_categories_list();

	# Refresh the right panel so that the read news are no longer showed in bold
	RightPanel::generate_first_feeds_news();
}

sub insert_feed {
	my ($self) = @_;

	# Create the add feed window and wait for a user action
	my $insert_feed_window = InsertFeedWindow->new($self, -1, "Add feed");
	$insert_feed_window->Centre();
	$insert_feed_window->ShowModal();
}

sub delete_feed {
	my ($self) = @_;

	# Get the feeds
	my %feeds =  %{Feeds::get_feeds_names()};

	# Sort the feeds by id, e.g the last is the one that was added last
	my @feeds_ids = sort { $a <=> $b } keys %feeds;

	# Get the corresponding feeds names
	my @feeds_names;
	push @feeds_names, $feeds{$_} foreach(@feeds_ids);

	# Create the dialog from which the user will choose which feed to delete
	my $feed_deletion = Wx::SingleChoiceDialog->new($self, "Select a feed to be deleted:", "Delete feed", \@feeds_names, \@feeds_ids);

	# If the user clicked okay and not cancel do the deletion
	if($feed_deletion->ShowModal() == wxID_OK) {
		my $feed_name = $feed_deletion->GetSelectionClientData();
		Feeds::delete_feed($feed_name);
		LeftPanel::generate_categories_list();
		RightPanel::generate_first_feeds_news();
	}
}

sub change_feed_category {
	my ($self) = @_;

	# Create the change feed category subwindow and wait for a user action
	my $change_feed_category_window = ChangeFeedCategoryWindow->new($self, -1, "Chage feed category");
	$change_feed_category_window->Centre();
	$change_feed_category_window->ShowModal();
}

sub insert_category {
	my ($self) = @_;

	# Create the dialog box
	my $dialog = Wx::TextEntryDialog->new($self, "Category name:", "Add category");

	# If the user clicked okay and not cancel do the insertion
	if( $dialog->ShowModal() == wxID_OK) {
		my $category_name = $dialog->GetValue();

		# Get the message from the validating function
		my $validation_message = Categories::validate_insert_category($category_name);

		if($validation_message eq '') {
			# Add the new category and regenerate the list of categories
			Categories::insert_category($category_name);
			LeftPanel::generate_categories_list();
		} else {
			$dialog = Wx::TextEntryDialog->new($self, "Category name:", "Add category");

			# The validation didn't pass, show the returned message
			Wx::MessageBox($validation_message);
		}
	}
}

sub delete_category {
	my ($self) = @_;

	# Get the categories
	my %categories =  %{Categories::get_categories_for_current_user()};

	my $general_gategory_id = Categories::get_category_id("General");

	# Sort the categories by id, e.g the last is the one that was added last
	my @categories_ids = sort { $a <=> $b } (grep { $_ != $general_gategory_id } keys %categories);

	# Get the corresponding categories names
	my @categories_names;
	push @categories_names, $categories{$_} foreach(@categories_ids);

	# Create the dialog from which the user will choose which feed to delete
	my $category_deletion = Wx::SingleChoiceDialog->new($self, "Select a category to be deleted:", "Delete category", \@categories_names, \@categories_ids);

	# If the user clicked okay and not cancel do the deletion
	if($category_deletion->ShowModal() == wxID_OK) {
		# Delete the selected category
		Categories::delete_category($category_deletion->GetSelectionClientData());

		# Regenerate the categories without the deleted one
		LeftPanel::generate_categories_list();
	}
}

sub logout {
	my ($self) = @_;

	# Logout the current user
	Login::logout();

	# Close the window
	$self->close_window();
}



sub update_settings {
	my ($self) = @_;

	# Create the settings subwindow and wait for a user action
	my $settings_window = SettingsWindow->new($self, -1, "Settings");
	$settings_window->Centre();
	$settings_window->ShowModal();
}

sub display_about {
	my ($self) = @_;

	# About text, describing the purpouse and functionality of the app
	my $about_text = <<ABOUT;
Welcome to Aquareader!
ABOUT

	# Display the About message box
	Wx::MessageBox($about_text, 'About', wxOK|wxICON_INFORMATION, $self);
}

sub delete_account {
	my ($self) = @_;

	# Delete our account
	Login::delete_account();

	# Close the window
	$self->close_window();
}

sub close_window {
	my ($self) = @_;

	# Close the main window
	$self->Close(0);
}

1;