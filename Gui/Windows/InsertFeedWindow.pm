package InsertFeedWindow;

use strict;
use warnings;
use utf8;
use Gui::Panels::LeftPanel;
use Wx qw(:everything);
use Wx::Event qw(EVT_BUTTON);

use base qw(Wx::Dialog);

our ($feed_input, $category_input);

sub new {
	my $class = shift;

	# Initialize the dialog window and center it
	my $self = $class->SUPER::new(@_);
	$self->CenterOnScreen();

	my ($ID_OK, $ID_CANCEL) = (1..2);

	# Create the main sizer
	my $topSizer = Wx::BoxSizer->new(wxVERTICAL);
	$self->SetSizer($topSizer);

	# Create a sizer for the inputs and the labels and add it to the main sizer
	my $boxSizer = Wx::BoxSizer->new(wxVERTICAL);
	$topSizer->Add($boxSizer, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);

	# Create a label and an input for the url and add them to the inputs sizer
	my $feed_url_label = Wx::StaticText->new($self, wxID_STATIC, "Feed url:", wxDefaultPosition, wxDefaultSize, 0);
	$boxSizer->Add($feed_url_label, 0, wxALIGN_LEFT | wxALL, 5);
	$feed_input = Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition, [300, -1], 0);
	$boxSizer->Add($feed_input, 0, wxGROW | wxALL, 5);

	# Create a sizer for the categories and add it to the main sizer
	my $categories_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
	$boxSizer->Add($categories_sizer, 0, wxGROW | wxALL, 5);

	# Create a label for the categories select cotrol and add it to the categories sizer
	my $category_label = Wx::StaticText->new($self, wxID_STATIC, "Category:", wxDefaultPosition, wxDefaultSize, 0);
	$categories_sizer->Add($category_label, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

	# Get the categories in the form of id => name, id => name
	my %categories =  %{Categories::get_categories_for_current_user()};

	# Sort the categories numerically on their ids
	my @categories_ids = sort { $a <=> $b } keys %categories;

	# Get the names corresponding to the sorted ids
	my @categories_names;
	push @categories_names, $categories{$_} foreach(@categories_ids);

	# Create an select menu for the categories
	$category_input = Wx::Choice->new($self, wxID_ANY, wxDefaultPosition, [250, -1]);

	# Add the categories and their ids as additional data
	for my $i (0..$#categories_names)
	{
		$category_input->Append($categories_names[$i], $categories_ids[$i]);
	}

	# Select the first category from the select box and add it to the category sizer
	$category_input->SetSelection(0);
	$categories_sizer->Add($category_input, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

	# Add a spacer box
	$categories_sizer->Add(5, 5, 1, wxALIGN_CENTER_VERTICAL | wxALL, 5);

	# Draw a static horizonal line
	my $line = Wx::StaticLine->new($self, wxID_STATIC, wxDefaultPosition, wxDefaultSize, wxLI_HORIZONTAL);
	$boxSizer->Add($line, 0, wxGROW | wxALL, 5);

	# Create a sizer for the insert and cancel buttons
	my $okCancelBox = Wx::BoxSizer->new(wxHORIZONTAL);
	$boxSizer->Add($okCancelBox, 0, wxALIGN_RIGHT | wxALL, 5);

	# Create and add an insert/cancel buttons to their sizer, placing them horizontally side by side
	my $insert = Wx::Button->new($self, $ID_OK, 'Insert', wxDefaultPosition, wxDefaultSize, 0);
	$okCancelBox->Add($insert, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);
	my $cancel = Wx::Button->new($self, $ID_CANCEL, 'Cancel', wxDefaultPosition, wxDefaultSize, 0);
	$okCancelBox->Add($cancel, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

	# Sizes the window so that it fits around its subwindows
	$topSizer->Fit($self);

	# Handle events for the cancel and insert buttons
	EVT_BUTTON($self, $ID_OK, \&insert_feed);
	EVT_BUTTON($self, $ID_CANCEL, \&close_dialog);

	return $self;
}

sub insert_feed {
	my ($self) = @_;

	# Get the feed's url and the selected category's id
	my $feed_url = $feed_input->GetValue();
	my $category_id = $category_input->GetClientData($category_input->GetSelection());

	# Get the message from the validating function
	my $validation_message = Feeds::validate_insert_feed($feed_url);

	if($validation_message eq '') {
		# Insert the feed url in the selected category
		Feeds::insert_feed($feed_url, $category_id);

		# Regenerate the list of news in the right panel and the categories list in the left
		LeftPanel::generate_categories_list();
		RightPanel::generate_first_feeds_news();

		# Close the dialog window
		$self->close_dialog();
	} else {
		# The validation didn't pass, show the returned message
		Wx::MessageBox($validation_message);
	}


}

sub close_dialog {
	my ($self) = @_;

	# Close the dialog window with a return code 0
	$self->EndModal(0);
}
1;