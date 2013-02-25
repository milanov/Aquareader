package RegisterWindow;

use strict;
use warnings;
use utf8;
use Aquareader::Login;
use Wx qw(:everything);
use Wx::Event qw(EVT_BUTTON);

use base qw(Wx::App);

sub OnInit {
	my $self  = shift;

	# Initialize and center the main window
	my $frame = RegisterWindowDialog->new(undef, -1, "Register to Aquareader");
	$frame->Centre();

	# Initialize and set the program icon
	Wx::InitAllImageHandlers();
	my $icon = Wx::Icon->new("Gui/resources/icon.png", wxBITMAP_TYPE_PNG, 16, 16);
	$frame->SetIcon($icon);

	# Show the window and wait for a user action
	$frame->Show(1);
	$frame->ShowModal();

	# Set our main window to be the top program window
	$self->SetTopWindow($frame);

	return 1;
}

package RegisterWindowDialog;

use strict;
use warnings;
use utf8;
use Aquareader::Login;
use Wx qw(:everything);
use Wx::Event qw(EVT_BUTTON);

use base qw(Wx::Dialog);

our ($username_input, $password_input, $password_confirmation_input, $first_name_input, $last_name_input);

sub new {
	my $class = shift;

	# Initialize the dialog window and center it
	my $self = $class->SUPER::new(@_);
	$self->CenterOnScreen();

	my ($ID_REGISTER, $ID_EXIT) = (1..2);

	# Create the main sizer
	my $topSizer = Wx::BoxSizer->new(wxVERTICAL);
	$self->SetSizer($topSizer);

	# Create a sizer for the inputs and the labels and add it to the main sizer
	my $boxSizer = Wx::BoxSizer->new(wxVERTICAL);
	$topSizer->Add($boxSizer, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);

	# Create a label and an input for the username
	my $username_label = Wx::StaticText->new($self, wxID_STATIC, "Username:");
	$boxSizer->Add($username_label, 0, wxALIGN_LEFT | wxALL, 5);
	$username_input = Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition, [200, -1], 0);
	$boxSizer->Add($username_input, 0, wxGROW | wxALL, 5);

	# Create a label and an input for the password
	my $password_label = Wx::StaticText->new($self, wxID_STATIC, "Password:");
	$boxSizer->Add($password_label, 0, wxALIGN_LEFT | wxALL, 5);
	$password_input = Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition, [200, -1], wxTE_PASSWORD);
	$boxSizer->Add($password_input, 0, wxGROW | wxALL, 5);

	# Create a label and an input for the password confirmation
	my $password_confirmation_label = Wx::StaticText->new($self, wxID_STATIC, "Repeat password:");
	$boxSizer->Add($password_confirmation_label, 0, wxALIGN_LEFT | wxALL, 5);
	$password_confirmation_input = Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition, [200, -1], wxTE_PASSWORD);
	$boxSizer->Add($password_confirmation_input, 0, wxGROW | wxALL, 5);

	# Create a label and an input for the first name
	my $first_name_label = Wx::StaticText->new($self, wxID_STATIC, "First name:");
	$boxSizer->Add($first_name_label, 0, wxALIGN_LEFT | wxALL, 5);
	$first_name_input = Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition, [200, -1], 0);
	$boxSizer->Add($first_name_input, 0, wxGROW | wxALL, 5);

	# Create a label and an input for the last name
	my $last_name_label = Wx::StaticText->new($self, wxID_STATIC, "Last name:");
	$boxSizer->Add($last_name_label, 0, wxALIGN_LEFT | wxALL, 5);
	$last_name_input = Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition, [200, -1]);
	$boxSizer->Add($last_name_input, 0, wxGROW | wxALL, 5);

	# Draw a static horizonal line
	my $line = Wx::StaticLine->new($self, wxID_STATIC);
	$boxSizer->Add($line, 0, wxGROW | wxALL, 5);

	# Create a sizer for the register and exit buttons
	my $okCancelBox = Wx::BoxSizer->new(wxHORIZONTAL);
	$boxSizer->Add($okCancelBox, 0, wxALIGN_RIGHT | wxALL, 5);

	# Create and add an register/exit buttons to their sizer, placing them horizontally side by side
	my $register = Wx::Button->new($self, $ID_REGISTER, 'Register');
	$okCancelBox->Add($register, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);
	my $exit = Wx::Button->new($self, $ID_EXIT, 'Exit');
	$okCancelBox->Add($exit, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

	# Sizes the window so that it fits around its subwindows
	$topSizer->Fit($self);

	# Handle events for the exit and register buttons
	EVT_BUTTON($self, $ID_REGISTER, \&register);
	EVT_BUTTON($self, $ID_EXIT, \&close_window);

	return $self;
}

sub register {
	my ($self) = @_;

	# Get all form values
	my $username = $username_input->GetValue();
	my $password = $password_input->GetValue();
	my $password_confirmation = $password_confirmation_input->GetValue();
	my $first_name = $first_name_input->GetValue();
	my $last_name = $last_name_input->GetValue();

	if($password eq $password_confirmation) {
		# Get the message from the validation function
		my $validation_message = Login::validate_register($username, $password, $first_name, $last_name);

		if($validation_message eq '') {
			# The passwords match, so register and login the user
			Login::register($username, $password, $first_name, $last_name);

			# Close the window
			$self->close_window();
		}
		else {
			# The validation didn't pass, show the returned message
			Wx::MessageBox($validation_message);
		}
	}
	else {
		Wx::MessageBox("Passwords does not match.");
	}
}

sub close_window {
	my ($self) = @_;

	# Close the dialog window with a return code 0 and destroy the window
	$self->EndModal(0);
	$self->Destroy();
}

1;