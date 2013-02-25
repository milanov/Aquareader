package SettingsWindow;

use strict;
use warnings;
use utf8;
use Gui::Panels::LeftPanel;
use Wx qw(:everything);
use Wx::Event qw(EVT_BUTTON);

use base qw(Wx::Dialog);

our ($delete_after_input);

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

	# Create a sizer for the 'delete after' days and add it to the main sizer
	my $delete_after_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
	$boxSizer->Add($delete_after_sizer, 0, wxGROW | wxALL, 5);

	# Create a label and an input for the 'delete after days' and add them to the inputs sizer
	my $delete_after_label = Wx::StaticText->new($self, wxID_STATIC, "Delete news after (in days):");
	$delete_after_sizer->Add($delete_after_label, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

	# The current 'delete after' days
	my $current_delete_after_days = Settings::get_delete_after_days();

	# Create the input for the delete after days and display it
	$delete_after_input = Wx::TextCtrl->new($self, wxID_ANY, $current_delete_after_days, wxDefaultPosition, [200, -1], 0);
	$delete_after_sizer->Add($delete_after_input, 0, wxGROW | wxALL, 5);

	# Draw a static horizonal line
	my $line = Wx::StaticLine->new($self, wxID_STATIC);
	$boxSizer->Add($line, 0, wxGROW | wxALL, 5);

	# Create a sizer for the update and cancel buttons
	my $okCancelBox = Wx::BoxSizer->new(wxHORIZONTAL);
	$boxSizer->Add($okCancelBox, 0, wxALIGN_RIGHT | wxALL, 5);

	# Create and add an update/cancel buttons to their sizer, placing them horizontally side by side
	my $update = Wx::Button->new($self, $ID_OK, 'Update');
	$okCancelBox->Add($update, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);
	my $cancel = Wx::Button->new($self, $ID_CANCEL, 'Cancel');
	$okCancelBox->Add($cancel, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

	# Sizes the window so that it fits around its subwindows
	$topSizer->Fit($self);

	# Handle events for the cancel and update buttons
	EVT_BUTTON($self, $ID_OK, \&update_settings);
	EVT_BUTTON($self, $ID_CANCEL, \&close_dialog);

	return $self;
}

sub update_settings {
	my ($self) = @_;

	# Get the number of days in which we keep the news before deleting them
	my $delete_after_days = $delete_after_input->GetValue();

	my $validation_message = Settings::validate_update_delete_days($delete_after_days);
	if($validation_message eq '') {
		# Update the 'delete after' days
		Settings::update_delete_after_days($delete_after_days);

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