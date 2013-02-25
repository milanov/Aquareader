package RightPanel;

use strict;
use warnings;
use utf8;
use Gui::Panels::RightPanel;
use POSIX qw(strftime);
use Wx qw(:everything);
use Wx::Event qw(EVT_HYPERLINK);

use base qw(Wx::ScrolledWindow);

our ($self, @current_news, $vbox, $top_level_window);

sub new {
	my $class = shift;
	my $parent_window = shift;
	$top_level_window = shift;

	# Initialize the window and set its scroll rate
	$self = $class->SUPER::new($parent_window, -1);

	# Generate the news for the first feed (the oldest one added)
	generate_first_feeds_news();

	return $self;
}


sub generate_first_feeds_news {
	my $first_feed_id = Feeds::get_first_feed_id();
	my $news_for_feed = News::get_news_for_feed($first_feed_id);

	# Generate the news list using the news belonging to the oldest feed
	generate_news_list($news_for_feed);
}

sub generate_news_list($) {
	# Get the news list and update the current news with this list
	my ($news_ref) = @_;
	my @news = @{$news_ref};
	@current_news = @news;

	$self->Freeze();
	$self->DestroyChildren();

	$vbox = Wx::BoxSizer->new(wxVERTICAL);
	for my $_news (@news) {
		my %news_item = %{$_news};

		# Create a panel for the current news item
		my $news_panel = Wx::Panel->new($self, wxID_ANY);

		# Create the current news item sizer and its title control
		my $news_sizer = Wx::BoxSizer->new(wxVERTICAL);
		my $news_title = Wx::HyperlinkCtrl->new($news_panel, $news_item{'id'}, $news_item{'title'}, $news_item{'url'},  wxDefaultPosition, wxDefaultSize, wxBORDER_NONE);

		# Make the font normal
		my $font = Wx::Font->new(10, wxDEFAULT, wxNORMAL, wxNORMAL);
		$news_title->SetFont($font);
		# If the news is not read, make it bold
		unless ($news_item{'read'}) {
			my $bold_font = Wx::Font->new(10, wxDEFAULT, wxNORMAL, wxBOLD);
			$news_title->SetFont($bold_font);
		}

		# Create the description and the date controls of the news item
		my $news_description = Wx::StaticText->new($news_panel, wxID_ANY, $news_item{'description'}, wxDefaultPosition);
		$news_description->Wrap(560);
		my $date = POSIX::strftime("%H:%I, %d %B, %Y", localtime($news_item{'date'}));
		my $news_date = Wx::StaticText->new($news_panel, wxID_ANY, $date);
		my $date_font = Wx::Font->new(7, wxDEFAULT, wxNORMAL, wxBOLD);
		$news_date->SetFont($date_font);

		# Draw a static horizonal line to separate the news from each other
		my $news_separator = Wx::StaticLine->new($news_panel, wxID_ANY);

		# Add all these controls to the news sizer, separated by some space
		$news_sizer->AddSpacer(5);
		$news_sizer->Add($news_title, 0);
		$news_sizer->AddSpacer(5);
		$news_sizer->Add($news_description, 0);
		$news_sizer->AddSpacer(5);
		$news_sizer->Add($news_date, 0);
		$news_sizer->AddSpacer(5);
		$news_sizer->Add($news_separator, 0, wxEXPAND | wxALIGN_LEFT , 20);

		# Add the sizer to the news panel
		$news_panel->SetSizer($news_sizer);

		# Add the whole panel to the main sizer
		$vbox->Add($news_panel, 0, wxEXPAND|wxALL);

		# Handle clicks on news
		EVT_HYPERLINK($self, $news_item{'id'}, \&news_clicked);
	}
	# Set the window sizer and add it a scroll
	$self->SetSizer($vbox);
	$self->SetScrollRate(10, 10);
	$vbox->Fit($self);
	$self->Thaw();

	# MY WORK HERE IS DONE
	my ($width, $height) = $top_level_window->GetSizeWH();
	$top_level_window->SetSize($width, $height+1);
	$top_level_window->SetSize($width, $height);
}

sub news_clicked {
	my ($self, $news) = @_;

	# Mark the current news as read
	my $news_url = $news->GetURL();
	News::read_news($news_url);

	# Mark the clicked news as read
	for my $_news (@current_news) {
		if($$_news{'url'} eq $news_url) {
			$$_news{'read'} = '1';
			last;
		}
	}

	# Regenerate the categories list
	LeftPanel::generate_categories_list();

	# Regenerate the news list with the current news
	generate_news_list(\@current_news);

	# Open the news url in the default browser
	Wx::LaunchDefaultBrowser($news_url);
}

1;