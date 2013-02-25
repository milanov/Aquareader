package LeftPanel;

use strict;
use warnings;
use utf8;
use Gui::Panels::RightPanel;
use Wx qw(:everything);
use Wx::Event qw(EVT_TREE_ITEM_ACTIVATED);

use base qw(Wx::TreeCtrl);

our $self;
our $ID_TREE = 1;

sub new {
	my ($class, $parent_window) = @_;

	# Initialize the TreeCtrl contol
	$self = $class->SUPER::new($parent_window, $ID_TREE, wxDefaultPosition, wxDefaultSize, wxTR_HIDE_ROOT);

	# Set the background colour to a light blue
	$self->SetBackgroundColour(Wx::Colour->new(210, 225, 230));

	# Set the font to bold arial
	$self->SetFont(Wx::Font->new(9, wxSWISS, wxNORMAL, wxBOLD, 0, "Arial"));

	# Generate the categories tree
	generate_categories_list();

	$self->Refresh();
	return $self;
}

sub generate_categories_list {
	# Remove the current elements
	$self->DeleteAllItems();

	my $root = $self->AddRoot('');

	# Sort the categories
	my %categories = %{Categories::get_categories_for_current_user()};
	my @categories_ids = sort { $a <=> $b } keys %categories;

	# Marks if any feed exist so that later it can be selected
	my $id_to_select = undef;

	foreach my $category_id (@categories_ids) {
		# Add the category name as a parent item
		my $category_name = $categories{$category_id};
		my $category_name_tree = $self->AppendItem($root, $category_name);

		foreach my $feed (@{Feeds::get_feeds_for_category($category_id)}) {
			# Get the number of unread news for the current feed
			my $unread_news = News::get_number_unread_news_for_feed($$feed{'id'});

			# Add this number to the feed name if there are unread news
			my $feed_name = $$feed{'name'};
			$feed_name .= " ($unread_news)" if $unread_news != 0;

			# Add the feed to its parent item (its category)
			my $feed_entry = $self->AppendItem($category_name_tree, $feed_name, -1, -1, Wx::TreeItemData->new($$feed{'id'}));

			# Initialize which feed will be selected by default
			$id_to_select = $feed_entry unless defined($id_to_select);
		}
	}

	# If any feed exists, select it
	Wx::TreeCtrl::SelectItem($self, $id_to_select) if defined($id_to_select);

	# Handle the click on a tree element
	EVT_TREE_ITEM_ACTIVATED($self, $ID_TREE, \&feed_selected);

	# Expand all the elements in the tree
	Wx::TreeCtrl::ExpandAll($self);
}

sub feed_selected {
	my ($self) = @_;

	# Get the itemdata of the clicked tree item
	my $item = Wx::TreeCtrl::GetItemData($self, $self->GetSelection());
	if($item) {
		# The item is a feed, so get its id
		my $feed_id = $item->GetData();

		# Get the news for the selected feed and show them in the right panel
		my $news_for_feed = News::get_news_for_feed($feed_id);
		RightPanel::generate_news_list($news_for_feed);
	}
}

1;